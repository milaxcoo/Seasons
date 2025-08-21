import 'package:equatable/equatable.dart';

// FIXED: The VotingStatus enum is defined here, in the same file as the model that uses it.
// This makes it available to the VotingEvent class and resolves the 'undefined_class' error.
enum VotingStatus {
  registration,
  active,
  completed,
}

// This class represents a single voting event.
// It extends Equatable to allow for easy value-based comparisons,
// which is crucial for the BLoC state management to work efficiently.
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

  // The 'props' getter is required by the Equatable package.
  // It lists all the properties that should be considered when checking for equality.
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
