// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'seasons';

  @override
  String get login => 'Sign In';

  @override
  String get copyright => '© RUDN University 2025';

  @override
  String get helpEmail => 'seasons-helpdesk@rudn.ru';

  @override
  String get noActiveVotings => 'No active votings yet';

  @override
  String registrationUntil(String date) {
    return 'Registration until: $date';
  }

  @override
  String get registrationOpen => 'Registration is open';

  @override
  String get registrationClosed => 'Registration closed';

  @override
  String votingUntil(String date) {
    return 'Voting until: $date';
  }

  @override
  String get votingActive => 'Voting in progress';

  @override
  String completedOn(String date) {
    return 'Completed: $date';
  }

  @override
  String get completed => 'Completed';

  @override
  String get registered => 'Registered';

  @override
  String get notRegistered => 'Not registered';

  @override
  String get voted => 'Voted';

  @override
  String get notVoted => 'Not voted';

  @override
  String get userData => 'User Data';

  @override
  String get failedToLoadProfile => 'Failed to load profile data';

  @override
  String get surname => 'Surname';

  @override
  String get name => 'Name';

  @override
  String get patronymic => 'Patronymic';

  @override
  String get email => 'Email';

  @override
  String get jobTitle => 'Job Title';

  @override
  String get registrationStart => 'Registration started at';

  @override
  String get registrationEnd => 'Registration ended at';

  @override
  String get status => 'Status';

  @override
  String get registerButton => 'Register';

  @override
  String get alreadyRegistered => 'You are already registered';

  @override
  String get registering => 'Registering...';

  @override
  String get registrationSuccess => 'You have been successfully registered!';

  @override
  String registrationError(String error) {
    return 'Registration error: $error';
  }

  @override
  String get notSet => 'N/A';

  @override
  String get votingStart => 'Voting started at';

  @override
  String get votingEnd => 'Voting end at';

  @override
  String get votingInProgress => 'Voting in progress';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get voteConfirmationMessage =>
      'After confirmation, your vote will be counted and cannot be changed.';

  @override
  String get cancel => 'Cancel';

  @override
  String get vote => 'Vote';

  @override
  String get answerAllQuestions => 'Please answer all questions.';

  @override
  String get voteAccepted => 'Vote Accepted';

  @override
  String get thankYou => 'Thank you for participating!';

  @override
  String get alreadyVotedError => 'Your vote has already been counted.';

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String get noQuestionsAvailable => 'No questions available for this voting.';

  @override
  String get alreadyVoted => 'You have already voted';

  @override
  String get description => 'Description';

  @override
  String get votingStartLabel => 'Voting started at';

  @override
  String get votingEndLabel => 'Voting ended at';

  @override
  String get sessionCompleted => 'Voting finished';

  @override
  String get resultsUnavailable => 'Results for this voting are not available.';

  @override
  String get votingResults => 'Voting results';

  @override
  String get voteCount => 'Vote Count';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';
}
