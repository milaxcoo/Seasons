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
  static const Duration _phaseBCookiePollTimeout = Duration(milliseconds: 8000);
  static const Duration _phaseBCookiePollStep = Duration(milliseconds: 100);
  static const Duration _phaseAWaitCallbackTimeout = Duration(seconds: 18);

  late final WebViewController _controller;
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  bool _isLoading = true;
  WebViewFinalizationState _finalizationState =
      const WebViewFinalizationState.initial();
  bool _isCallbackCompletionInProgress = false;
  bool _isRetryInProgress = false;
  String? _lastCallbackUrl;
  String? _lastForcedNavigationUrl;
  int _finalizationRunId = 0;
  Timer? _cookieCheckTimer;
  Timer? _phaseATimeoutTimer;
  bool _hasPopped = false;

  bool get _isFinishingLogin => _finalizationState.isFinishing;
  bool get _hasFinishingError => _finalizationState.hasError;
  String get _finishingErrorMessage => _finalizationState.errorMessage;
  bool get _webViewHiddenAfterCallback =>
      _finalizationState.webViewHiddenAfterCallback;
  bool get _isWaitingCallbackLoad =>
      _finalizationState.phase == WebViewFinalizationPhase.waitingCallbackLoad;
  bool get _isPollingCookie =>
      _finalizationState.phase == WebViewFinalizationPhase.pollingCookie;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (!mounted) return;
            if (_webViewHiddenAfterCallback) return;
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
              unawaited(_onCallbackPageFinished(url));
              return;
            }

            if (_webViewHiddenAfterCallback) {
              return;
            }

            // Auto-click the login button when homepage loads
            if (shouldAutoClickEntryButton(
              url: url,
              webViewHiddenAfterCallback: _webViewHiddenAfterCallback,
            )) {
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
            _logNavigationDecision(
              url: request.url,
              action: action,
            );
            switch (action) {
              case WebViewNavigationAction.preventAndUpgrade:
                final secureUrl = upgradeToHttps(request.url);
                if (isExpectedAuthCallbackUrl(secureUrl)) {
                  _startFinishingLogin(secureUrl);
                }
                unawaited(
                  _forceLoadRequestOnce(
                    secureUrl,
                    reason: 'upgrade_to_https_callback',
                  ),
                );
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

    _logForcedNavigation(
      method: 'loadRequest',
      url: 'https://seasons.rudn.ru?lang=${widget.languageCode}',
      reason: 'initial_open',
      skipped: false,
    );
    _controller.loadRequest(
        Uri.parse('https://seasons.rudn.ru?lang=${widget.languageCode}'));

    // Start periodic check for session cookie (increased frequency for speed)
    _startCookieCheckTimer();
  }

  @override
  void dispose() {
    _cookieCheckTimer?.cancel();
    _phaseATimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkCookies() async {
    if (!mounted ||
        _hasPopped ||
        _isFinishingLogin ||
        _webViewHiddenAfterCallback) {
      return;
    }
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
    _lastCallbackUrl = callbackUrl;
    if (_isFinishingLogin && !_hasFinishingError) {
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
      _finalizationState = _finalizationState.onCallbackDetected();
      _isLoading = false;
    });
    _cookieCheckTimer?.cancel();
    _finalizationRunId += 1;
    _phaseATimeoutTimer?.cancel();
    _startPhaseATimeout(_finalizationRunId);
  }

  Future<void> _onCallbackPageFinished(String callbackUrl) async {
    if (!_isWaitingCallbackLoad || !_isFinishingLogin) {
      return;
    }

    _phaseATimeoutTimer?.cancel();
    if (mounted) {
      setState(() {
        _finalizationState = _finalizationState.onCallbackPageFinished();
      });
    }

    await _startCookiePollingPhase(
      callbackUrl,
      _finalizationRunId,
    );
  }

  Future<void> _startCookiePollingPhase(
    String callbackUrl,
    int runId,
  ) async {
    if (!shouldStartCallbackCompletion(
      isMounted: mounted,
      hasPopped: _hasPopped,
      isFinishing: _isFinishingLogin,
      isCompletionInProgress: _isCallbackCompletionInProgress,
    )) {
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
      if (runId != _finalizationRunId ||
          !_isPollingCookie ||
          !_isFinishingLogin) {
        return;
      }

      if (sessionCookie == null) {
        ErrorReportingService().reportEvent('webview_callback_cookie_missing');

        _showPhaseBTimeoutError();
        return;
      }

      await _completeLoginAndPop(sessionCookie);
    } catch (_) {
      if (runId == _finalizationRunId &&
          _isPollingCookie &&
          _isFinishingLogin) {
        _showFinishingError(WebViewFinalizationState.phaseBTimeoutMessage);
      }
    } finally {
      if (runId == _finalizationRunId) {
        _isCallbackCompletionInProgress = false;
      }
    }
  }

  void _startPhaseATimeout(int runId) {
    _phaseATimeoutTimer?.cancel();
    _phaseATimeoutTimer = Timer(
      _phaseAWaitCallbackTimeout,
      () => _onPhaseATimeoutFired(runId),
    );
  }

  void _onPhaseATimeoutFired(int runId) {
    if (runId != _finalizationRunId ||
        !mounted ||
        _hasPopped ||
        !_isFinishingLogin ||
        !_isWaitingCallbackLoad) {
      return;
    }

    _showPhaseATimeoutError();
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
    return pollForSessionCookie(
      readCookie: _readSessionCookieFromDocument,
      timeout: _phaseBCookiePollTimeout,
      step: _phaseBCookiePollStep,
      shouldStop: () => _hasPopped,
    );
  }

  Future<void> _completeLoginAndPop(String sessionCookie) async {
    await RudnAuthService().saveCookie(sessionCookie);
    ErrorReportingService().reportEvent('webview_cookie_found', details: {
      'cookie_length': '${sessionCookie.length}',
    });

    if (mounted && !_hasPopped) {
      _hasPopped = true;
      _cookieCheckTimer?.cancel();
      _phaseATimeoutTimer?.cancel();
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

  void _showPhaseATimeoutError() {
    _showFinishingError(WebViewFinalizationState.phaseATimeoutMessage);
  }

  void _showPhaseBTimeoutError() {
    _showFinishingError(WebViewFinalizationState.phaseBTimeoutMessage);
  }

  void _showFinishingError(String message) {
    if (!mounted || _hasPopped) return;
    _phaseATimeoutTimer?.cancel();
    setState(() {
      _finalizationState = _finalizationState.onError(message);
      _isLoading = false;
    });
  }

  Future<void> _retryLogin() async {
    if (!mounted || _hasPopped || _isRetryInProgress) return;
    _isRetryInProgress = true;

    _cookieCheckTimer?.cancel();
    _phaseATimeoutTimer?.cancel();
    _isCallbackCompletionInProgress = false;
    _lastForcedNavigationUrl = null;
    _finalizationRunId += 1;

    setState(() {
      _finalizationState = _finalizationState.onRetry();
      _isLoading = false;
    });

    _startPhaseATimeout(_finalizationRunId);

    try {
      final callbackUrl = _lastCallbackUrl;
      if (callbackUrl != null) {
        await _forceLoadRequestOnce(
          callbackUrl,
          reason: 'retry_callback',
        );
      } else {
        await _forceReloadOnce(reason: 'retry_reload');
      }
    } catch (_) {
      _showFinishingError(WebViewFinalizationState.phaseBTimeoutMessage);
    } finally {
      _isRetryInProgress = false;
    }
  }

  void _cancelLogin() {
    if (!mounted || _hasPopped) return;
    _hasPopped = true;
    _isRetryInProgress = false;
    _cookieCheckTimer?.cancel();
    _phaseATimeoutTimer?.cancel();
    Navigator.of(context).pop(false);
  }

  Future<void> _forceLoadRequestOnce(
    String url, {
    required String reason,
  }) async {
    if (!mounted || _hasPopped) return;
    if (!shouldForceNavigation(_lastForcedNavigationUrl, url)) {
      _logForcedNavigation(
        method: 'loadRequest',
        url: url,
        reason: reason,
        skipped: true,
      );
      return;
    }

    _lastForcedNavigationUrl = url;
    _logForcedNavigation(
      method: 'loadRequest',
      url: url,
      reason: reason,
      skipped: false,
    );
    await _controller.loadRequest(Uri.parse(url));
  }

  Future<void> _forceReloadOnce({required String reason}) async {
    if (!mounted || _hasPopped) return;
    const reloadMarker = '__reload__';
    if (!shouldForceNavigation(_lastForcedNavigationUrl, reloadMarker)) {
      _logForcedNavigation(
        method: 'reload',
        reason: reason,
        skipped: true,
      );
      return;
    }

    _lastForcedNavigationUrl = reloadMarker;
    _logForcedNavigation(
      method: 'reload',
      reason: reason,
      skipped: false,
    );
    await _controller.reload();
  }

  void _logNavigationDecision({
    required String url,
    required WebViewNavigationAction action,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      'WebView.delegate navigation_request url=${sanitizeUrlForLog(url)} action=${navigationActionLabel(action)}',
    );
  }

  void _logForcedNavigation({
    required String method,
    String? url,
    required String reason,
    required bool skipped,
  }) {
    if (!kDebugMode) return;
    final sanitizedUrl = url == null ? 'n/a' : sanitizeUrlForLog(url);
    debugPrint(
      'WebView.delegate forced_$method reason=$reason skipped=$skipped url=$sanitizedUrl',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Stack(
        children: [
          Offstage(
            offstage: _webViewHiddenAfterCallback,
            child: IgnorePointer(
              ignoring: _webViewHiddenAfterCallback,
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

typedef DelayCallback = Future<void> Function(Duration duration);
typedef NowProvider = DateTime Function();

@visibleForTesting
class WebViewFinalizationState {
  static const String phaseATimeoutMessage =
      'Login is taking longer than expected. Please retry.';
  static const String phaseBTimeoutMessage =
      'Could not complete login. Please retry or cancel.';

  final bool webViewHiddenAfterCallback;
  final bool isFinishing;
  final bool hasError;
  final String errorMessage;
  final WebViewFinalizationPhase phase;

  const WebViewFinalizationState._({
    required this.webViewHiddenAfterCallback,
    required this.isFinishing,
    required this.hasError,
    required this.errorMessage,
    required this.phase,
  });

  const WebViewFinalizationState.initial()
      : this._(
          webViewHiddenAfterCallback: false,
          isFinishing: false,
          hasError: false,
          errorMessage: '',
          phase: WebViewFinalizationPhase.idle,
        );

  WebViewFinalizationState onCallbackDetected() {
    return const WebViewFinalizationState._(
      webViewHiddenAfterCallback: true,
      isFinishing: true,
      hasError: false,
      errorMessage: '',
      phase: WebViewFinalizationPhase.waitingCallbackLoad,
    );
  }

  WebViewFinalizationState onCallbackPageFinished() {
    return const WebViewFinalizationState._(
      webViewHiddenAfterCallback: true,
      isFinishing: true,
      hasError: false,
      errorMessage: '',
      phase: WebViewFinalizationPhase.pollingCookie,
    );
  }

  WebViewFinalizationState onError(String message) {
    return WebViewFinalizationState._(
      webViewHiddenAfterCallback: true,
      isFinishing: true,
      hasError: true,
      errorMessage: message,
      phase: WebViewFinalizationPhase.error,
    );
  }

  WebViewFinalizationState onRetry() {
    return const WebViewFinalizationState._(
      webViewHiddenAfterCallback: true,
      isFinishing: true,
      hasError: false,
      errorMessage: '',
      phase: WebViewFinalizationPhase.waitingCallbackLoad,
    );
  }

  WebViewFinalizationState onPhaseATimeout() {
    return onError(phaseATimeoutMessage);
  }

  WebViewFinalizationState onPhaseBTimeout() {
    return onError(phaseBTimeoutMessage);
  }
}

enum WebViewFinalizationPhase {
  idle,
  waitingCallbackLoad,
  pollingCookie,
  error,
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
      uri.host.toLowerCase() == _seasonsHost &&
      uri.path == _authCallbackPath;
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
String navigationActionLabel(WebViewNavigationAction action) {
  switch (action) {
    case WebViewNavigationAction.navigate:
      return 'allow';
    case WebViewNavigationAction.prevent:
      return 'prevent';
    case WebViewNavigationAction.preventAndUpgrade:
      return 'upgrade';
    case WebViewNavigationAction.navigateAndFinishLogin:
      return 'callback-finalize';
  }
}

@visibleForTesting
bool shouldForceNavigation(String? lastForcedNavigationUrl, String nextUrl) {
  return lastForcedNavigationUrl != nextUrl;
}

@visibleForTesting
bool shouldStartCallbackCompletion({
  required bool isMounted,
  required bool hasPopped,
  required bool isFinishing,
  required bool isCompletionInProgress,
}) {
  if (!isMounted || hasPopped || !isFinishing || isCompletionInProgress) {
    return false;
  }
  return true;
}

@visibleForTesting
bool shouldAutoClickEntryButton({
  required String url,
  required bool webViewHiddenAfterCallback,
}) {
  if (webViewHiddenAfterCallback) return false;
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;
  if (uri.scheme.toLowerCase() != 'https') return false;
  if (uri.host.toLowerCase() != _seasonsHost) return false;
  return uri.path.isEmpty || uri.path == '/';
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

Future<void> _defaultDelay(Duration duration) {
  return Future<void>.delayed(duration);
}

DateTime _defaultNow() {
  return DateTime.now();
}

@visibleForTesting
Future<String?> pollForSessionCookie({
  required Future<String?> Function() readCookie,
  required Duration timeout,
  required Duration step,
  DelayCallback delay = _defaultDelay,
  NowProvider now = _defaultNow,
  bool Function()? shouldStop,
}) async {
  final deadline = now().add(timeout);
  while (now().isBefore(deadline)) {
    if (shouldStop?.call() == true) {
      return null;
    }

    try {
      final cookie = await readCookie();
      if (cookie != null) {
        return cookie;
      }
    } catch (_) {}

    if (!now().isBefore(deadline)) {
      break;
    }

    await delay(step);
  }
  return null;
}
