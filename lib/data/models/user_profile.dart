import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String surname;
  final String name;
  final String patronymic;
  final String email;
  final String jobTitle;

  const UserProfile({
    required this.surname,
    required this.name,
    required this.patronymic,
    required this.email,
    required this.jobTitle,
  });

  @override
  List<Object> get props => [surname, name, patronymic, email, jobTitle];

  String get fullName => '$surname $name $patronymic';

  factory UserProfile.empty() {
    return const UserProfile(
        surname: '', name: '', patronymic: '', email: '', jobTitle: '');
  }
}
