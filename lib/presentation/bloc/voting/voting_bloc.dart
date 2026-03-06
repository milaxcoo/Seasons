import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:seasons/core/services/background_service.dart';
import 'package:seasons/core/utils/safe_log.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/voting/voting_connection_status.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';

class VotingBloc extends Bloc<VotingEvent, VotingState> {
  final VotingRepository _votingRepository;
  final Duration _refreshDebounce;
  final Duration _restoredStatusDuration;

  StreamSubscription? _serviceSubscription;
  final StreamController<void> _authInvalidController =
      StreamController<void>.broadcast();
  final StreamController<VotingConnectionStatus> _connectionStatusController =
      StreamController<VotingConnectionStatus>.broadcast();

  Timer? _coalescedRefreshTimer;
  Timer? _restoredStatusTimer;
  bool _pendingRefreshNeedsRestoredStatus = false;
  bool _needsCatchUpAfterReconnect = false;
  VotingConnectionStatus _currentConnectionStatus =
      VotingConnectionStatus.connected;

  Stream<void> get onAuthInvalid => _authInvalidController.stream;
  Stream<VotingConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;
  VotingConnectionStatus get currentConnectionStatus =>
      _currentConnectionStatus;

  VotingBloc({
    required VotingRepository votingRepository,
    Stream<Map<String, dynamic>?>? backgroundServiceStream,
    Duration refreshDebounce = const Duration(milliseconds: 350),
    Duration restoredStatusDuration = const Duration(seconds: 2),
  })  : _votingRepository = votingRepository,
        _refreshDebounce = refreshDebounce,
        _restoredStatusDuration = restoredStatusDuration,
        super(VotingInitial()) {
    on<FetchEventsByStatus>(_onFetchEventsByStatus);
    on<RefreshEventsSilent>(_onRefreshEventsSilent);
    on<RefreshAllEventsSilent>(_onRefreshAllEventsSilent);
    on<RegisterForEvent>(_onRegisterForEvent);
    on<SubmitVote>(_onSubmitVote);
    on<VotingUpdated>(_onVotingUpdated);
    on<VotingListUpdated>(_onVotingListUpdated);

    // Listen to BackgroundService for updates (or provided stream for testing).
    _serviceSubscription =
        (backgroundServiceStream ?? BackgroundService().on).listen((data) {
      if (data == null) return;

      final action = data['action'] as String?;
      if (action == null || action.isEmpty) return;
      if (kDebugMode) {
        debugPrint("VotingBloc: Received from BackgroundService: $action");
      }

      _handleBackgroundServiceAction(action);
    });
  }

  void _handleBackgroundServiceAction(String action) {
    if (action == BackgroundService.actionAuthInvalid) {
      _authInvalidController.add(null);
      return;
    }

    if (action == BackgroundService.actionConnectionReconnecting) {
      _needsCatchUpAfterReconnect = true;
      _emitConnectionStatus(VotingConnectionStatus.reconnecting);
      return;
    }

    if (action == BackgroundService.actionConnectionWaitingForNetwork) {
      _needsCatchUpAfterReconnect = true;
      _emitConnectionStatus(VotingConnectionStatus.waitingForNetwork);
      return;
    }

    if (action == BackgroundService.actionConnectionConnected) {
      if (_needsCatchUpAfterReconnect) {
        _needsCatchUpAfterReconnect = false;
        _emitConnectionStatus(VotingConnectionStatus.syncing);
        _scheduleCoalescedSilentRefresh(emitRestoredStatus: true);
      } else {
        _emitConnectionStatus(VotingConnectionStatus.connected);
      }
      return;
    }

    // Coalesce bursty WS actions into one refresh wave.
    _scheduleCoalescedSilentRefresh(emitRestoredStatus: false);
  }

