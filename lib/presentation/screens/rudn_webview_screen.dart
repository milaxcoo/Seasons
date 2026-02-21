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
  late final WebViewController _controller;
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  bool _isLoading = true;
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
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
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
            if (shouldUpgradeToHttps(request.url)) {
              final secureUrl = upgradeToHttps(request.url);
              if (kDebugMode) {
                debugPrint(
                  'Upgrading insecure redirect to ${sanitizeUrlForLog(secureUrl)}',
                );
                if (secureUrl.contains('/oauth/login_callback')) {
                  debugPrint('Received oauth login_callback redirect');
                }
              }
              _controller.loadRequest(Uri.parse(secureUrl));
              return NavigationDecision.prevent;
            }
            if (!isAllowedWebViewUrl(request.url)) {
              if (kDebugMode) {
                debugPrint(
                  'Blocked WebView navigation to ${sanitizeUrlForLog(request.url, keepQuery: true)}',
                );
              }
              return NavigationDecision.prevent;
            }
            if (kDebugMode && request.url.contains('/oauth/login_callback')) {
              debugPrint('Received oauth login_callback redirect');
            }
            return NavigationDecision.navigate;
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
    _cookieCheckTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _checkCookies();
    });
  }

  @override
  void dispose() {
    _cookieCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkCookies() async {
    if (!mounted || _hasPopped) return;
    try {
      // Use JavaScript to get cookies from the current page
      final cookieString = await _controller.runJavaScriptReturningResult(
        'document.cookie',
      );

      final sessionCookie = extractSessionCookieValue(cookieString.toString());
      if (sessionCookie != null) {
        await RudnAuthService().saveCookie(sessionCookie);
        ErrorReportingService().reportEvent('webview_cookie_found', details: {
          'cookie_length': '${sessionCookie.length}',
        });

        if (mounted && !_hasPopped) {
          _hasPopped = true;
          _cookieCheckTimer?.cancel();
          ErrorReportingService().reportEvent('webview_popping');
          Navigator.of(context).pop(true);
        } else {
          ErrorReportingService()
              .reportEvent('webview_duplicate_pop_blocked', details: {
            'mounted': '$mounted',
            'hasPopped': '$_hasPopped',
          });
        }
        return;
      }
    } catch (e) {
      // Error ignored - page might not be ready yet
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: SeasonsLoader(),
            ),
        ],
      ),
    );
  }
}

const Set<String> _allowedWebViewHosts = {
  'seasons.rudn.ru',
};

const Set<String> _blockedWebViewSchemes = {
  'file',
  'data',
  'javascript',
  'intent',
  'about',
  'chrome',
  'blob',
};

@visibleForTesting
bool shouldUpgradeToHttps(String url) {
  return url.startsWith('http://seasons.rudn.ru');
}

@visibleForTesting
String upgradeToHttps(String url) {
  return url.replaceFirst('http://', 'https://');
}

@visibleForTesting
bool isAllowedWebViewUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || !uri.hasScheme) return false;

  final scheme = uri.scheme.toLowerCase();
  if (_blockedWebViewSchemes.contains(scheme)) return false;
  if (scheme != 'https') return false;

  final host = uri.host.toLowerCase();
  if (host.isEmpty) return false;
  return _allowedWebViewHosts.contains(host);
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
