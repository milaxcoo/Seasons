import 'package:equatable/equatable.dart';

enum VotingStatus { registration, active, completed }

class VotingEvent extends Equatable {
  final String id;
  final String title;
  final String description;
  final VotingStatus status;
  final DateTime registrationEndDate;
  final DateTime votingStartDate;
  final DateTime votingEndDate;

  const VotingEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.registrationEndDate,
    required this.votingStartDate,
    required this.votingEndDate,
  });

  @override
  List<Object> get props => [
        id,
        title,
        description,
        status,
        registrationEndDate,
        votingStartDate,
        votingEndDate,
      ];
}