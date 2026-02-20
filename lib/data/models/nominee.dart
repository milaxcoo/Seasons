import 'package:equatable/equatable.dart';

class Nominee extends Equatable {
  final String id;
  final String name;

  const Nominee({
    required this.id,
    required this.name,
  });

  // Этот "рецепт" объясняет, как создать объект Nominee из JSON-карты.
  // Он безопасно считывает поля, чтобы избежать ошибок, если данные придут в неожиданном формате.
  factory Nominee.fromJson(Map<String, dynamic> json) {
    return Nominee(
      id: json['id'] as String? ?? 'unknown_id',
      name: json['name'] as String? ?? 'Без имени',
    );
  }

  @override
  List<Object> get props => [id, name];
}
