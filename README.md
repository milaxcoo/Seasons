# 🌿 Seasons

A privacy-focused mobile app for voting at RUDN / PFUR University.

![Flutter](https://img.shields.io/badge/Flutter-3.4+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart)

## ✨ Features

- **Secure Login** — RUDN university credentials via WebView
- **Voting Events** — Three tabs: Registration, Active, Results
- **Real-time Updates** — WebSocket connection for live notifications
- **Push Notifications** — Get notified about new votings
- **Bilingual** — Russian and English interface
- **Privacy-First** — No third-party analytics, no data collection

## 📱 Screenshots

*Coming soon*

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.4+ |
| State Management | BLoC |
| Storage | flutter_secure_storage |
| Notifications | Local notifications + WebSocket |
| Backend | RUDN University (seasons.rudn.ru) |

## 🔒 Privacy

- ❌ No Firebase
- ❌ No Google Analytics
- ❌ No Crashlytics
- ❌ No third-party SDKs that collect data
- ✅ All data stays on RUDN servers
- ✅ Optional Telegram crash reporting (disabled by default)
- ✅ Diagnostic auth telemetry is opt-in and disabled by default

### Security note (release/profile builds)

- Never pass `TELEGRAM_BOT_TOKEN` or `TELEGRAM_CHAT_ID` to release/profile builds.
- Direct Telegram sending is disabled in release/profile builds.
- Production monitoring will be routed through an on-prem relay in a follow-up rollout.

## 🚀 Getting Started

### Prerequisites
- Flutter 3.4+
- Xcode (for iOS)
- Android Studio (for Android)

### Installation

```bash
# Clone
git clone https://github.com/milaxcoo/Seasons.git
cd Seasons

# Install dependencies
flutter pub get

# Run
flutter run
```

## 🧪 Testing

```bash
flutter test                  # Run all tests
flutter test --coverage       # Run with coverage report
```

> **Note**: `flutter test` requires a compatible `flutter_tester` binary for your platform.

## ⚙️ CI Quality Gates

Every push/PR to `main`, `devs`, or `dev` triggers the [Flutter CI](.github/workflows/flutter_ci.yml) pipeline:

1. 🎨 **Format** — `dart format --set-exit-if-changed`
2. 🔍 **Analyze** — `flutter analyze --fatal-infos --fatal-warnings`
3. 🧪 **Test** — `flutter test --coverage`
4. ✅ **Coverage** — ≥ 50% filtered (generated code excluded; raw + filtered reports uploaded)

CodeQL security scanning ([workflow](.github/workflows/codeql.yml)) also runs for Java/Kotlin and Swift code.

## 📁 Project Structure

```
lib/
├── core/               # Theme, services, utilities
│   └── services/       # Background service, error reporting
├── data/               # Repositories, data sources
├── domain/             # Models
├── l10n/               # Localization (RU/EN)
└── presentation/       # UI
    ├── bloc/           # State management
    ├── screens/        # App screens
    └── widgets/        # Reusable components
```
