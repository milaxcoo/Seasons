import 'package.equatable/equatable.dart';

class VoteResult extends Equatable {
  final String nomineeName;
  final double votePercentage;

  const VoteResult({required this.nomineeName, required this.votePercentage});

  @override
  List<Object> get props => [nomineeName, votePercentage];
}