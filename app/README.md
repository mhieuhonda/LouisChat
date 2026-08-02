# LouisChat — Flutter app

The Android client for LouisChat. Messenger-style UI, realtime chat via Socket.io, JWT auth, and avatar uploads.

## Requirements

- Flutter ≥ 3.19
- Dart ≥ 3.3
- Android SDK (for building APK)

## Install

```bash
cd app
flutter pub get
```

## Configure

Open `lib/utils/config.dart` and set the server URLs:

```dart
static const String apiUrl    = 'http://10.0.2.2:3000';   // emulator
static const String socketUrl = 'http://10.0.2.2:3000';
```

For a real device, use the LAN / public IP of your backend host.

## Run (debug)

```bash
flutter run
```

## Build release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Project structure

```
lib/
├── main.dart
├── models/
│   ├── user.dart
│   └── message.dart
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── main_screen.dart
│   ├── chats_tab.dart
│   ├── people_tab.dart
│   ├── chat_detail_screen.dart
│   └── profile_screen.dart
├── services/
│   ├── api_service.dart
│   ├── socket_service.dart
│   └── app_store.dart
├── utils/
│   ├── config.dart
│   └── theme.dart
└── widgets/
    └── avatar.dart
```

## CI

APK builds are produced automatically by `.github/workflows/build-apk.yml` on every GitHub Release. See the top-level [README](../README.md) for signing setup.
