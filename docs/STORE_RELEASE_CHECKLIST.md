# Store Release Checklist (Google Play + Apple App Store)

Last verified: 2026-02-17

## Automated quality gates

- [x] `flutter analyze --fatal-infos --fatal-warnings`
- [x] `flutter test --coverage`
- [x] Coverage >= 50% (current: 53.28%)
- [x] Android release APK build (signed)
- [x] Android release AAB build (signed)
- [x] iOS archive build (`flutter build ipa --release --no-codesign`)

## Security and transport checks

- [x] Android cleartext disabled (`network_security_config.xml`: `cleartextTrafficPermitted="false"`)
- [x] iOS ATS insecure HTTP exception removed (`NSExceptionAllowsInsecureHTTPLoads` not present)
- [x] Release Android builds fail if signing env is missing
- [x] Non-essential `RECEIVE_BOOT_COMPLETED` permission removed from merged manifest

## Platform metadata checks

- [x] Android package: `lebedev.seasons`
- [x] Android version: `1.1.0` (`versionCode=9`)
- [x] Android `targetSdkVersion=36` (verified from merged release manifest)
- [x] iOS bundle id: `com.lebedev.seasons`
- [x] iOS version: `1.1.0` (`build=9`)
- [x] iOS deployment target aligned to `15.0`
- [x] iOS placeholder launch image warning resolved

## CI/CD gates

- [x] Analyze step is strict (`--fatal-infos --fatal-warnings`)
- [x] Coverage threshold enforced in CI
- [x] Android signing secrets required and validated in CI
- [x] CodeQL runs for Android (`java-kotlin`) and iOS (`swift`)

## Policy references to track before submission

- Google Play target API policy:
  https://support.google.com/googleplay/android-developer/answer/11926878
- Apple upcoming app requirements:
  https://developer.apple.com/news/upcoming-requirements/

## Manual console tasks (must be completed by release owner)

- [ ] Google Play: complete/update Data safety form
- [ ] Google Play: declare foreground service usage with accurate use case text
- [ ] Google Play: verify app content rating and target audience
- [ ] Google Play: upload production privacy policy URL
- [ ] Google Play: verify store listing assets (icon, screenshots, feature graphic)
- [ ] Google Play: create release notes for this version
- [ ] App Store Connect: update privacy nutrition labels
- [ ] App Store Connect: verify export compliance / encryption answers
- [ ] App Store Connect: upload screenshots for all required device classes
- [ ] App Store Connect: complete app review notes and test account details (if needed)
- [ ] App Store Connect: sign archive with production certificate and provisioning profile

## Recommended pre-release smoke tests

- [ ] Fresh install login flow
- [ ] Session restore after app restart
- [ ] Voting registration flow
- [ ] Vote submit flow
- [ ] Results screen rendering
- [ ] Push/local notification tap navigation
- [ ] Logout and session cleanup
- [ ] Offline and flaky-network behavior
