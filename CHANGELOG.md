# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-01-11

> **Note:** Push notification infrastructure is included in this release but will be activated in a future update pending backend API implementation.

### Security
- **[CRITICAL]** Replaced Android debug key signing with production environment variable configuration
  - Release builds now require `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` to be set
  - Prevents accidental distribution with debug keys
- **[HIGH]** Hardened iOS App Transport Security (ATS) configuration
  - Removed permissive `NSAllowsArbitraryLoads` setting
  - Added domain-specific exception for `seasons.rudn.ru` with HTTPS enforcement only
  - All other network connections now enforce secure HTTPS
- **[HIGH]** Removed Firebase API keys from Git history
  - Executed `git filter-branch` to purge `lib/firebase_options.dart` from 153 commits
  - File properly gitignored to prevent future commits
  - **Action Required:** Verify Firebase Console API key restrictions

### Added
- New authentication implementation using WebView-based login
  - Secure cookie storage via `flutter_secure_storage`
  - Proper dependency injection for testability
  - Session persistence across app restarts
- Comprehensive CI/CD pipeline with GitHub Actions
  - Parallel jobs: format, analyze, test, Android build, iOS build
  - Code coverage reporting with Codecov
  - Automated mock file generation for Firebase configs
  - Release artifact uploads (Android APK)
- Enhanced test suite
  - Added 16 unit tests for `RudnAuthService` (100% coverage)
  - Total test count: 144 tests, all passing
  - Improved integration tests for full authentication flow

### Changed
- Replaced deprecated `webview_cookie_manager` with built-in `webview_flutter` cookie management
- Upgraded Android Gradle Plugin (AGP) to 8.6.0 for better compatibility
- Increased Android `minSdkVersion` from 23 to 24 for WebView compatibility
- Refactored `RudnAuthService` with dependency injection pattern for improved testability
- Updated results screen parsing to handle empty API response arrays robustly
- Improved results screen display formatting for `qualification_council` question type

### Fixed
- Results screen bug: parsing now handles empty arrays from API responses
- Results screen display: added vertical table dividers for better readability
- Removed unnecessary string interpolation (static analysis compliance)
- Fixed formatting issues across multiple Dart files

### Deprecated
- Removed `webview_cookie_manager` package (replaced with `webview_flutter` built-in)

## [1.0.0] - Initial Release

### Added
- Initial Flutter application structure
- Voting events list view with status filtering
- User profile screen with RUDN authentication
- Push notifications support via Firebase Cloud Messaging
- Multi-language support (Russian)
- Custom theming with seasonal backgrounds

---

## Migration Guide

### For Developers

**If upgrading from a commit before the security fixes:**

1. **Android Release Builds:** Set the following environment variables before building:
   ```bash
   export KEYSTORE_PATH="/path/to/release.keystore"
   export KEYSTORE_PASSWORD="your_keystore_password"
   export KEY_ALIAS="your_key_alias"
   export KEY_PASSWORD="your_key_password"
   flutter build appbundle --release
   ```

2. **Firebase Configuration:** Regenerate `lib/firebase_options.dart` using:
   ```bash
   flutterfire configure
   ```

3. **Clean Build:** After pulling these changes:
   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   flutter test
   ```

### For CI/CD

**GitHub Actions Secrets Required:**
- `KEYSTORE_BASE64` - Base64-encoded release keystore file
- `KEYSTORE_PASSWORD` - Keystore password
- `KEY_ALIAS` - Key alias name
- `KEY_PASSWORD` - Key password

**Example workflow update:**
```yaml
- name: Decode Keystore
  run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > release.keystore

- name: Build Android
  env:
    KEYSTORE_PATH: ./release.keystore
    KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
    KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
    KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
  run: flutter build appbundle --release
```

---

## Notes

- **Breaking Change:** Android release builds will fail without proper keystore configuration
- **Security:** Firebase API keys must have console restrictions configured (SHA-256, bundle ID)
- **iOS:** ATS now restricts network traffic, may affect development against non-HTTPS backends
