# Release Evidence - 2026-03-06

## Candidate metadata
- Date/time (MSK): 2026-03-06 15:59:03
- Branch: `dev`
- Commit (short): `0d3e307`
- Telemetry release flags: `ENABLE_ERROR_REPORTING=false`, `ENABLE_DIAGNOSTIC_EVENTS=false`

## Automated gates
- `bash tool/pre_release_safety_checks.sh` -> PASS
- `flutter analyze --fatal-infos --fatal-warnings` -> PASS
- `flutter test` -> PASS
- `bash tool/with_release_env.sh flutter build apk --release --dart-define=ENABLE_ERROR_REPORTING=false --dart-define=ENABLE_DIAGNOSTIC_EVENTS=false` -> PASS
- `bash tool/with_release_env.sh flutter build appbundle --release --dart-define=ENABLE_ERROR_REPORTING=false --dart-define=ENABLE_DIAGNOSTIC_EVENTS=false` -> PASS
- `flutter build ios --release --no-codesign --dart-define=ENABLE_ERROR_REPORTING=false --dart-define=ENABLE_DIAGNOSTIC_EVENTS=false` -> PASS

## Artifact manifest
- APK: `build/app/outputs/flutter-apk/app-release.apk`
  - size: 57M
  - sha256: `d7035131f4639ff3f1ca5d90e7ef5b49e10417caa6978581ee73ff76e11752e6`
- AAB: `build/app/outputs/bundle/release/app-release.aab`
  - size: 47M
  - sha256: `455bc38243343a129c778b9654c246e57d2215a0da8880f927200ec2a164890d`
- iOS app bundle (no-codesign build output): `build/ios/iphoneos/Runner.app`

## Manual smoke matrix (release mode)
- iPhone (iOS 26.3): PASS
  - fresh login
  - kill/reopen session restore
  - logout/login again
  - background/foreground stability
- iPad (iOS 26.3): PASS
  - fresh login
  - kill/reopen session restore
  - logout/login again
  - background/foreground stability
- Android physical device: PENDING (no Android device/ADB on current workstation session)

## Security posture checks for this candidate
- Local plaintext secret files are redacted placeholders only (`.env`, `.secrets`, `.local_signing/android-signing.env`).
- Signing secrets are injected from Keychain via `tool/with_release_env.sh`.
- Release defaults keep production telemetry disabled.

## Remaining conditions before store submission
- Android physical-device release smoke test is still required.
- Developer accounts are not yet active (Google Play Console / Apple paid developer account), so store upload/compliance steps cannot be executed yet.

## Current recommendation
- Engineering readiness: **GO WITH CONDITIONS**.
- Do not submit to stores until the two conditions above are closed.
