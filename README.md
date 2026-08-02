# LouisChat

<p align="center">
  <img alt="LouisChat" src="https://img.shields.io/badge/LouisChat-v0.1.0-0084FF?style=for-the-badge&logo=flutter&logoColor=white" />
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" />
  <img alt="License" src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" />
</p>

> A Messenger-style realtime chat app for Android, built with Flutter + Node.js + PostgreSQL + Redis.

LouisChat is a lightweight, end-to-end chat application that replicates the look & feel of Facebook Messenger while running entirely on your own infrastructure. This repository contains **both** the Flutter mobile client (`app/`) and the Node.js backend (`server/`).

---

## ✨ Features (v0.1)

- **100% Messenger-style UI** — chat list, search, conversation detail, profile screen
- **Custom in-app authentication** — register & login with username/email + password
- **Avatar upload** — pick from gallery, store on server, served back to all clients
- **Realtime messaging** — Socket.io + Redis pub/sub, instant delivery across devices
- **Live presence** — online dot in chat list & chat header
- **Typing indicator** — animated three-dot bubble
- **Read receipts** — blue double-tick on read messages
- **Search users** — find anyone by username / display name
- **Persistent sessions** — JWT stored on device, auto-resume on launch
- **Cross-worker realtime** — Redis pub/sub fans messages out across multiple Node.js processes

---

## 🏗 Architecture

```
┌────────────────────────────┐
│   Flutter app (Android)    │
│  ─────────────────────────  │
│  • UI (Messenger-style)    │
│  • REST (http)             │
│  • WebSocket (socket_io)   │
└─────────────┬──────────────┘
              │ HTTPS / WSS
              ▼
┌─────────────────────────────────────────────┐
│           Node.js Backend (Express)         │
│  ─────────────────────────────────────────   │
│  • /api/auth      register, login, me,      │
│                    avatar, profile           │
│  • /api/users     search, profile           │
│  • /api/messages  conversations, send, read │
│  • Socket.io      message:new, typing,      │
│                    message:read, presence   │
└──────┬────────────┬──────────────┬──────────┘
       │            │              │
       ▼            ▼              ▼
┌────────────┐ ┌─────────┐ ┌──────────────┐
│ PostgreSQL │ │  Redis  │ │     MySQL    │
│ users,     │ │ pub/sub │ │ app_events   │
│ messages,  │ │ + online│ │ (audit log)  │
│ convs      │ │ presence│ │              │
└────────────┘ └─────────┘ └──────────────┘
```

---

## 📁 Repository layout

```
LouisChat/
├── app/                       # Flutter mobile client (Android)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/            # AppUser, Message, Conversation
│   │   ├── screens/           # splash, login, register, main, chats, people, chat detail, profile
│   │   ├── services/          # api_service, socket_service, app_store
│   │   ├── utils/             # config, theme
│   │   └── widgets/           # avatar
│   ├── pubspec.yaml
│   └── README.md
├── server/                    # Node.js backend
│   ├── src/
│   │   ├── index.js
│   │   ├── db.js              # PostgreSQL pool + schema bootstrap
│   │   ├── redis.js           # Redis client + pub/sub helpers
│   │   ├── mysql.js           # auxiliary MySQL connection
│   │   ├── socket.js          # Socket.io realtime layer
│   │   ├── middleware/auth.js # JWT verify
│   │   └── routes/            # auth, users, messages
│   ├── .env.example
│   ├── package.json
│   └── README.md
├── .github/workflows/
│   └── build-apk.yml          # Auto-build & sign APK on release
└── README.md                  # you are here
```

---

## 🚀 Getting started

### 1. Start the backend

```bash
cd server
cp .env.example .env     # tweak DB credentials if needed
npm install
npm start                # listens on :3000
```

The server will auto-create the PostgreSQL schema on first boot.

### 2. Configure the Flutter app

Edit `app/lib/utils/config.dart` to point at your backend:

```dart
static const String apiUrl    = 'http://<your-server-ip>:3000';
static const String socketUrl = 'http://<your-server-ip>:3000';
```

> For Android emulator, use `http://10.0.2.2:3000`.
> For a real device, use a reachable LAN/public IP and ensure `INTERNET` permission is set (it is, by default).

### 3. Run the app

```bash
cd app
flutter pub get
flutter run                # debug
# or:
flutter build apk --release
```

---

## 📦 Releases & auto-built APK

Every GitHub **Release** automatically triggers [`build-apk.yml`](.github/workflows/build-apk.yml) which:

1. Checks out the repo
2. Sets up Flutter (stable channel)
3. Builds a release APK
4. **Signs** the APK with a keystore (see "Signing" below)
5. Uploads the signed APK to the release assets

### Signing setup (one-time)

The workflow will sign with your keystore if you provide these **GitHub repository secrets**:

| Secret              | Description                                            |
|---------------------|--------------------------------------------------------|
| `KEYSTORE_BASE64`   | base64-encoded `.jks` keystore                         |
| `KEY_ALIAS`         | alias of the signing key                               |
| `KEY_PASSWORD`      | password for the signing key                           |
| `STORE_PASSWORD`    | password for the keystore file                         |

Quick way to produce `KEYSTORE_BASE64`:

```bash
keytool -genkeypair -v -keystore louischat.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias louischat
base64 -w 0 louischat.jks   # paste output into the secret
```

> **If secrets are missing**, the workflow still produces a debug-signed APK so the build never fails.

---

## 🔒 Security notes

- Passwords are hashed with **bcrypt** (cost 10).
- Auth tokens are **JWT** (7-day expiry by default — see `JWT_EXPIRES_IN`).
- The bundled `.env.example` contains the demo DB credentials you provided. **Rotate them before going to production** and never commit a real `.env`.

---

## 🗺 Roadmap

| Version | Planned                                              |
|---------|------------------------------------------------------|
| v0.2    | Image / video attachments in chat                    |
| v0.3    | Group chats (schema is already group-ready)          |
| v0.4    | Voice notes & push notifications (FCM)               |
| v0.5    | Voice / video calls (WebRTC)                         |
| v1.0    | End-to-end encryption (Signal protocol)              |

---

## 📄 License

MIT © 2026 LouisChat contributors
