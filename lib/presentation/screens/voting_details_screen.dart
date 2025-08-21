import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';

class VotingDetailsScreen extends StatelessWidget {
  final model.VotingEvent event;
  const VotingDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Create a new, scoped BLoC instance for this screen.
    // This is good practice for screens that manage their own specific data.
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
  // Local state to track the selected nominee's ID.
  String? _selectedNomineeId;
  // Local state to prevent re-voting after a successful submission.
  bool _voteSubmitted = false;

  void _submitVote() {
    if (_selectedNomineeId == null) {
      // Show an error if no nominee is selected.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Please select a nominee before submitting.'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
      ),
      body: BlocConsumer<VotingBloc, VotingState>(
        listener: (context, state) {
          if (state is VotingSubmissionSuccess) {
            // On successful submission, update local state and show a confirmation dialog.
            setState(() {
              _voteSubmitted = true;
            });
            showDialog(
              context: context,
              barrierDismissible: false, // User must tap button to close.
              builder: (dialogContext) => AlertDialog(
                title: const Text('Vote Submitted'),
                content: const Text('Thank you for your participation!'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else if (state is VotingFailure) {
            // On failure, show an error message.
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text('Error: ${state.error}'),
                backgroundColor: Colors.redAccent,
              ));
          }
        },
        builder: (context, state) {
          if (state is VotingLoadInProgress && !_voteSubmitted) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VotingNomineesLoadSuccess) {
            return Column(
              children: [
                // Use Expanded to make the ListView fill the available space.
                Expanded(
                  child: ListView.builder(
                    itemCount: state.nominees.length,
                    itemBuilder: (context, index) {
                      final nominee = state.nominees[index];
                      // Use RadioListTile for a large, easy-to-tap selection area.
                      return RadioListTile<String>(
                        title: Text(nominee.name),
                        value: nominee.id,
                        groupValue: _selectedNomineeId,
                        // Disable the radio buttons after a vote has been submitted.
                        onChanged: _voteSubmitted
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedNomineeId = value;
                                });
                              },
                      );
                    },
                  ),
                ),
                // Submit Button Area
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // Disable the button if no nominee is selected or if the vote is submitted.
                      onPressed: (_selectedNomineeId == null || _voteSubmitted)
                          ? null
                          : _submitVote,
                      child: Text(_voteSubmitted ? 'Vote Submitted' : 'Submit Vote'),
                    ),
                  ),
                ),
              ],
            );
          }
          if (state is VotingFailure) {
            return Center(child: Text('Failed to load nominees: ${state.error}'));
          }
          // Fallback view, handles VotingInitial and other states.
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
