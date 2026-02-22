import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:seasons/core/services/rudn_auth_service.dart';
import 'package:seasons/core/services/error_reporting_service.dart';
import 'package:seasons/core/utils/safe_log.dart';
import 'package:seasons/presentation/widgets/seasons_loader.dart';

class RudnWebviewScreen extends StatefulWidget {
  final String languageCode;

  const RudnWebviewScreen({super.key, required this.languageCode});

  @override
  State<RudnWebviewScreen> createState() => _RudnWebviewScreenState();
}

class _RudnWebviewScreenState extends State<RudnWebviewScreen> {
  static const Duration _callbackCookiePollTimeout =
      Duration(milliseconds: 500);
  static const Duration _callbackCookiePollStep = Duration(milliseconds: 50);

  late final WebViewController _controller;
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  bool _isLoading = true;
  bool _isFinishingLogin = false;
  Timer? _cookieCheckTimer;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });

            // Auto-click the login button when homepage loads
            if (isAllowedWebViewUrl(url)) {
              // Efficiently poll for the login button
              await _controller.runJavaScript('''
                (function() {
                  var attempts = 0;
                  var maxAttempts = 50; // 5 seconds timeout
                  
                  var checkExist = setInterval(function() {
                     var loginBtn = document.getElementById('bt-entry');
                     if (loginBtn) {
                        loginBtn.click();
                        clearInterval(checkExist);
                     }
                     attempts++;
                     if (attempts >= maxAttempts) {
                       clearInterval(checkExist);
                     }
                  }, 100); // Check every 100ms
                })();
              ''');
            }

            await _checkCookies();
          },
          onWebResourceError: (WebResourceError error) {
            // Error logging removed for production
          },
          onNavigationRequest: (NavigationRequest request) {
            final action = resolveWebViewNavigationAction(request.url);
            switch (action) {
              case WebViewNavigationAction.preventAndUpgrade:
                final secureUrl = upgradeToHttps(request.url);
                if (kDebugMode) {
                  debugPrint(
                    'Upgrading insecure redirect to ${sanitizeUrlForLog(secureUrl)}',
                  );
                }
                _controller.loadRequest(Uri.parse(secureUrl));
                return NavigationDecision.prevent;
              case WebViewNavigationAction.preventAndFinishLogin:
                final callbackUrl = shouldUpgradeToHttps(request.url)
                    ? upgradeToHttps(request.url)
                    : request.url;
                unawaited(_handleAuthCallbackIntercepted(callbackUrl));
                return NavigationDecision.prevent;
              case WebViewNavigationAction.prevent:
                if (kDebugMode) {
                  debugPrint(
                    'Blocked WebView navigation to ${sanitizeUrlForLog(request.url, keepQuery: true)}',
                  );
                }
                return NavigationDecision.prevent;
              case WebViewNavigationAction.navigate:
                return NavigationDecision.navigate;
            }
          },
        ),
      );
    _initWebView();
  }

  Future<void> _initWebView() async {
    try {
      // Only clear cookies to ensure fresh login, but KEEP CACHE for speed
      await _cookieManager.clearCookies();
    } catch (e) {
      // Error ignored
    }

    if (!mounted) return;

    // Set a standard User Agent to avoid being blocked/looping
    const userAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1";
    await _controller.setUserAgent(userAgent);

    _controller.loadRequest(
        Uri.parse('https://seasons.rudn.ru?lang=${widget.languageCode}'));

    // Start periodic check for session cookie (increased frequency for speed)
    _startCookieCheckTimer();
  }

  @override
  void dispose() {
    _cookieCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkCookies() async {
    if (!mounted || _hasPopped || _isFinishingLogin) return;
    try {
      final sessionCookie = await _readSessionCookieFromDocument();
      if (sessionCookie != null) {
        await _completeLoginAndPop(sessionCookie);
      }
    } catch (e) {
      // Error ignored - page might not be ready yet
    }
  }

  Future<void> _handleAuthCallbackIntercepted(String callbackUrl) async {
    if (!mounted || _hasPopped || _isFinishingLogin) return;

    if (kDebugMode) {
      debugPrint(
        'Intercepted oauth callback before render: ${sanitizeUrlForLog(callbackUrl)}',
      );
    }

    setState(() {
      _isFinishingLogin = true;
      _isLoading = false;
    });
    _cookieCheckTimer?.cancel();

    final sessionCookie = await _pollSessionCookieFromDocument();
    if (sessionCookie == null) {
      ErrorReportingService().reportEvent('webview_callback_cookie_missing');

      if (!mounted || _hasPopped) return;
      setState(() {
        _isFinishingLogin = false;
      });
      _startCookieCheckTimer();
      return;
    }

    await _completeLoginAndPop(sessionCookie);
  }

  void _startCookieCheckTimer() {
    _cookieCheckTimer?.cancel();
    _cookieCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      unawaited(_checkCookies());
    });
  }

  Future<String?> _readSessionCookieFromDocument() async {
    final cookieString = await _controller.runJavaScriptReturningResult(
      'document.cookie',
    );
    return extractSessionCookieValue(cookieString.toString());
  }

  Future<String?> _pollSessionCookieFromDocument() async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < _callbackCookiePollTimeout) {
      if (_hasPopped) return null;
      try {
        final cookie = await _readSessionCookieFromDocument();
        if (cookie != null) {
          return cookie;
        }
      } catch (_) {}

      await Future<void>.delayed(_callbackCookiePollStep);
    }
    return null;
  }

  Future<void> _completeLoginAndPop(String sessionCookie) async {
    await RudnAuthService().saveCookie(sessionCookie);
    ErrorReportingService().reportEvent('webview_cookie_found', details: {
      'cookie_length': '${sessionCookie.length}',
    });

    if (mounted && !_hasPopped) {
      _hasPopped = true;
      _cookieCheckTimer?.cancel();
      ErrorReportingService().reportEvent('webview_popping');
      Navigator.of(context).pop(true);
      return;
    }

    ErrorReportingService()
        .reportEvent('webview_duplicate_pop_blocked', details: {
      'mounted': '$mounted',
      'hasPopped': '$_hasPopped',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: _isFinishingLogin ? 0 : 1,
            child: IgnorePointer(
              ignoring: _isFinishingLogin,
              child: WebViewWidget(controller: _controller),
            ),
          ),
          if (_isLoading)
            const Center(
              child: SeasonsLoader(),
            ),
          if (_isFinishingLogin)
            Container(
              color: Colors.black.withValues(alpha: 0.72),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SeasonsLoader(),
                    SizedBox(height: 20),
                    Text(
                      'Finishing login...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum WebViewNavigationAction {
  navigate,
  prevent,
  preventAndUpgrade,
  preventAndFinishLogin,
}

const Set<String> _allowedWebViewHosts = {
  'seasons.rudn.ru',
  'id.rudn.ru',
};

const Set<String> _blockedWebViewSchemes = {
  'file',
  'data',
  'javascript',
  'intent',
  'chrome',
  'blob',
};

const String _seasonsHost = 'seasons.rudn.ru';
const String _authCallbackPath = '/oauth/login_callback';

@visibleForTesting
bool shouldUpgradeToHttps(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;
  return uri.scheme.toLowerCase() == 'http' &&
      uri.host.toLowerCase() == _seasonsHost;
}

@visibleForTesting
String upgradeToHttps(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  return uri.replace(scheme: 'https').toString();
}

@visibleForTesting
bool isExpectedAuthCallbackUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || !uri.hasScheme) return false;
  return uri.scheme.toLowerCase() == 'https' &&
      uri.host.toLowerCase() == _seasonsHost &&
      uri.path == _authCallbackPath;
}

@visibleForTesting
bool isAllowedWebViewUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || !uri.hasScheme) return false;

  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'about') {
    final aboutPath = uri.path.toLowerCase();
    return aboutPath == 'blank' || aboutPath == 'srcdoc';
  }
  if (_blockedWebViewSchemes.contains(scheme)) return false;
  if (scheme != 'https') return false;

  final host = uri.host.toLowerCase();
  if (host.isEmpty) return false;
  return _allowedWebViewHosts.contains(host);
}

