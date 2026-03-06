# Release Runbook

Last reviewed: 2026-02-26

This runbook is the operational guide for a release candidate (RC) build and store submission.

## 1. Scope and ownership

- This document covers release execution steps.
- It does not decide legal ownership, publisher identity, or store account ownership.
- Record those decisions in [RELEASE_OWNERSHIP_DECISIONS_TEMPLATE.md](RELEASE_OWNERSHIP_DECISIONS_TEMPLATE.md).

## 2. Preconditions (go/no-go before building)

- `main` or `dev` has green GitHub Actions checks:
  - Flutter CI
  - CodeQL
- Release version in `pubspec.yaml` is finalized.
- Release notes draft exists for both stores.
- Required signing materials are available to the release operator.

## 3. Local quality checks

Run from repository root:

```bash
bash tool/pre_release_safety_checks.sh
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
```

Coverage target in CI is filtered coverage >= 50%.

## 4. Android signed build steps

The Android Gradle config requires these environment variables for release tasks:
- `KEYSTORE_PATH`
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`

Do not keep these values in plaintext files (for example `.secrets`, `.env`, `.local_signing/android-signing.env`).
Use macOS Keychain + secure injection script instead.

One-time keychain setup on the release workstation:

```bash
security add-generic-password -a "$USER" -s "votepfurapp_keystore_path" -w "/absolute/path/to/upload-keystore.jks" -U
security add-generic-password -a "$USER" -s "votepfurapp_keystore_password" -w "<redacted>" -U
security add-generic-password -a "$USER" -s "votepfurapp_key_alias" -w "<redacted>" -U
security add-generic-password -a "$USER" -s "votepfurapp_key_password" -w "<redacted>" -U
```

Build flow:

```bash
flutter pub get
bash tool/with_release_env.sh flutter build apk --release --dart-define=ENABLE_ERROR_REPORTING=false --dart-define=ENABLE_DIAGNOSTIC_EVENTS=false
bash tool/with_release_env.sh flutter build appbundle --release --dart-define=ENABLE_ERROR_REPORTING=false --dart-define=ENABLE_DIAGNOSTIC_EVENTS=false
```

Expected outputs:
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

## 5. iOS signed export prerequisites and steps

Current CI verifies only `flutter build ios --release --no-codesign`.
Signed distribution still requires Apple account assets outside this repository.

Required before signed export:
- Apple Developer account access with correct role
- Distribution certificate in Keychain
- Provisioning profile matching bundle id
- App Store Connect access for upload

Typical signed export command:

```bash
flutter pub get
flutter build ipa --release
```

If your team uses manual export options, use your project-approved `ExportOptions.plist`.

## 6. Store upload sequence

1. Upload Android `.aab` to Google Play internal testing.
2. Complete Google Play release forms (Data safety, content rating, policy declarations).
3. Upload iOS build to App Store Connect and complete required metadata/compliance fields.
4. Run manual smoke checks using [MANUAL_SMOKE_CHECKLIST.md](MANUAL_SMOKE_CHECKLIST.md).
5. Record final release decision and owners in [RELEASE_OWNERSHIP_DECISIONS_TEMPLATE.md](RELEASE_OWNERSHIP_DECISIONS_TEMPLATE.md).

## 7. Final go/no-go checklist

- [ ] CI green on release commit (`main` or `dev`)
- [ ] Android signed artifacts generated and verified installable
- [ ] iOS signed archive/export completed by authorized account owner
- [ ] Manual smoke checklist completed
- [ ] Store metadata/compliance items completed
- [ ] Rollback plan and release notes prepared

## 8. What is proven vs not proven by repo automation

Proven by repo automation:
- formatting/analyze/tests/coverage gate
- Android signed release build viability in CI (when secrets are configured)
- iOS release compile without codesign
- CodeQL for Java/Kotlin only
- Release defaults keep production telemetry disabled unless secure relay is explicitly configured

Not proven by repo automation:
- Swift/native iOS CodeQL scanning
- iOS production signing/export correctness
- Store account ownership/legal publisher decisions
