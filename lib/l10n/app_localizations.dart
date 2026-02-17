import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// App tagline shown below main title
  ///
  /// In ru, this message translates to:
  /// **'времена года'**
  String get appTagline;

  /// Login button text
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get login;

  /// Copyright text
  ///
  /// In ru, this message translates to:
  /// **'© RUDN University 2026'**
  String get copyright;

  /// Help desk email
  ///
  /// In ru, this message translates to:
  /// **'seasons-helpdesk@rudn.ru'**
  String get helpEmail;

  /// Message when no votings are available
  ///
  /// In ru, this message translates to:
  /// **'Нет активных голосований'**
  String get noActiveVotings;

  /// Registration deadline text
  ///
  /// In ru, this message translates to:
  /// **'Регистрация до: {date}'**
  String registrationUntil(String date);

  /// Registration is open
  ///
  /// In ru, this message translates to:
  /// **'Регистрация открыта'**
  String get registrationOpen;

  /// Registration is closed for user
  ///
  /// In ru, this message translates to:
  /// **'Регистрация закрыта'**
  String get registrationClosed;

  /// Voting deadline text
  ///
  /// In ru, this message translates to:
  /// **'Голосование до: {date}'**
  String votingUntil(String date);

  /// Voting is active
  ///
  /// In ru, this message translates to:
  /// **'Идет голосование'**
  String get votingActive;

  /// Completed date text
  ///
  /// In ru, this message translates to:
  /// **'Завершено: {date}'**
  String completedOn(String date);

  /// Completed status
  ///
  /// In ru, this message translates to:
  /// **'Завершено'**
  String get completed;

  /// User is registered
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрирован(-а)'**
  String get registered;

  /// User is not registered
  ///
  /// In ru, this message translates to:
  /// **'Не зарегистрирован(-а)'**
  String get notRegistered;

  /// User has voted
  ///
  /// In ru, this message translates to:
  /// **'Проголосовал(-а)'**
  String get voted;

  /// User has not voted
  ///
  /// In ru, this message translates to:
  /// **'Не проголосовал(-а)'**
  String get notVoted;

  /// User data screen title
  ///
  /// In ru, this message translates to:
  /// **'Данные пользователя'**
  String get userData;

  /// Error message when profile fails to load
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить данные профиля'**
  String get failedToLoadProfile;

  /// Surname field label
  ///
  /// In ru, this message translates to:
  /// **'Фамилия'**
  String get surname;

  /// Name field label
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get name;

  /// Patronymic field label
  ///
  /// In ru, this message translates to:
  /// **'Отчество'**
  String get patronymic;

  /// Email field label
  ///
  /// In ru, this message translates to:
  /// **'Электронная почта'**
  String get email;

  /// Job title field label
  ///
  /// In ru, this message translates to:
  /// **'Должность'**
  String get jobTitle;

  /// Registration start label
  ///
  /// In ru, this message translates to:
  /// **'Начало\nрегистрации'**
  String get registrationStart;

  /// Registration end label
  ///
  /// In ru, this message translates to:
  /// **'Завершение\nрегистрации'**
  String get registrationEnd;

  /// Status label
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get status;

  /// Register button text
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get registerButton;

  /// Already registered message
  ///
  /// In ru, this message translates to:
  /// **'Вы уже зарегистрированы'**
  String get alreadyRegistered;

  /// Registration in progress
  ///
  /// In ru, this message translates to:
  /// **'Идет регистрация...'**
  String get registering;

  /// Registration success message
  ///
  /// In ru, this message translates to:
  /// **'Вы были успешно зарегистрированы!'**
  String get registrationSuccess;

  /// Registration error message
  ///
  /// In ru, this message translates to:
  /// **'Ошибка регистрации: {error}'**
  String registrationError(String error);

  /// Not set placeholder
  ///
  /// In ru, this message translates to:
  /// **'Не установлено'**
  String get notSet;

  /// Voting start label
  ///
  /// In ru, this message translates to:
  /// **'Начало голосования'**
  String get votingStart;

  /// Voting end label
  ///
  /// In ru, this message translates to:
  /// **'Завершение голосования'**
  String get votingEnd;

  /// Voting in progress badge
  ///
  /// In ru, this message translates to:
  /// **'Идет голосование'**
  String get votingInProgress;

  /// Confirmation dialog title
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены?'**
  String get areYouSure;

  /// Vote confirmation dialog message
  ///
  /// In ru, this message translates to:
  /// **'После подтверждения ваш голос будет засчитан, и изменить его будет нельзя.'**
  String get voteConfirmationMessage;

  /// Cancel button
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// Vote button
  ///
  /// In ru, this message translates to:
  /// **'Проголосовать'**
  String get vote;

  /// Validation message for incomplete voting
  ///
  /// In ru, this message translates to:
  /// **'Пожалуйста, ответьте на все вопросы.'**
  String get answerAllQuestions;

  /// Vote accepted dialog title
  ///
  /// In ru, this message translates to:
  /// **'Голос принят'**
  String get voteAccepted;

  /// Thank you message
  ///
  /// In ru, this message translates to:
  /// **'Спасибо за участие!'**
  String get thankYou;

  /// Already voted error message
  ///
  /// In ru, this message translates to:
  /// **'Ваш голос уже был учтен ранее.'**
  String get alreadyVotedError;

  /// Generic error message
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String error(String error);

  /// No questions available message
  ///
  /// In ru, this message translates to:
  /// **'Вопросы для этого голосования отсутствуют.'**
  String get noQuestionsAvailable;

  /// Already voted button text
  ///
  /// In ru, this message translates to:
  /// **'Вы уже проголосовали'**
  String get alreadyVoted;

  /// Description label
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get description;

  /// Voting start label for results screen
  ///
  /// In ru, this message translates to:
  /// **'Начало\nголосования'**
  String get votingStartLabel;

  /// Voting end label for results screen
  ///
  /// In ru, this message translates to:
  /// **'Завершение\nголосования'**
  String get votingEndLabel;

  /// Session completed message
  ///
  /// In ru, this message translates to:
  /// **'Заседание завершено'**
  String get sessionCompleted;

  /// Results unavailable message
  ///
  /// In ru, this message translates to:
  /// **'Результаты для этого голосования отсутствуют.'**
  String get resultsUnavailable;

  /// Voting results title
  ///
  /// In ru, this message translates to:
  /// **'Результаты голосования'**
  String get votingResults;

  /// Vote count column header
  ///
  /// In ru, this message translates to:
  /// **'Количество голосов'**
  String get voteCount;

  /// Russian language option
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// English language option
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Error message when votings fail to load
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить голосования'**
  String get connectionError;

  /// Tap to retry hint
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы обновить'**
  String get tapToRetry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
