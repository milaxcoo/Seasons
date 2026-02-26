# Manual Smoke Checklist

Last reviewed: 2026-02-26

Use this checklist for RC validation on real devices before store submission.

## Test matrix

- At least one physical Android device
- At least one physical iOS device
- One stable network and one degraded network scenario (loss/reconnect)

## Authentication and session

- [ ] Fresh install -> login succeeds with valid RUDN account
- [ ] App restart restores valid session without forced relogin
- [ ] Logout clears session and returns to login screen
- [ ] Expired/invalid session path (`auth_invalid`) forces safe relogin flow

## Voting flows

- [ ] Registration tab loads and allows registration action when available
- [ ] Active tab loads current voting items
- [ ] Vote submit path succeeds and UI state updates
- [ ] Results tab renders completed votes correctly

## Network and reconnect behavior

- [ ] Offline startup is handled without crash
- [ ] Reconnect overlay/status appears during connection loss
- [ ] After reconnect, data refreshes and overlay clears
- [ ] Flaky network does not cause duplicate critical actions

## Notifications

- [ ] Foreground notification handling does not break current screen
- [ ] Tap from background routes to expected destination
- [ ] Cold start from notification routes correctly on first launch

## Release artifact sanity

- [ ] Android release APK installs and launches on target Android device
- [ ] iOS signed build installed via approved distribution path and launches
- [ ] App version/build number shown in store metadata matches release plan

## Cross-device sanity

- [ ] Core flow validated on at least two device profiles/sizes
- [ ] UI remains usable in both supported languages (RU/EN)

## Sign-off

- Release candidate version:
- Date:
- Tester:
- Result: PASS / BLOCKED
- Notes:
