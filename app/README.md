# LouisChat — Flutter App

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

## Run (debug)

```bash
flutter run
```

## Build release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Zero Config

The server URL is hardcoded — **no configuration needed**. Just open the app and start chatting.

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
│   ├── api_service.dart        # 12s timeout, viMessage translator
│   ├── socket_service.dart     # auto-reconnect, multi-event handlers
│   └── app_store.dart          # provider state
├── utils/
│   ├── config.dart             # hardcoded server URL
│   └── theme.dart
└── widgets/
    ├── avatar.dart
    └── loading.dart            # ChatListSkeleton, ErrorView, EmptyView
```

## Android config

- `network_security_config.xml` allows cleartext HTTP for development.
- For CH Play v1.0: switch server to HTTPS, then remove the `<base-config cleartextTrafficPermitted="true" />` line.

## CI

APK builds are produced automatically by `.github/workflows/build-apk.yml` on every GitHub Release. See the top-level [README](../README.md) for signing setup.