@visibleForTesting
WebViewNavigationAction resolveWebViewNavigationAction(String rawUrl) {
  if (shouldUpgradeToHttps(rawUrl)) {
    final upgradedUrl = upgradeToHttps(rawUrl);
    if (isExpectedAuthCallbackUrl(upgradedUrl)) {
      return WebViewNavigationAction.preventAndFinishLogin;
    }
    return WebViewNavigationAction.preventAndUpgrade;
  }

  if (isExpectedAuthCallbackUrl(rawUrl)) {
    return WebViewNavigationAction.preventAndFinishLogin;
  }

  if (!isAllowedWebViewUrl(rawUrl)) {
    return WebViewNavigationAction.prevent;
  }

  return WebViewNavigationAction.navigate;
}

@visibleForTesting
String? extractSessionCookieValue(String rawCookieString) {
  final cleanCookies = rawCookieString.replaceAll('"', '').trim();
  if (cleanCookies.isEmpty || cleanCookies == 'null') {
    return null;
  }

  for (final cookie in cleanCookies.split(';')) {
    final parts = cookie.trim().split('=');
    if (parts.length < 2) {
      continue;
    }
    final name = parts.first.trim();
    final value = parts.sublist(1).join('=').trim();
    if (name == 'session' && value.isNotEmpty) {
      return value;
    }
  }

  return null;
}
