# iOS Release Readiness Gate

Last reviewed: 2026-03-07

This gate covers the release proof that cannot be completed from code-only CI.

## Signed distribution proof

| Action | Expected result | Likely root cause if it fails |
| --- | --- | --- |
| Archive the app with production signing assets in Xcode or approved automation | Archive succeeds with the shipping bundle id and version/build | Provisioning, certificate, team, entitlements, or archive config issue |
| Export the archive for device/App Store distribution | Export completes and produces installable output | Export options, signing profile, or capability mismatch |
| Install the signed build on physical iPhone and iPad hardware | App launches and basic auth/session flows work | Release-signing-only packaging issue or device capability mismatch |

## Store metadata / compliance proof

| Action | Expected result | Likely root cause if it fails |
| --- | --- | --- |
| Verify App Store Connect app privacy answers against actual app behavior | Privacy answers match cookie auth, local drafts, notifications, and optional relay telemetry defaults | Store metadata drift from implementation |
| Verify export compliance / encryption answers | Answers match current transport/security usage | Console configuration gap |
| Upload screenshots for required device classes | Required iPhone/iPad screenshot sets are accepted | Missing or invalid store assets |
| Verify privacy policy URL and review notes | Review metadata is complete and reachable | Release-owner console task incomplete |

## Sign-off

- Release candidate:
- Archive date:
- Signed by:
- Result: PASS / BLOCKED
- Notes:
