// import 'package:seasons/data/models/nominee.dart';
// import 'package:seasons/data/models/vote_result.dart';
// import 'package:seasons/data/models/voting_event.dart';
// import 'package:seasons/data/repositories/voting_repository.dart';

// // Этот класс имитирует получение данных, возвращая заранее определенные значения.
// // Он необходим для разработки UI и для тестов.
// class MockVotingRepository implements VotingRepository {
//   // --- Методы аутентификации ---
//   @override
//   Future<String> login(String login, String password) async {
//     await Future.delayed(const Duration(seconds: 1));
//     if (login.isNotEmpty && password.isNotEmpty) {
//       return 'fake_auth_token';
//     } else {
//       throw Exception('Login failed');
//     }
//   }

//   @override
//   Future<void> logout() async {
//     await Future.delayed(const Duration(milliseconds: 500));
//   }

//   @override
//   Future<String?> getAuthToken() async {
//     // В моке можно имитировать, что токена нет при старте
//     return null;
//   }

//   @override
//   Future<String?> getUserLogin() async {
//     return 'Тестовый Пользователь';
//   }

//   // --- Методы для голосований ---
//   @override
//   Future<List<VotingEvent>> getEventsByStatus(VotingStatus status) async {
//     await Future.delayed(const Duration(seconds: 1));
//     // Возвращаем поддельные данные для каждого статуса
//     switch (status) {
//       case VotingStatus.registration:
//         return [
//           VotingEvent(
//             id: 'reg-01',
//             title: 'Лучшее мобильное приложение (Мок)',
//             description: 'Описание для лучшего мобильного приложения.',
//             status: VotingStatus.registration,
//             registrationEndDate: DateTime.now().add(const Duration(days: 10)),
//             votingStartDate: DateTime.now().add(const Duration(days: 11)),
//             votingEndDate: DateTime.now().add(const Duration(days: 20)),
//           ),
//         ];
//       case VotingStatus.active:
//         return [
//           VotingEvent(
//             id: 'active-01',
//             title: 'Инноватор года (Мок)',
//             description: 'Описание для инноватора года.',
//             status: VotingStatus.active,
//             registrationEndDate: DateTime.now().subtract(const Duration(days: 1)),
//             votingStartDate: DateTime.now(),
//             votingEndDate: DateTime.now().add(const Duration(days: 5)),
//           ),
//         ];
//       case VotingStatus.completed:
//         return []; // Имитируем отсутствие завершенных голосований
//     }
//   }

//   // FIXED: Добавлен недостающий метод registerForEvent.
//   // В моке он просто успешно завершается, ничего не делая.
//   @override
//   Future<void> registerForEvent(String eventId) async {
//     await Future.delayed(const Duration(seconds: 1));
//     return;
//   }
  
//   @override
//   Future<List<Nominee>> getNomineesForEvent(String eventId) async {
//     await Future.delayed(const Duration(seconds: 1));
//     return [
//       const Nominee(id: 'nom-01', name: 'Проект Альфа'),
//       const Nominee(id: 'nom-02', name: 'Команда Инноваторов'),
//     ];
//   }

//   @override
//   Future<List<VoteResult>> getResultsForEvent(String eventId) async {
//     await Future.delayed(const Duration(seconds: 1));
//     return [
//       const VoteResult(nomineeName: 'Проект Альфа', votePercentage: 65.0),
//       const VoteResult(nomineeName: 'Команда Инноваторов', votePercentage: 35.0),
//     ];
//   }

//   @override
//   Future<void> submitVote(String eventId, String nomineeId) async {
//     await Future.delayed(const Duration(seconds: 1));
//   }
// }
