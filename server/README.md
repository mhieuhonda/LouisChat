# LouisChat — Backend Server

Node.js + Express + Socket.io backend that powers the LouisChat Flutter app.

## Stack

| Concern        | Tech                          |
|----------------|-------------------------------|
| HTTP API       | Express 4                     |
| Realtime       | Socket.io 4 + Redis pub/sub   |
| Primary DB     | PostgreSQL (users, messages)  |
| Auxiliary DB   | MySQL (event logs)            |
| Cache / bus    | Redis (sessions, presence)    |
| Auth           | JWT (Bearer) + bcrypt         |
| File uploads   | Multer (disk storage)         |

## Getting started

```bash
cd server
cp .env.example .env     # edit values if needed
npm install
npm run dev              # or: npm start
```

Server listens on `http://localhost:3000`.

## API surface

### Auth
| Method | Path                            | Body                                | Returns                  |
|--------|---------------------------------|-------------------------------------|--------------------------|
| POST   | `/api/auth/register`            | `{username, email, password, displayName}` | `{token, user}`   |
| POST   | `/api/auth/login`               | `{identifier, password}`            | `{token, user}`          |
| GET    | `/api/auth/me`                  | — (Bearer)                          | `{user}`                 |
| PUT    | `/api/auth/avatar`              | multipart `avatar`                  | `{user}`                 |
| PUT    | `/api/auth/profile`             | `{displayName, bio}`                | `{user}`                 |

### Users
| Method | Path                       | Notes                |
|--------|----------------------------|----------------------|
| GET    | `/api/users/search?q=...`  | Search by username   |
| GET    | `/api/users/:id`           | Public profile       |

### Messages
| Method | Path                                       | Body / Query                 | Returns                  |
|--------|--------------------------------------------|------------------------------|--------------------------|
| GET    | `/api/messages/conversations`              | —                            | `{conversations}`        |
| POST   | `/api/messages/conversations/direct`       | `{peerId}`                   | `{conversationId}`       |
| GET    | `/api/messages/:conversationId`            | `?before=&limit=`            | `{messages}`             |
| POST   | `/api/messages/:conversationId`            | `{content}`                  | `{message}`              |
| POST   | `/api/messages/:conversationId/read`       | —                            | `{ok}`                   |

### Socket.io events

| Direction | Event                | Payload                                              |
|-----------|----------------------|------------------------------------------------------|
| client→   | `conversation:join`  | `conversationId`                                     |
| client→   | `typing`             | `{conversationId, isTyping}`                         |
| client→   | `message:read`       | `{conversationId}`                                   |
| server→   | `message:new`        | `{conversation_id, message}`                         |
| server→   | `typing`             | `{conversation_id, user_id, username, isTyping}`     |
| server→   | `message:read`       | `{conversation_id, reader_id}`                       |
| server→   | `presence`           | `{userId, online}`                                   |

## Schema (auto-created on boot)

- `users` — profile + auth credentials
- `conversations` + `conversation_members` — direct (and future group) chats
- `messages` — chat messages with status & read_at

## Notes

- v0.1 ships **1-on-1** chats only; the schema already supports groups.
- Avatars are stored on disk under `uploads/` and served at `/uploads/<file>`.
- The `app_events` table in MySQL is used for lightweight server-side logging.