  void _scheduleCoalescedSilentRefresh({required bool emitRestoredStatus}) {
    _pendingRefreshNeedsRestoredStatus =
        _pendingRefreshNeedsRestoredStatus || emitRestoredStatus;
    if (_coalescedRefreshTimer?.isActive ?? false) return;

    _coalescedRefreshTimer = Timer(_refreshDebounce, () {
      if (isClosed) return;
      final shouldEmitRestored = _pendingRefreshNeedsRestoredStatus;
      _pendingRefreshNeedsRestoredStatus = false;
      add(RefreshAllEventsSilent(emitRestoredStatus: shouldEmitRestored));
    });
  }

  void _emitConnectionStatus(VotingConnectionStatus status) {
    if (_currentConnectionStatus == status) return;
    if (status != VotingConnectionStatus.restored) {
      _restoredStatusTimer?.cancel();
      _restoredStatusTimer = null;
    }
    _currentConnectionStatus = status;
    _connectionStatusController.add(status);
  }

  void _emitRestoredThenConnected() {
    _emitConnectionStatus(VotingConnectionStatus.restored);
    _restoredStatusTimer?.cancel();
    _restoredStatusTimer = Timer(_restoredStatusDuration, () {
      if (isClosed) return;
      _emitConnectionStatus(VotingConnectionStatus.connected);
    });
  }

  Future<bool> _refreshStatusSilent(
    model.VotingStatus status,
    Emitter<VotingState> emit,
  ) async {
    try {
      final events = await _votingRepository.getEventsByStatus(status);
      emit(VotingEventsLoadSuccess(
        events: events,
        status: status,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
      return true;
    } on UnauthorizedSessionException {
      _notifyAuthInvalid();
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Silent refresh failed for $status: ${sanitizeObjectForLog(e)}',
        );
      }
      return false;
    }
  }

