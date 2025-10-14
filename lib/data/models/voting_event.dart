import 'package:equatable/equatable.dart';

// Enum для представления статуса голосования
enum VotingStatus { registration, active, completed }

class VotingEvent extends Equatable {
  final String id;
  final String title;
  final String description;
  final VotingStatus status;
  final DateTime registrationEndDate;
  final DateTime votingStartDate;
  final DateTime votingEndDate;
  // FIXED: Добавлено новое поле для хранения статуса регистрации
  final bool isRegistered;

  const VotingEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.registrationEndDate,
    required this.votingStartDate,
    required this.votingEndDate,
    required this.isRegistered,
  });

  factory VotingEvent.fromJson(Map<String, dynamic> json) {
    VotingStatus status;
    switch (json['status'] as String?) {
      case 'active':
      case 'ongoing':
        status = VotingStatus.active;
        break;
      case 'completed':
      case 'finished':
        status = VotingStatus.completed;
        break;
      default:
        status = VotingStatus.registration;
    }

    DateTime parseDate(String? dateString) {
      return dateString != null && dateString.isNotEmpty 
          ? DateTime.parse(dateString) 
          : DateTime.now();
    }

    return VotingEvent(
      id: json['id'] as String? ?? 'unknown_id',
      title: json['name'] as String? ?? 'Без названия', 
      description: json['description'] as String? ?? 'Описание отсутствует.',
      status: status,
      registrationEndDate: parseDate(json['end_registration_at'] as String?),
      votingStartDate: parseDate(json['registration_started_at'] as String?),
      votingEndDate: parseDate(json['voting_end_at'] as String?),
      // FIXED: Читаем поле 'registered' из JSON. '1' означает true, все остальное - false.
      isRegistered: json['registered'] == 1,
    );
  }

  @override
  List<Object> get props => [
        id,
        title,
        description,
        status,
        registrationEndDate,
        votingStartDate,
        votingEndDate,
        isRegistered, // Добавлено в props для сравнения объектов
      ];
}

