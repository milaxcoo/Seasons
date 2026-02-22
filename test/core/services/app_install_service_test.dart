import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/core/services/app_install_service.dart';
import 'package:seasons/core/services/draft_service.dart';
import 'package:seasons/core/services/rudn_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRudnAuthService extends Mock implements RudnAuthService {}

class MockDraftService extends Mock implements DraftService {}

void main() {
  late MockRudnAuthService mockAuthService;
  late MockDraftService mockDraftService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuthService = MockRudnAuthService();
    mockDraftService = MockDraftService();
    when(() => mockAuthService.clearSecureData()).thenAnswer((_) async {});
    when(() => mockDraftService.clearAllDrafts()).thenAnswer((_) async {});
  });

  test('clears secure/cached auth state and sets install id on fresh install',
      () async {
    final service = AppInstallService(
      authService: mockAuthService,
      draftService: mockDraftService,
      idGenerator: () => 'install-123',
    );

    await service.ensureInstallConsistency();

    verify(() => mockAuthService.clearSecureData()).called(1);
    verify(() => mockDraftService.clearAllDrafts()).called(1);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppInstallService.installIdKey), 'install-123');
  });

  test('does not clear secure data when install id already exists', () async {
    SharedPreferences.setMockInitialValues({
      AppInstallService.installIdKey: 'existing-install',
    });

    final service = AppInstallService(
      authService: mockAuthService,
      draftService: mockDraftService,
    );

    await service.ensureInstallConsistency();

    verifyNever(() => mockAuthService.clearSecureData());
    verifyNever(() => mockDraftService.clearAllDrafts());

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(AppInstallService.installIdKey),
      'existing-install',
    );
  });
}
