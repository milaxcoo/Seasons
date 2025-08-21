import 'package:equatable/equatable.dart';

// This class represents a single nominee in a voting event.
// Like the VotingEvent model, it extends Equatable to ensure that
// BLoC can correctly compare different instances and avoid unnecessary UI rebuilds.
class Nominee extends Equatable {
  final String id;
  final String name;

  // A const constructor for performance benefits.
  const Nominee({
    required this.id,
    required this.name,
  });

  // The list of properties to be used for value-based equality checking.
  @override
  List<Object> get props => [id, name];
}
