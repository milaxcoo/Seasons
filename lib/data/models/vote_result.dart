import 'package:equatable/equatable.dart';

// This class represents the final result for a single nominee
// in a completed voting event.
// It extends Equatable to ensure efficient state comparisons in the BLoC.
class VoteResult extends Equatable {
  final String nomineeName;
  final double votePercentage;

  // A const constructor for performance benefits.
  const VoteResult({
    required this.nomineeName,
    required this.votePercentage,
  });

  // The list of properties for value-based equality checking.
  @override
  List<Object> get props => [nomineeName, votePercentage];
}
