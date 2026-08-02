# LouisChat

<p align="center">
  <img alt="LouisChat" src="https://img.shields.io/badge/LouisChat-v0.2.0-0084FF?style=for-the-badge&logo=flutter&logoColor=white" />
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" />
  <img alt="License" src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" />
</p>

> A Messenger-style realtime chat app for Android, built with Flutter + Node.js + PostgreSQL + Redis.

LouisChat is a lightweight, end-to-end chat application that replicates the look & feel of Facebook Messenger while running entirely on your own infrastructure. This repository contains **both** the Flutter mobile client (`app/`) and the Node.js backend (`server/`).

---

## ✨ Features

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
- **Runtime server config** — change API/WebSocket URL inside the app, no recompile needed
- **Vietnamese error messages** — every known failure mode has a friendly translation
- **Hardened backend** — helmet, rate-limit, graceful shutdown, deep health check

---

## 🆕 What's new in v0.2

| Area | Change |
|------|--------|
| 🐛 Critical bugfix | Register/login no longer spin forever when server is unreachable — every request now has a 12-second timeout |
| ⚙️ New screen | **Settings → Server** lets you configure API & WebSocket URL inside the app, with a one-tap connection test |
| 🇻🇳 Localization | All error messages translated to Vietnamese (`ApiException.viMessage`) |
| 🛡 Backend | `helmet`, `express-rate-limit`, `compression`, `morgan`, graceful shutdown, `/api/health/deep` |
| 🎨 UI polish | Date separators in chat, loading skeletons, pull-to-retry, socket reconnect indicator |
| 🔧 Android | `network_security_config.xml` for cleartext HTTP in dev |

See [`CHANGELOG.md`](./CHANGELOG.md) for the full history.

---

## 🏗 Architecture

```
┌────────────────────────────┐
│   Flutter app (Android)    │
│  ─────────────────────────  │
│  • UI (Messenger-style)    │
│  • REST (http, 12s timeout)│
│  • WebSocket (socket_io)   │
│  • Runtime server URL      │
└─────────────┬──────────────┘
              │ HTTPS / WSS
              ▼
┌─────────────────────────────────────────────┐
│           Node.js Backend (Express)         │
│  ─────────────────────────────────────────   │
│  • helmet + rate-limit + compression        │
│  • /api/health      liveness                │
│  • /api/health/deep readiness (PG+MySQL+Redis)│
│  • /api/auth        register, login, me,    │
│                     avatar, profile         │
│  • /api/users       search, profile         │
│  • /api/messages    conversations, send,    │
│                     read                    │
│  • Socket.io        message:new, typing,    │
│                     message:read, presence  │
│  • Graceful shutdown (SIGINT/SIGTERM)       │
└──────┬────────────┬──────────────┬──────────┘
       │            │              │
       ▼            ▼              ▼
┌────────────┐ ┌─────────┐ ┌──────────────┐
│ PostgreSQL │ │  Redis  │ │     MySQL    │
│ users,     │ │ pub/sub │ │ app_events   │
│ messages,  │ │ + online│ │ (audit log)  │
│ convs      │ │ presence│ │              │
│ +pgcrypto  │ │         │ │              │
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
│   │   ├── screens/           # splash, login, register, main, chats,
│   │   │                      #   people, chat detail, profile,
│   │   │                      #   server settings
│   │   ├── services/          # api_service, socket_service, app_store
│   │   ├── utils/             # config, theme
│   │   └── widgets/           # avatar, loading (skeleton/error/empty)
│   ├── android/
│   │   └── app/src/main/res/xml/network_security_config.xml
│   ├── pubspec.yaml
│   └── README.md
├── server/                    # Node.js backend
│   ├── src/
│   │   ├── index.js           # helmet, compression, morgan, rate-limit,
│   │   │                      #   graceful shutdown
│   │   ├── db.js              # PostgreSQL pool + pgcrypto + schema
│   │   ├── redis.js           # Redis client + pub/sub helpers
│   │   ├── mysql.js           # auxiliary MySQL connection
│   │   ├── socket.js          # Socket.io realtime layer
│   │   ├── middleware/
│   │   │   ├── auth.js
│   │   │   ├── error.js       # centralized error handler
│   │   │   └── rateLimit.js
│   │   └── routes/
│   │       ├── auth.js
│   │       ├── users.js
│   │       ├── messages.js
│   │       └── health.js      # /api/health + /api/health/deep
│   ├── .env.example
│   ├── package.json
│   └── README.md
├── .github/workflows/
│   └── build-apk.yml          # Auto-build & sign APK on release
├── CHANGELOG.md
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

The server will auto-create the PostgreSQL schema (including `pgcrypto`) on first boot.

Verify it's healthy:

```bash
curl http://localhost:3000/api/health
curl http://localhost:3000/api/health/deep
```

### 2. Run the Flutter app

```bash
cd app
flutter pub get
flutter run                # debug
# or:
flutter build apk --release
```

### 3. Point the app at your server

The app's default server URL is `http://163.44.96.79:3000`. **You can change
this at runtime** without recompiling:

- On first launch, if the server is unreachable, the app opens **Settings →
  Server** automatically.
- Or open **Profile → Cài đặt máy chủ**.
- Enter your server URL (e.g. `http://192.168.1.10:3000`), tap
  **"Kiểm tra kết nối"** to verify, then **"Lưu & Tiếp tục"**.

> For Android emulator use `http://10.0.2.2:3000`.
> For a real device use a reachable LAN/public IP.

---

## 📦 Releases & auto-built APK

Every GitHub **Release** automatically triggers [`build-apk.yml`](.github/workflows/build-apk.yml) which:

1. Checks out the repo
2. Sets up Flutter (stable channel)
3. Builds a release APK
4. **Signs** the APK with a keystore (see "Signing" below)
5. Uploads the signed APK + SHA256 to the release assets

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
- **Rate limiting** on auth (30 / 15 min per IP) and general API (120 / min per IP).
- **helmet** adds security headers.
- The bundled `.env.example` contains the demo DB credentials you provided. **Rotate them before going to production** and never commit a real `.env`.
- For v1.0 CH Play release: switch the backend to **HTTPS**, then remove the cleartext block in `network_security_config.xml`.

---

## 🗺 Roadmap

| Version | Planned                                              |
|---------|------------------------------------------------------|
| v0.3    | Image / video attachments in chat                    |
| v0.4    | Group chats (schema is already group-ready)          |
| v0.5    | Voice notes & push notifications (FCM)               |
| v0.6    | Voice / video calls (WebRTC)                         |
| v1.0    | End-to-end encryption (Signal protocol) + CH Play    |

---

## 📄 License

MIT © 2026 LouisChat contributors
