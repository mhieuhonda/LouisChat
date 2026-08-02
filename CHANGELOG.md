# Changelog

All notable changes to **LouisChat** are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] — 2026-08-02

### Highlights

**Zero-config experience.** Users no longer need to configure anything — just open
the app and start chatting. The server settings screen has been completely removed
and the server URL is hardcoded. The backend ships with a ready-to-use `.env` file
so deployment is a single `npm install && npm start` command.

### Removed — App
- **`ServerSettingsScreen`** — deleted entirely. No user should ever have to
  configure a server address in a messaging app.
- **Runtime server URL configuration** — `AppStore.setServerUrls()`,
  `AppStore.resetServerUrls()`, `AppStore.checkServer()`,
  `AppStore.serverReachable`, `AppStore.serverVersion` all removed.
- **`ApiService.setServerUrls()` / `resetServerUrls()`** — removed. The URL is
  now a constant in `AppConfig`.
- **Server status pill** on the login screen — removed (no longer relevant).
- **"Cài đặt máy chủ" tile** in the profile screen — removed.
- **"Cài đặt" SnackBar action** on login failure — removed.
- **SharedPreferences keys** for server URL (`server_api_url`, `server_socket_url`)
  — removed from `AppConfig`.

### Changed — App
- `AppConfig` now exposes `apiUrl` and `socketUrl` as static constants instead of
  `defaultApiUrl` / `defaultSocketUrl` + SharedPreferences overrides.
- `ApiService` no longer reads or writes server URLs from SharedPreferences.
- `AppStore.bootstrap()` no longer calls `checkServer()` — the app just connects
  directly. If the server is down, the user sees a normal error message.
- `SplashScreen` no longer redirects to `ServerSettingsScreen` when the server
  is unreachable. It goes straight to login or main screen.
- `LoginScreen` simplified — no server status indicator, no settings button.
- `ProfileScreen` simplified — no "Cài đặt máy chủ" tile, version text updated
  to `v0.3.0`.
- `SocketService` no longer imports `AppConfig` — the URL is passed in from
  `AppStore` which gets it from `ApiService`.
- Version bumped to `0.3.0` across all components.

### Added — Server
- **`.env` file** — ships with all credentials pre-configured so the server starts
  immediately with `npm install && npm start`.
- **Strong JWT secret** — `LouisChat2026xK9mPq7wRt3vYz5bNc8dFg2hJk4lM` (replaces
  the insecure placeholder).

### Changed — Server
- Version bumped to `0.3.0` in `package.json`, health endpoint, and startup log.

## [0.2.0] — 2026-08-02

### Highlights

This release fixes the **"register loads forever"** bug by adding HTTP timeouts,
runtime server-URL configuration, and clear Vietnamese error messages. It also
hardens the backend (helmet, rate limit, graceful shutdown) and improves overall
UX with loading skeletons, date separators, and pull-to-retry everywhere.

### Added — App
- **`ServerSettingsScreen`** — configure API + WebSocket URL inside the app,
  with a built-in "test connection" button. Stored in `SharedPreferences`.
- **HTTP timeout (12s normal / 30s upload)** on every request — no more
  infinite spinners when the server is unreachable.
- **Splash diagnostics** — if the server is unreachable on first launch, the
  app opens `ServerSettingsScreen` automatically with a clear hint.
- **Vietnamese error messages** — `ApiException.viMessage` translates every
  known error code (`user_exists`, `invalid_credentials`, `timeout`,
  `server_unreachable`, `rate_limited`, …) into human-friendly text.
- **Server status pill** on the login screen — green "Server OK" / red
  "Server lỗi" with one-tap access to settings.
- **`/api/health` check** on app boot — server version is shown in settings.
- **Date separators** in chat ("Hôm nay", "Hôm qua", `dd/mm/yyyy`).
- **Socket reconnect indicator** — orange dot + "Đang kết nối lại..." in
  the chat header when socket is reconnecting.
- **Loading skeletons** for the chat list (animated shimmer rows).
- **Generic `ErrorView` & `EmptyView`** widgets — consistent across all tabs.
- **Pull-to-refresh** on the chat list (was already there, now more reliable).
- **Logout confirmation dialog**.
- **`connectivity_plus`** dependency added (for future use).
- **Network security config** — explicit `cleartext` allowlist for the dev
  server. For v1.0 CH Play release, switch server to HTTPS and remove this.

### Added — Backend
- **`helmet`** security headers.
- **`compression`** gzip responses.
- **`morgan`** request logging (combined in prod, dev in dev).
- **`express-rate-limit`** — 30 auth attempts / 15 min per IP, 120 API
  requests / min per IP, 20 uploads / min per IP.
- **`/api/health/deep`** — readiness check that pings PostgreSQL, MySQL,
  and Redis individually with pool stats.
- **`pgcrypto`** extension auto-created on boot (needed for `gen_random_uuid`
  on PostgreSQL < 13).
- **Graceful shutdown** — `SIGINT`/`SIGTERM` close HTTP server, Socket.io,
  and DB pools cleanly.
- **`uncaughtException` & `unhandledRejection`** handlers.
- **`trust proxy = 1`** — correct client IP behind reverse proxy.
- **Better input validation** — username regex, email regex, length caps.
- **Previous-avatar cleanup** on avatar upload (best-effort).
- **`last_seen`** updated on login/register.

### Changed
- Default API URL changed from `http://10.0.2.2:3000` (emulator-only) to
  `http://163.44.96.79:3000` (user's actual server host).
- `applicationId` unchanged, `versionCode` 1 → 2, `versionName` `0.1.0` → `0.2.0`.
- Polling interval for chat list reduced from 15s to 30s (socket handles
  the realtime updates anyway).
- Search debounced 350ms (was firing on every keystroke).
- `AppStore` exposes `serverReachable`, `serverVersion`, `checkServer()`,
  `setServerUrls()`, `resetServerUrls()`.

### Fixed
- **Critical:** register / login would spin forever when the server was
  unreachable — `http` package has no default timeout.
- Socket auth uses `setAuth()` (supported) instead of mutating
  `_socket.io.options` (which is nullable and broke compilation).
- `aspectRatio` removed from `configChanges` — invalid flag in SDK 36.
- Keystore path now resolved via `rootProject.file()` so `flutter build apk`
  finds `release.keystore` regardless of working directory.
- Email is now stored lowercase to prevent duplicate-account edge cases.
- `last_seen` populated on auth flows.

## [0.1.0] — 2026-08-02

### Added
- Flutter Android client with Messenger-style UI (splash, login, register,
  chat list, people search, chat detail, profile).
- Custom JWT auth + bcrypt password hashing.
- Avatar upload via `image_picker` + multer.
- Realtime messaging via Socket.io + Redis pub/sub.
- PostgreSQL primary store (users, conversations, messages).
- Redis sessions + presence + pub/sub.
- MySQL auxiliary event log.
- GitHub Action `build-apk.yml` — auto-build & sign APK on release.
