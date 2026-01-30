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
- ✅ Custom error reporting (optional Telegram)

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

### Building for Release

```bash
# Create .secrets file with your Telegram credentials (optional)
echo "TELEGRAM_BOT_TOKEN=your_token" > .secrets
echo "TELEGRAM_CHAT_ID=your_chat_id" >> .secrets

# Build with secrets
./build.sh apk        # Android APK
./build.sh appbundle  # Android AAB
./build.sh ios        # iOS
```

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


