import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class HomeTabState extends Equatable {
  final int index;
  final String source;

  const HomeTabState({
    required this.index,
    required this.source,
  });

  @override
  List<Object> get props => [index, source];
}

class HomeTabCubit extends Cubit<HomeTabState> {
  HomeTabCubit({int initialIndex = 0})
      : super(
          HomeTabState(
            index: _normalizeIndex(initialIndex),
            source: 'init',
          ),
        );

  static int _normalizeIndex(int index) {
    if (index < 0) return 0;
    if (index > 2) return 2;
    return index;
  }

  void setIndex(
    int index, {
    required String source,
  }) {
    final normalized = _normalizeIndex(index);
    if (state.index == normalized) {
      if (kDebugMode) {
        debugPrint(
          'HomeTabCubit: unchanged index=$normalized source=$source',
        );
      }
      return;
    }

    if (kDebugMode) {
      debugPrint(
        'HomeTabCubit: index ${state.index} -> $normalized source=$source',
      );
    }
    emit(HomeTabState(index: normalized, source: source));
  }
}
