import 'dart:io';

const String iosSafariUserAgent =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';
const String androidChromeUserAgent =
    'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

String mobileUserAgentForPlatform({String? operatingSystem}) {
  final normalizedOs =
      (operatingSystem ?? Platform.operatingSystem).toLowerCase().trim();
  if (normalizedOs == 'android') {
    return androidChromeUserAgent;
  }
  return iosSafariUserAgent;
}
