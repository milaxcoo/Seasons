// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTagline => 'времена года';

  @override
  String get login => 'Войти';

  @override
  String get copyright => '© RUDN University 2026';

  @override
  String get helpEmail => 'seasons-helpdesk@rudn.ru';

  @override
  String get noActiveVotings => 'Нет активных голосований';

  @override
  String registrationUntil(String date) {
    return 'Регистрация до: $date';
  }

  @override
  String get registrationOpen => 'Регистрация открыта';

  @override
  String get registrationClosed => 'Регистрация закрыта';

  @override
  String votingUntil(String date) {
    return 'Голосование до: $date';
  }

  @override
  String get votingActive => 'Идет голосование';

  @override
  String completedOn(String date) {
    return 'Завершено: $date';
  }

  @override
  String get completed => 'Завершено';

  @override
  String get registered => 'Зарегистрирован(-а)';

  @override
  String get notRegistered => 'Не зарегистрирован(-а)';

  @override
  String get voted => 'Проголосовал(-а)';

  @override
  String get notVoted => 'Не проголосовал(-а)';

  @override
  String get userData => 'Данные пользователя';

  @override
  String get failedToLoadProfile => 'Не удалось загрузить данные профиля';

  @override
  String get surname => 'Фамилия';

  @override
  String get name => 'Имя';

  @override
  String get patronymic => 'Отчество';

  @override
  String get email => 'Электронная почта';

  @override
  String get jobTitle => 'Должность';

  @override
  String get registrationStart => 'Начало\nрегистрации';

  @override
  String get registrationEnd => 'Завершение\nрегистрации';

  @override
  String get status => 'Статус';

  @override
  String get registerButton => 'Зарегистрироваться';

  @override
  String get alreadyRegistered => 'Вы уже зарегистрированы';

  @override
  String get registering => 'Идет регистрация...';

  @override
  String get registrationSuccess => 'Вы были успешно зарегистрированы!';

  @override
  String registrationError(String error) {
    return 'Ошибка регистрации: $error';
  }

  @override
  String get notSet => 'Не установлено';

  @override
  String get votingStart => 'Начало голосования';

  @override
  String get votingEnd => 'Завершение голосования';

  @override
  String get votingInProgress => 'Идет голосование';

  @override
  String get areYouSure => 'Вы уверены?';

  @override
  String get voteConfirmationMessage =>
      'После подтверждения ваш голос будет засчитан, и изменить его будет нельзя.';

  @override
  String get cancel => 'Отмена';

  @override
  String get vote => 'Проголосовать';

  @override
  String get answerAllQuestions => 'Пожалуйста, ответьте на все вопросы.';

  @override
  String get voteAccepted => 'Голос принят';

  @override
  String get thankYou => 'Спасибо за участие!';

  @override
  String get alreadyVotedError => 'Ваш голос уже был учтен ранее.';

  @override
  String error(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get noQuestionsAvailable =>
      'Вопросы для этого голосования отсутствуют.';

  @override
  String get alreadyVoted => 'Вы уже проголосовали';

  @override
  String get description => 'Описание';

  @override
  String get votingStartLabel => 'Начало\nголосования';

  @override
  String get votingEndLabel => 'Завершение\nголосования';

  @override
  String get sessionCompleted => 'Заседание завершено';

  @override
  String get resultsUnavailable =>
      'Результаты для этого голосования отсутствуют.';

  @override
  String get votingResults => 'Результаты голосования';

  @override
  String get voteCount => 'Количество голосов';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';
}
