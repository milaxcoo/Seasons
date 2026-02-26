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

## 5. Handoff checklist

- [ ] Android keystore custody owner documented
- [ ] Android passphrase custody owner documented
- [ ] CI secrets owner documented
- [ ] Apple certificate/profile owner documented
- [ ] App Store Connect account owner documented
- [ ] Recovery/backup location documented

Use [RELEASE_OWNERSHIP_DECISIONS_TEMPLATE.md](RELEASE_OWNERSHIP_DECISIONS_TEMPLATE.md) to record ownership decisions.
