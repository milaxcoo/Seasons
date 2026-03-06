# Signing and Distribution Setup

Last reviewed: 2026-02-26

This document explains current signing/distribution setup and handoff expectations.
Do not store raw secrets in this repository.

## 1. Current repository reality

- Android release signing is enforced by Gradle for release tasks.
- CI expects Android signing secrets and decodes the keystore at runtime.
- iOS CI currently builds with `--no-codesign` only.
- iOS distribution signing/export still depends on Apple account assets outside the repo.

## 2. Android signing inputs

Required environment variables for local release builds:
- `KEYSTORE_PATH`
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`

Preferred local workflow:
- Keep signing values in macOS Keychain (account: current `$USER`).
- Inject them only for the build command via `bash tool/with_release_env.sh ...`.
- Keep `.env`, `.secrets`, and `.local_signing/android-signing.env` redacted placeholders only.

Expected keychain service names used by `tool/with_release_env.sh`:
- `votepfurapp_keystore_path`
- `votepfurapp_keystore_password`
- `votepfurapp_key_alias`
- `votepfurapp_key_password`

Optional telemetry keychain services:
- `votepfurapp_error_report_relay_url`
- `votepfurapp_error_report_relay_api_key`

CI secret mapping:
- `ANDROID_KEYSTORE_BASE64` -> decoded to `KEYSTORE_PATH` in workflow
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`

## 3. iOS distribution requirements

Required (managed outside git):
- Apple Developer account with proper role permissions
- Distribution certificate/private key in keychain
- Provisioning profile for `com.lebedev.seasons`
- App Store Connect access for upload/release actions

## 4. Secure storage and backup expectations

- Store credentials in an approved password manager or secure vault.
- Keep at least one controlled backup of Android keystore and passphrases.
- Track who has access to each signing asset.
- Rotate/revoke access when maintainers change.

## 5. Production telemetry relay expectations

- Direct Telegram transport is debug-only and must not be used in release/profile.
- Keep `ENABLE_ERROR_REPORTING=false` in production until secure relay is validated.
- If enabling production telemetry, provide:
  - `ERROR_REPORT_RELAY_URL`
  - optional `ERROR_REPORT_RELAY_API_KEY`
- Update store privacy disclosures when telemetry transport behavior changes.

## 6. Handoff checklist

- [ ] Android keystore custody owner documented
- [ ] Android passphrase custody owner documented
- [ ] CI secrets owner documented
- [ ] Apple certificate/profile owner documented
- [ ] App Store Connect account owner documented
- [ ] Recovery/backup location documented

Use [RELEASE_OWNERSHIP_DECISIONS_TEMPLATE.md](RELEASE_OWNERSHIP_DECISIONS_TEMPLATE.md) to record ownership decisions.
