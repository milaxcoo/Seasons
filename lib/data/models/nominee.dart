import 'package:equatable/equatable.dart';

class Nominee extends Equatable {
  final String id;
  final String name;

  const Nominee({
    required this.id,
    required this.name,
  });

  // FIXED: Добавлен фабричный конструктор для создания из JSON
  factory Nominee.fromJson(Map<String, dynamic> json) {
    return Nominee(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  @override
  List<Object> get props => [id, name];
}
