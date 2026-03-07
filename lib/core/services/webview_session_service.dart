import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

abstract class WebViewSessionControllerInterface {
  Future<void> clearCache();
  Future<void> clearLocalStorage();
}

class WebViewSessionControllerAdapter
    implements WebViewSessionControllerInterface {
  final WebViewController _controller;

  WebViewSessionControllerAdapter(this._controller);

  @override
  Future<void> clearCache() {
    return _controller.clearCache();
  }

  @override
  Future<void> clearLocalStorage() {
    return _controller.clearLocalStorage();
  }
}

class WebViewSessionCleanupResult {
  final bool cookiesCleared;
  final bool cacheCleared;
  final bool localStorageCleared;

  const WebViewSessionCleanupResult({
    required this.cookiesCleared,
    required this.cacheCleared,
    required this.localStorageCleared,
  });

  bool get allSucceeded =>
      cookiesCleared && cacheCleared && localStorageCleared;
}

class WebViewSessionService {
  final Future<bool> Function() _clearCookies;
  final WebViewSessionControllerInterface Function() _controllerFactory;

  WebViewSessionService({
    Future<bool> Function()? clearCookies,
    WebViewSessionControllerInterface Function()? controllerFactory,
  })  : _clearCookies =
            clearCookies ?? (() => WebViewCookieManager().clearCookies()),
        _controllerFactory = controllerFactory ??
            (() => WebViewSessionControllerAdapter(WebViewController()));

  Future<WebViewSessionCleanupResult> clearForFreshLogin({
    WebViewSessionControllerInterface? controller,
  }) {
    return _clearSessionData(reason: 'fresh_login', controller: controller);
  }

  Future<WebViewSessionCleanupResult> clearOnLogout({
    WebViewSessionControllerInterface? controller,
  }) {
    return _clearSessionData(reason: 'logout', controller: controller);
  }

  Future<WebViewSessionCleanupResult> _clearSessionData({
    required String reason,
    WebViewSessionControllerInterface? controller,
  }) async {
    final targetController = controller ?? _controllerFactory();

    bool cookiesCleared = false;
    bool cacheCleared = false;
    bool localStorageCleared = false;

    try {
      cookiesCleared = await _clearCookies();
    } catch (e) {
      _debugLog(reason, 'cookies', e);
    }

    try {
      await targetController.clearCache();
      cacheCleared = true;
    } catch (e) {
      _debugLog(reason, 'cache', e);
    }

    try {
      await targetController.clearLocalStorage();
      localStorageCleared = true;
    } catch (e) {
      _debugLog(reason, 'local_storage', e);
    }

    return WebViewSessionCleanupResult(
      cookiesCleared: cookiesCleared,
      cacheCleared: cacheCleared,
      localStorageCleared: localStorageCleared,
    );
  }

  void _debugLog(String reason, String step, Object error) {
    if (!kDebugMode) return;
    debugPrint(
      'WebViewSessionService: $reason cleanup failed at $step: $error',
    );
  }
}
