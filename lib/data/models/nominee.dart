import 'package:equatable/equatable.dart';

class Nominee extends Equatable {
  final String id;
  final String name;

  const Nominee({required this.id, required this.name});

  @override
  List<Object> get props => [id, name];
}