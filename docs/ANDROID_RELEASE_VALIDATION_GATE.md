# Android Release Validation Gate

Last reviewed: 2026-03-07

Run this gate on a physical Android device using the signed release artifact.

## Preconditions

- Build with:
  - `bash tool/with_release_env.sh flutter build appbundle --release --dart-define=ENABLE_ERROR_REPORTING=false --dart-define=ENABLE_DIAGNOSTIC_EVENTS=false`
- Install the matching release APK/AAB-derived build on a real Android device.
- Prepare one stable network and one degraded network scenario.

## Test steps

| Action | Expected result | Likely root cause if it fails |
| --- | --- | --- |
| Install and launch the release build | App launches without crash and shows login screen or restored session | Release-only manifest/proguard/plugin issue |
| Start fresh login from login screen | RUDN login page opens and renders correctly | WebView cache/session cleanup regression, UA mismatch, backend mobile-site mismatch |
| Complete login with valid account | App returns to authenticated home screen | Cookie extraction failure, WebView callback handling bug, secure-storage write issue |
| Force-close app, relaunch | Existing valid session restores without forced relogin | Session validation parser drift, secure-storage read issue |
| Tap logout from authenticated UI | App returns to login and next launch stays logged out | Local session not cleared, WebView session cleanup failed |
| Login again after logout with same account | Login succeeds without stale page reuse or phantom session state | WebView cache/local storage not cleared |
| Login, then background app for at least 1 minute and resume | No crash; session remains usable; content refreshes normally | Background-service lifecycle issue, resume refresh bug |
| While logged in, disable network for 30-60 seconds, then restore it | Reconnect/degraded state appears, then clears after recovery; user is not logged out solely due to reconnect | Background auth handling bug, secure-storage transient failure misclassified as auth loss |
| Deny notification permission when prompted | App remains usable; no crash or blocked flow | Notification permission handling bug |
| Reinstall or reset permission and allow notifications | App remains usable and notification flow can proceed | Notification setup bug |
| Trigger a local notification-producing event path | Notification appears once per event burst and is not silently overwritten | Notification ID collision or action filtering bug |
| Tap notification while app is backgrounded | App opens the expected tab | Notification payload parsing or navigation replay bug |
| Tap notification from cold start | App launches and routes to the expected tab | Launch payload handling or pending-navigation replay bug |
| Repeat login flow after temporary network degradation | Login still succeeds with current UA policy | UA policy regression or backend device detection mismatch |

## Sign-off

- Release candidate:
- Device model / Android version:
- Tester:
- Result: PASS / BLOCKED
- Notes:
