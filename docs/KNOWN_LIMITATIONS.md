# Known Limitations and Accepted Risks

Last reviewed: 2026-02-26

This file lists current limitations accepted for release planning transparency.

## CI and security coverage limits

- CodeQL is configured for `java-kotlin` only.
- Swift/native iOS code is not currently scanned by CodeQL in this repository.
- iOS CI build is `flutter build ios --release --no-codesign` (compile check only).

## Release process limits

- iOS production distribution signing is not proven by CI and depends on Apple account assets.
- Store-console policy/compliance tasks are manual and cannot be fully validated from this repo.

## Runtime validation limits

- Some behavior depends on real backend availability and real network conditions.
- VPN or campus-network conditions can affect authentication flow and must be tested manually.
- Notification behavior (especially cold-start routing) requires device-level validation.
- Production telemetry relay is disabled by default until secure endpoint configuration is validated.

## Quality gate limits

- Current coverage gate is global filtered coverage >= 50%; it does not guarantee high coverage for newly changed files.
