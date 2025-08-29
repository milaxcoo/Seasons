import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seasons/core/theme.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/widgets/app_background.dart';

class VotingDetailsScreen extends StatelessWidget {
  final model.VotingEvent event;
  const VotingDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Create a new, scoped BLoC instance for this screen.
    return BlocProvider(
      create: (context) => VotingBloc(
        votingRepository: RepositoryProvider.of<VotingRepository>(context),
      )..add(FetchNominees(eventId: event.id)),
      child: _VotingDetailsView(event: event),
    );
  }
}

class _VotingDetailsView extends StatefulWidget {
  final model.VotingEvent event;
  const _VotingDetailsView({required this.event});

  @override
  State<_VotingDetailsView> createState() => _VotingDetailsViewState();
}

class _VotingDetailsViewState extends State<_VotingDetailsView> {
  String? _selectedNomineeId;
  bool _voteSubmitted = false;

  void _submitVote() {
    if (_selectedNomineeId == null) {
      // Show an error if no nominee is selected.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Пожалуйста, выберите номинанта перед отправкой.'),
          backgroundColor: Colors.orange,
        ));
      return;
    }

    // Dispatch the SubmitVote event to the BLoC.
    context.read<VotingBloc>().add(
          SubmitVote(
            eventId: widget.event.id,
            nomineeId: _selectedNomineeId!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      imagePath: 'assets/august.jpg',
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          color: Colors.black.withOpacity(0.2),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                widget.event.title,
                style: const TextStyle(color: Colors.white), // Set title color to white
              ),
            ),
            body: BlocConsumer<VotingBloc, VotingState>(
              listener: (context, state) {
                if (state is VotingSubmissionSuccess) {
                  setState(() {
                    _voteSubmitted = true;
                  });
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Голос принят'),
                      content: const Text('Спасибо за участие!'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            // First, pop the dialog
                            Navigator.of(dialogContext).pop();
                            // Then, pop the screen to go back
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                } else if (state is VotingFailure) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text('Ошибка: ${state.error}'),
                      backgroundColor: Colors.redAccent,
                    ));
                }
              },
              builder: (context, state) {
                if (state is VotingLoadInProgress && !_voteSubmitted) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (state is VotingNomineesLoadSuccess) {
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.nominees.length,
                          itemBuilder: (context, index) {
                            final nominee = state.nominees[index];
                            return Card(
                              color: Colors.black.withOpacity(0.3),
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: RadioListTile<String>(
                                title: Text(
                                  nominee.name,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                                ),
                                value: nominee.id,
                                groupValue: _selectedNomineeId,
                                activeColor: Colors.white,
                                onChanged: _voteSubmitted
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedNomineeId = value;
                                        });
                                      },
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: (_selectedNomineeId == null || _voteSubmitted)
                                ? null
                                : _submitVote,
                            child: Text(
                              _voteSubmitted ? 'Голос принят' : 'Проголосовать',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                if (state is VotingFailure) {
                  return Center(
                    child: Text(
                      'Не удалось загрузить номинантов: ${state.error}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              },
            ),
          ),
        ),
      ),
    );
  }
}
