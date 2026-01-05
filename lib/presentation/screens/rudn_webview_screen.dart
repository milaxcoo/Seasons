import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:seasons/core/services/rudn_auth_service.dart';

class RudnWebviewScreen extends StatefulWidget {
  const RudnWebviewScreen({super.key});

  @override
  State<RudnWebviewScreen> createState() => _RudnWebviewScreenState();
}

class _RudnWebviewScreenState extends State<RudnWebviewScreen> {
  late final WebViewController _controller;
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
            // print("Webview: Page started: $url");
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            // print("Webview: Page finished: $url");
            setState(() {
              _isLoading = false;
            });
            // Still check on finish
            await _checkCookies(url);
          },
          onWebResourceError: (WebResourceError error) {
            // Error logging removed for production
          },
          onNavigationRequest: (NavigationRequest request) {
            // print("Webview: Navigating to: ${request.url}");
            return NavigationDecision.navigate;
          },
        ),
      );
    // We postpone the load until cookies are cleared to ensure a fresh session
    _initWebView();
  }

  Future<void> _initWebView() async {
    try {
      await _controller.clearCache();
      await WebviewCookieManager().clearCookies();
      if (mounted) {}
    } catch (e) {
      // Error ignored
    }

    if (!mounted) return;

    // Set a standard User Agent to avoid being blocked/looping
    const userAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1";
    await _controller.setUserAgent(userAgent);

    _controller.loadRequest(Uri.parse('https://seasons.rudn.ru'));

    // Start periodic check
    _cookieCheckTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _checkCookies("current");
    });
  }

  @override
  void dispose() {
    _cookieCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkCookies(String url) async {
    try {
      final cookieManager = WebviewCookieManager();

      final domainsToCheck = [
        url == "current" ? null : url,
        'https://seasons.rudn.ru', // The user states this is the ONLY place
        'https://id.rudn.ru',
        'https://rudn.ru',
      ].whereType<String>().toSet().toList(); // Unique and non-null

      for (final domain in domainsToCheck) {
        if (domain.isEmpty || domain == 'about:blank') continue;

        try {
          final cookies = await cookieManager.getCookies(domain);
          if (cookies.isNotEmpty) {
            // print("Webview: Checking domain $domain. Found ${cookies.length} cookies."); // Reduced spam
            for (final cookie in cookies) {
              // Only log if we find something interesting or for very verbose debug (commented out)
              if (cookie.name == 'session' && cookie.value.isNotEmpty) {
                // Session cookie found
                await RudnAuthService().saveCookie(cookie.value);

                if (mounted) {
                  _cookieCheckTimer?.cancel();
                  Navigator.of(context).pop(true);
                }
                return;
              }
            }
          }
        } catch (e) {
          // ignore specific domain errors
        }
      }
    } catch (e) {
      if (!e.toString().contains("MissingPluginException")) {
        // Error ignored
      }
    }
  }

  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RUDN ID Login'),
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
