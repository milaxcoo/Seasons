# Firebase Setup Guide

This document explains how to set up Firebase for the Seasons app.

## Important Security Note

**Never commit Firebase configuration files to version control!** These files contain sensitive API keys and should remain private.

The following files are already included in `.gitignore`:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## Setup Instructions

### 1. Install Firebase CLI

```bash
npm install -g firebase-tools
```

### 2. Login to Firebase

```bash
firebase login
```

### 3. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 4. Configure Firebase for Your Project

Run the following command in the project root:

```bash
flutterfire configure --project=pfur-seasons
```

This will:
- Create `lib/firebase_options.dart`
- Create `android/app/google-services.json`
- Create `ios/Runner/GoogleService-Info.plist`

### 5. Verify Configuration

After running the configuration, ensure all three files exist:

```bash
ls -l lib/firebase_options.dart
ls -l android/app/google-services.json
ls -l ios/Runner/GoogleService-Info.plist
```

### 6. Team Setup

When other developers clone this repository, they must:

1. Follow steps 1-4 above
2. Never commit the generated Firebase files
3. Keep their Firebase configuration files private

## CI/CD Setup

The GitHub Actions workflow creates mock Firebase configuration files for testing purposes. These mock files:
- Allow tests to run without real Firebase credentials
- Prevent exposure of sensitive information
- Enable CI/CD to work without secret management

## Troubleshooting

### "Firebase not configured" Error

If you see this error, run:

```bash
flutterfire configure --project=pfur-seasons
```

### Files Missing After Git Pull

Firebase configuration files are not tracked in git. Run the configuration command again after pulling changes.

### Different Firebase Project

If you need to use a different Firebase project, replace `pfur-seasons` with your project ID:

```bash
flutterfire configure --project=your-project-id
```