  void _onVotingListUpdated(
    VotingListUpdated event,
    Emitter<VotingState> emit,
  ) {
    if (state is VotingEventsLoadSuccess) {
      final currentState = state as VotingEventsLoadSuccess;
      final filtered =
          event.events.where((e) => e.status == currentState.status).toList();

      if (kDebugMode) {
        debugPrint(
          "VotingBloc: _onVotingListUpdated emitting ${filtered.length} filtered events",
        );
      }

      emit(VotingEventsLoadSuccess(
        events: filtered,
        status: currentState.status,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  void _onVotingUpdated(VotingUpdated event, Emitter<VotingState> emit) {
    if (state is VotingEventsLoadSuccess) {
      final currentState = state as VotingEventsLoadSuccess;
      final updatedEvents = currentState.events.map((e) {
        if (e.id == event.event.id) {
          return event.event;
        }
        return e;
      }).toList();

      emit(VotingEventsLoadSuccess(
        events: updatedEvents,
        status: currentState.status,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  @override
  Future<void> close() {
    _coalescedRefreshTimer?.cancel();
    _restoredStatusTimer?.cancel();
    _serviceSubscription?.cancel();
    _authInvalidController.close();
    _connectionStatusController.close();
    return super.close();
  }

  Future<void> _onFetchEventsByStatus(
    FetchEventsByStatus event,
    Emitter<VotingState> emit,
  ) async {
    emit(VotingLoadInProgress());
    try {
      final events = await _votingRepository.getEventsByStatus(event.status);
      emit(VotingEventsLoadSuccess(
        events: events,
        status: event.status,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    } on UnauthorizedSessionException {
      _notifyAuthInvalid();
      emit(const VotingFailure(error: 'auth_invalid'));
    } catch (e) {
      if (_isUnauthorizedError(e)) {
        _notifyAuthInvalid();
        emit(const VotingFailure(error: 'auth_invalid'));
        return;
      }
      emit(VotingFailure(error: e.toString()));
    }
  }

  Future<void> _onRefreshEventsSilent(
    RefreshEventsSilent event,
    Emitter<VotingState> emit,
  ) async {
    await _refreshStatusSilent(event.status, emit);
  }

  Future<void> _onRefreshAllEventsSilent(
    RefreshAllEventsSilent event,
    Emitter<VotingState> emit,
  ) async {
    final statuses = <model.VotingStatus>[
      model.VotingStatus.registration,
      model.VotingStatus.active,
      model.VotingStatus.completed,
    ];

    // Fetch all statuses in parallel.
    final results = await Future.wait(statuses.map((status) async {
      try {
        final events = await _votingRepository.getEventsByStatus(status);
        return (
          status: status,
          events: events,
          success: true,
          unauthorized: false,
        );
      } on UnauthorizedSessionException {
        return (
          status: status,
          events: <model.VotingEvent>[],
          success: false,
          unauthorized: true,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'Silent refresh failed for $status: ${sanitizeObjectForLog(e)}',
          );
        }
        return (
          status: status,
          events: <model.VotingEvent>[],
          success: false,
          unauthorized: _isUnauthorizedError(e),
        );
      }
    }));

    // Emit results sequentially (Emitter does not support concurrent emissions).
    var hasSuccess = false;
    var hasFailure = false;
    var hasUnauthorized = false;
    for (final result in results) {
      if (result.success) {
        hasSuccess = true;
        emit(VotingEventsLoadSuccess(
          events: result.events,
          status: result.status,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        if (result.unauthorized) {
          hasUnauthorized = true;
        }
        hasFailure = true;
      }
    }

    if (hasUnauthorized) {
      _notifyAuthInvalid();
      _emitConnectionStatus(VotingConnectionStatus.disconnected);
      return;
    }

    if (!hasSuccess) {
      _emitConnectionStatus(VotingConnectionStatus.disconnected);
      return;
    }

    if (hasFailure) {
      _emitConnectionStatus(VotingConnectionStatus.disconnected);
      return;
    }

    if (event.emitRestoredStatus) {
      _emitRestoredThenConnected();
      return;
    }

    _emitConnectionStatus(VotingConnectionStatus.connected);
  }

  Future<void> _onRegisterForEvent(
    RegisterForEvent event,
    Emitter<VotingState> emit,
  ) async {
    emit(RegistrationInProgress());
    try {
      await _votingRepository.registerForEvent(event.eventId);
      emit(RegistrationSuccess());
    } on UnauthorizedSessionException {
      _notifyAuthInvalid();
      emit(const RegistrationFailure(error: 'auth_invalid'));
    } catch (e) {
      if (_isUnauthorizedError(e)) {
        _notifyAuthInvalid();
        emit(const RegistrationFailure(error: 'auth_invalid'));
        return;
      }
      emit(RegistrationFailure(error: e.toString()));
    }
  }

  Future<void> _onSubmitVote(
      SubmitVote event, Emitter<VotingState> emit) async {
    emit(VotingLoadInProgress());
    try {
      final isVoteAccepted =
          await _votingRepository.submitVote(event.event, event.answers);
      if (isVoteAccepted) {
        emit(VotingSubmissionSuccess());
      } else {
        emit(const VotingFailure(error: 'User already voted'));
      }
    } on UnauthorizedSessionException {
      _notifyAuthInvalid();
      emit(const VotingFailure(error: 'auth_invalid'));
    } catch (e) {
      if (_isUnauthorizedError(e)) {
        _notifyAuthInvalid();
        emit(const VotingFailure(error: 'auth_invalid'));
        return;
      }
      emit(VotingFailure(error: e.toString()));
    }
  }

  void _notifyAuthInvalid() {
    _authInvalidController.add(null);
  }

  bool _isUnauthorizedError(Object error) {
    if (error is UnauthorizedSessionException) {
      return true;
    }
    final value = error.toString().toLowerCase();
    return value.contains('unauthorizedsessionexception') ||
        value.contains('auth_invalid') ||
        value.contains('unauthorized') ||
        value.contains('forbidden') ||
        value.contains('401') ||
        value.contains('403');
  }
}
