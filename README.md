<p align="center">
  <img src="https://img.shields.io/badge/LouisChat-v0.3.0-0084FF?style=for-the-badge&logo=chat&logoColor=white" alt="LouisChat v0.3.0" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" />
  <img src="https://img.shields.io/badge/Server-Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white" />
</p>

<h1 align="center">💬 LouisChat</h1>

<p align="center">
  <strong>Messenger-style realtime chat app — zero config, just open and chat.</strong>
</p>

---

## ✨ What is LouisChat?

LouisChat is a full-stack realtime messaging application inspired by Facebook Messenger. It features a Flutter Android client with a polished Messenger-style UI and a Node.js backend powered by PostgreSQL, MySQL, and Redis. **No configuration needed** — the app connects to the server automatically.

## 🏗 Architecture

```
┌─────────────────┐     WebSocket      ┌──────────────────┐
│  Flutter App     │◄──────────────────►│  Socket.io       │
│  (Android)       │     REST API       │  (Realtime)      │
│                  │───────────────────►│  Express 4       │
└─────────────────┘                     └────────┬─────────┘
                                                 │
                              ┌──────────────────┼──────────────────┐
                              │                  │                  │
                     ┌────────▼───────┐ ┌────────▼───────┐ ┌───────▼──────┐
                     │  PostgreSQL    │ │  MySQL         │ │  Redis       │
                     │  (Primary DB)  │ │  (Event Logs)  │ │  (Cache/Pub) │
                     └────────────────┘ └────────────────┘ └──────────────┘
```

## 🚀 Quick Start

### Server

```bash
cd server
npm install
npm start
```

That's it. The `.env` file is already configured with all database credentials. The server auto-creates all required tables on first boot.

### App

```bash
cd app
flutter pub get
flutter run
```

Or build a release APK:

```bash
flutter build apk --release
```

## 📱 Features

| Feature | Description |
|---------|-------------|
| 🔐 Auth | Register / Login with JWT + bcrypt |
| 💬 Realtime Chat | Socket.io + Redis pub/sub for instant message delivery |
| 👤 Presence | Online/Offline status with live updates |
| ⌨️ Typing Indicator | See when the other person is typing |
| ✅ Read Receipts | Double-check marks (✓✓) with blue color when read |
| 🖼 Avatar Upload | Upload profile pictures from gallery |
| 🔍 User Search | Find friends by username or display name |
| 📅 Date Separators | "Hôm nay", "Hôm qua", etc. in chat |
| 🔄 Auto Reconnect | Socket reconnects automatically when connection drops |
| 🇻🇳 Vietnamese UI | Full Vietnamese interface |
| 🔒 Rate Limiting | Brute-force protection on auth endpoints |
| 🏥 Health Checks | `/api/health` and `/api/health/deep` endpoints |

## 📂 Project Structure

```
LouisChat/
├── app/                          # Flutter Android client
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   └── message.dart
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── main_screen.dart
│   │   │   ├── chats_tab.dart
│   │   │   ├── people_tab.dart
│   │   │   ├── chat_detail_screen.dart
│   │   │   └── profile_screen.dart
│   │   ├── services/
│   │   │   ├── api_service.dart     # HTTP client with 12s timeout
│   │   │   ├── socket_service.dart  # Socket.io auto-reconnect
│   │   │   └── app_store.dart       # Provider state management
│   │   ├── utils/
│   │   │   ├── config.dart          # Hardcoded server URL
│   │   │   └── theme.dart           # Messenger-style theme
│   │   └── widgets/
│   │       ├── avatar.dart
│   │       └── loading.dart
│   └── pubspec.yaml
├── server/                        # Node.js backend
│   ├── src/
│   │   ├── index.js                # Express + Socket.io entry
│   │   ├── db.js                   # PostgreSQL pool + schema
│   │   ├── mysql.js                # MySQL pool + event log
│   │   ├── redis.js                # Redis pub/sub + presence
│   │   ├── socket.js               # Socket.io realtime layer
│   │   ├── middleware/
│   │   │   ├── auth.js             # JWT verification
│   │   │   ├── rateLimit.js        # Rate limiting
│   │   │   └── error.js            # Centralized error handler
│   │   └── routes/
│   │       ├── auth.js             # Register, login, profile, avatar
│   │       ├── users.js            # Search, profile view
│   │       ├── messages.js         # Conversations, messages, read
│   │       └── health.js           # Health checks
│   ├── .env                        # Pre-configured credentials
│   ├── .env.example
│   └── package.json
├── .github/
│   └── workflows/
│       └── build-apk.yml           # Auto-build APK on release
├── CHANGELOG.md
└── README.md
```

## 🛠 Tech Stack

### Client
| Tech | Purpose |
|------|---------|
| Flutter | Cross-platform UI framework |
| Provider | State management |
| Socket.io Client | Realtime WebSocket connection |
| HTTP | REST API calls |
| Shared Preferences | Local token persistence |
| Image Picker | Avatar selection |

### Server
| Tech | Purpose |
|------|---------|
| Express 4 | HTTP API framework |
| Socket.io 4 | WebSocket realtime |
| PostgreSQL | Primary data store (users, conversations, messages) |
| MySQL | Auxiliary event logging |
| Redis | Session cache, presence, pub/sub |
| JWT + bcrypt | Authentication |
| Multer | File upload handling |
| Helmet | Security headers |
| Morgan | Request logging |

## 📡 API Surface

### Auth
| Method | Path | Body | Returns |
|--------|------|------|---------|
| POST | `/api/auth/register` | `{username, email, password, displayName}` | `{token, user}` |
| POST | `/api/auth/login` | `{identifier, password}` | `{token, user}` |
| GET | `/api/auth/me` | — (Bearer) | `{user}` |
| PUT | `/api/auth/avatar` | multipart `avatar` | `{user}` |
| PUT | `/api/auth/profile` | `{displayName, bio}` | `{user}` |

### Users
| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/users/search?q=...` | Search by username |
| GET | `/api/users/:id` | Public profile |

### Messages
| Method | Path | Body / Query | Returns |
|--------|------|-------------|---------|
| GET | `/api/messages/conversations` | — | `{conversations}` |
| POST | `/api/messages/conversations/direct` | `{peerId}` | `{conversationId}` |
| GET | `/api/messages/:conversationId` | `?before=&limit=` | `{messages}` |
| POST | `/api/messages/:conversationId` | `{content}` | `{message}` |
| POST | `/api/messages/:conversationId/read` | — | `{ok}` |

### Socket.io Events
| Direction | Event | Payload |
|-----------|-------|---------|
| client → | `conversation:join` | `conversationId` |
| client → | `typing` | `{conversationId, isTyping}` |
| client → | `message:read` | `{conversationId}` |
| server → | `message:new` | `{conversation_id, message}` |
| server → | `typing` | `{conversation_id, user_id, username, isTyping}` |
| server → | `message:read` | `{conversation_id, reader_id}` |
| server → | `presence` | `{userId, online}` |

## 📋 Version History

| Version | Date | Highlights |
|---------|------|-----------|
| **0.3.0** | 2026-08-02 | Zero-config: removed server settings screen, hardcoded server URL, pre-configured `.env` |
| 0.2.0 | 2026-08-02 | HTTP timeouts, server URL config, Vietnamese errors, loading skeletons |
| 0.1.0 | 2026-08-02 | Initial release: Messenger-style UI, realtime chat, JWT auth |

## 📄 License

MIT
