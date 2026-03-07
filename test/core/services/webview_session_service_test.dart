import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/services/webview_session_service.dart';

class FakeWebViewSessionController
    implements WebViewSessionControllerInterface {
  int clearCacheCalls = 0;
  int clearLocalStorageCalls = 0;
  bool failCache;
  bool failLocalStorage;

  FakeWebViewSessionController({
    this.failCache = false,
    this.failLocalStorage = false,
  });

  @override
  Future<void> clearCache() async {
    clearCacheCalls += 1;
    if (failCache) {
      throw Exception('cache failure');
    }
  }

  @override
  Future<void> clearLocalStorage() async {
    clearLocalStorageCalls += 1;
    if (failLocalStorage) {
      throw Exception('local storage failure');
    }
  }
}

void main() {
  group('WebViewSessionService', () {
    test('clearForFreshLogin clears cookies cache and local storage', () async {
      final controller = FakeWebViewSessionController();
      var clearCookiesCalls = 0;
      final service = WebViewSessionService(
        clearCookies: () async {
          clearCookiesCalls += 1;
          return true;
        },
        controllerFactory: () => controller,
      );

      final result = await service.clearForFreshLogin();

      expect(clearCookiesCalls, 1);
      expect(controller.clearCacheCalls, 1);
      expect(controller.clearLocalStorageCalls, 1);
      expect(result.allSucceeded, isTrue);
    });

    test('clearOnLogout keeps going when one cleanup step fails', () async {
      final controller = FakeWebViewSessionController(failCache: true);
      final service = WebViewSessionService(
        clearCookies: () async => true,
        controllerFactory: () => controller,
      );

      final result = await service.clearOnLogout();

      expect(result.cookiesCleared, isTrue);
      expect(result.cacheCleared, isFalse);
      expect(result.localStorageCleared, isTrue);
      expect(controller.clearCacheCalls, 1);
      expect(controller.clearLocalStorageCalls, 1);
    });
  });
}
