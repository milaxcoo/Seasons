import 'package:flutter/material.dart';
import '../../data/models/models.dart';
// Mock data for nominees since the repository doesn't provide it per event yet
import '../../data/repositories/mock_voting_repository.dart';

class VotingDetailsScreen extends StatefulWidget {
  final VotingEvent event;
  const VotingDetailsScreen({super.key, required this.event});

  @override
  State<VotingDetailsScreen> createState() => _VotingDetailsScreenState();
}

class _VotingDetailsScreenState extends State<VotingDetailsScreen> {
  String? _selectedNomineeId;
  bool _isSubmitting = false;
  bool _voteSubmitted = false;
  List<Nominee> _nominees =;

  @override
  void initState() {
    super.initState();
    _fetchNominees();
  }

  Future<void> _fetchNominees() async {
    // In a real app, you'd use context.read<VotingRepository>()
    final nominees = await MockVotingRepository().getNomineesForEvent(widget.event.id);
    setState(() {
      _nominees = nominees;
    });
  }

  void _submitVote() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Vote'),
          content: const Text('Are you sure you want to submit your vote? This action cannot be undone.'),
          actions: <Widget>,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
      ),
      body: _nominees.isEmpty
         ? const Center(child: CircularProgressIndicator())
          : Column(
              children:;
                      return RadioListTile<String>(
                        title: Text(nominee.name),
                        value: nominee.id,
                        groupValue: _selectedNomineeId,
                        onChanged: _voteSubmitted? null : (value) {
                          setState(() {
                            _selectedNomineeId = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_selectedNomineeId == null |

| _voteSubmitted |
| _isSubmitting)
                         ? null
                          : _submitVote,
                      child: _isSubmitting
                         ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_voteSubmitted? 'Vote Submitted' : 'Submit Vote'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}