import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/utils/user_friendly_error_mapper.dart';
import 'package:seasons/l10n/app_localizations.dart';

Future<AppLocalizations> _loadL10n(WidgetTester tester, Locale locale) async {
  AppLocalizations? l10n;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru'), Locale('en')],
      locale: locale,
      home: Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context)!;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return l10n!;
}

void main() {
  testWidgets(
      'maps registration error to friendly text and does not leak endpoint details',
      (tester) async {
    final l10n = await _loadL10n(tester, const Locale('en'));
    final message = UserFriendlyErrorMapper.toMessage(
      l10n,
      'POST https://seasons.rudn.ru/api/v1/voter/register_in_voting failed',
      context: UserErrorContext.registration,
    );

    expect(message, 'Could not complete registration. Please try again.');
    expect(message.contains('https://'), isFalse);
    expect(message.contains('/api/'), isFalse);
  });

  testWidgets('maps vote submission network/server failures correctly',
      (tester) async {
    final l10n = await _loadL10n(tester, const Locale('en'));

    final networkMessage = UserFriendlyErrorMapper.toMessage(
      l10n,
      'SocketException: Failed host lookup',
      context: UserErrorContext.voteSubmit,
    );
    expect(
      networkMessage,
      'Network connection problem. Check your internet and try again.',
    );

    final serverMessage = UserFriendlyErrorMapper.toMessage(
      l10n,
      'HTTP 503 Service Unavailable',
      context: UserErrorContext.voteSubmit,
    );
    expect(
      serverMessage,
      'Server is temporarily unavailable. Please try again later.',
    );
  });

  testWidgets('already-voted remains dedicated user path', (tester) async {
    final l10n = await _loadL10n(tester, const Locale('ru'));

    expect(
      UserFriendlyErrorMapper.isAlreadyVotedError('User already voted'),
      isTrue,
    );
    final message = UserFriendlyErrorMapper.toMessage(
      l10n,
      'User already voted',
      context: UserErrorContext.voteSubmit,
    );
    expect(message, 'Ваш голос уже был учтен ранее.');
  });

  test('auth_invalid action is recognized', () {
    expect(UserFriendlyErrorMapper.isAuthInvalidAction('auth_invalid'), isTrue);
    expect(UserFriendlyErrorMapper.isAuthInvalidAction('AUTH_INVALID'), isTrue);
    expect(UserFriendlyErrorMapper.isAuthInvalidAction('unknown'), isFalse);
  });
}
