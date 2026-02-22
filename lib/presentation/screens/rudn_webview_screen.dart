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
      Duration(milliseconds: 2000);
  static const Duration _callbackCookiePollStep = Duration(milliseconds: 100);
  static const Duration _callbackOverallTimeout = Duration(seconds: 5);

  late final WebViewController _controller;
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  bool _isLoading = true;
  bool _isFinishingLogin = false;
  bool _isCallbackCompletionInProgress = false;
  bool _hasFinishingError = false;
  String _finishingErrorMessage = '';
  Timer? _cookieCheckTimer;
  Timer? _finishingTimeoutTimer;
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
            if (_isFinishingLogin) return;
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });

            if (isExpectedAuthCallbackUrl(url)) {
              unawaited(_handleCallbackPageFinished(url));
              return;
            }

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
              case WebViewNavigationAction.navigateAndFinishLogin:
                final callbackUrl = shouldUpgradeToHttps(request.url)
                    ? upgradeToHttps(request.url)
                    : request.url;
                _startFinishingLogin(callbackUrl);
                return NavigationDecision.navigate;
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
    _finishingTimeoutTimer?.cancel();
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

  void _startFinishingLogin(String callbackUrl) {
    if (!mounted || _hasPopped) return;
    if (_isFinishingLogin) {
      if (kDebugMode) {
        debugPrint(
          'Ignoring duplicate oauth callback while finishing: ${sanitizeUrlForLog(callbackUrl)}',
        );
      }
      return;
    }

    if (kDebugMode) {
      debugPrint(
        'Intercepted oauth callback before render: ${sanitizeUrlForLog(callbackUrl)}',
      );
    }

    setState(() {
      _isFinishingLogin = true;
      _isLoading = false;
      _hasFinishingError = false;
      _finishingErrorMessage = '';
    });
    _cookieCheckTimer?.cancel();
    _finishingTimeoutTimer?.cancel();
    _finishingTimeoutTimer = Timer(_callbackOverallTimeout, () {
      if (!mounted || _hasPopped || !_isFinishingLogin) return;
      _showFinishingError(
        'Login is taking longer than expected. Please retry.',
      );
    });
  }

  Future<void> _handleCallbackPageFinished(String callbackUrl) async {
    if (!mounted ||
        _hasPopped ||
        !_isFinishingLogin ||
        _isCallbackCompletionInProgress) {
      return;
    }

    if (kDebugMode) {
      debugPrint(
        'OAuth callback finished loading: ${sanitizeUrlForLog(callbackUrl)}',
      );
    }

    _isCallbackCompletionInProgress = true;
    try {
      final sessionCookie = await _pollSessionCookieFromDocument();
      if (sessionCookie == null) {
        ErrorReportingService().reportEvent('webview_callback_cookie_missing');

        _showFinishingError(
          'Could not complete login. Please retry or cancel.',
        );
        return;
      }

      await _completeLoginAndPop(sessionCookie);
    } catch (_) {
      _showFinishingError(
        'Could not complete login. Please retry or cancel.',
      );
    } finally {
      _isCallbackCompletionInProgress = false;
    }
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
      _finishingTimeoutTimer?.cancel();
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

  void _showFinishingError(String message) {
    if (!mounted || _hasPopped) return;
    _finishingTimeoutTimer?.cancel();
    setState(() {
      _isFinishingLogin = true;
      _isLoading = false;
      _hasFinishingError = true;
      _finishingErrorMessage = message;
    });
  }

  Future<void> _retryLogin() async {
    if (!mounted || _hasPopped) return;

    _cookieCheckTimer?.cancel();
    _finishingTimeoutTimer?.cancel();
    _isCallbackCompletionInProgress = false;

    setState(() {
      _isFinishingLogin = false;
      _hasFinishingError = false;
      _finishingErrorMessage = '';
      _isLoading = true;
    });

    _startCookieCheckTimer();
    await _controller.loadRequest(
        Uri.parse('https://seasons.rudn.ru?lang=${widget.languageCode}'));
  }

  void _cancelLogin() {
    if (!mounted || _hasPopped) return;
    _hasPopped = true;
    _cookieCheckTimer?.cancel();
    _finishingTimeoutTimer?.cancel();
    Navigator.of(context).pop(false);
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
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_hasFinishingError) ...[
                      const SeasonsLoader(),
                      const SizedBox(height: 20),
                      const Text(
                        'Finishing login...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 34,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _finishingErrorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton(
                            onPressed: _retryLogin,
                            child: const Text('Retry'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _cancelLogin,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
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
  navigateAndFinishLogin,
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
    return WebViewNavigationAction.preventAndUpgrade;
  }

  if (isExpectedAuthCallbackUrl(rawUrl)) {
    return WebViewNavigationAction.navigateAndFinishLogin;
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
