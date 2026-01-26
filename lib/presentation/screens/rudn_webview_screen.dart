import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:seasons/core/services/rudn_auth_service.dart';

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
            if (url.startsWith('https://seasons.rudn.ru')) {
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
            if (request.url.startsWith('http://seasons.rudn.ru')) {
              final secureUrl = request.url.replaceFirst('http://', 'https://');
              if (kDebugMode) {
                print('Upgrading insecure redirect to: $secureUrl');
              }
              _controller.loadRequest(Uri.parse(secureUrl));
              return NavigationDecision.prevent;
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

    _controller.loadRequest(Uri.parse('https://seasons.rudn.ru?lang=${widget.languageCode}'));

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
    if (!mounted) return;
    try {
      // Use JavaScript to get cookies from the current page
      final cookieString = await _controller.runJavaScriptReturningResult(
        'document.cookie',
      );

      // Parse the cookie string (format: "name1=value1; name2=value2")
      final cookies = cookieString.toString();

      // Remove quotes if present (JavaScript returns quoted string)
      final cleanCookies = cookies.replaceAll('"', '');

      if (cleanCookies.isNotEmpty && cleanCookies != 'null') {
        // Split into individual cookies
        final cookieList = cleanCookies.split(';');

        for (final cookie in cookieList) {
          final parts = cookie.trim().split('=');
          if (parts.length >= 2) {
            final name = parts[0].trim();
            final value = parts.sublist(1).join('=').trim();

            if (name == 'session' && value.isNotEmpty) {
              // Session cookie found
              await RudnAuthService().saveCookie(value);

              if (mounted) {
                _cookieCheckTimer?.cancel();
                Navigator.of(context).pop(true);
              }
              return;
            }
          }
        }
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
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
