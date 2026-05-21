# openim-flutter-app — Flutter Client

Flutter IM client app. Connects to im-business (port 10008) for auth and to OpenIM (ports 10001/10002) for messaging.

> **Upstream dependencies (DO NOT MODIFY):** `../open-im-server/`, `../openim-sdk-core/`

---

## Key Config File

`openim_common/lib/src/config.dart` line 67:
```dart
static const _host = "192.168.110.105"; // ← change to your LAN IP
```

When `_host` is an IP, URLs resolve to:
- `appAuthUrl` → `http://<host>:10008`  (im-business)
- `imApiUrl`   → `http://<host>:10002`  (OpenIM HTTP)
- `imWsUrl`    → `ws://<host>:10001`    (OpenIM WebSocket)

---

## Flutter Version Constraint

**Use FVM. Do NOT use system Flutter 3.44.0.**

| Version | Dart | Status |
|---------|------|--------|
| 3.32.x | 3.8.0 | Too old — `map_launcher ^4.4.2` needs Dart ≥ 3.8.1 |
| 3.33.x–3.43.x | 3.8.1–3.11.x | **Works** |
| 3.44.0+ | 3.12.0+ | Breaks — `extended_text_field` + `font_awesome_flutter` incompatible |

**Why 3.44 breaks:**
- `extended_text_field 16.0.2` uses `ExtendSelectionByPageIntent` (removed in Flutter 3.44)
- `font_awesome_flutter 10.12.0` extends `IconData` (became `final` in Dart 3.12)

```bash
fvm install 3.35.0
fvm use 3.35.0 --force
```

---

## Run

```bash
fvm flutter pub get
fvm flutter run -d "iPhone 17"
```

---

## iOS Setup

`ios/Podfile` known working config:
- `platform :ios, '15.0'` (line 1)
- `post_install` block sets `IPHONEOS_DEPLOYMENT_TARGET = '15.0'` for all pods

`pubspec.yaml` dependency overrides:
```yaml
dependency_overrides:
  livekit_client: ^2.6.0
  font_awesome_flutter: any
  extended_text_field: any
```

---

## Known Issues

| Issue | Fix |
|-------|-----|
| WebRTC-SDK version conflict | Force `pod 'WebRTC-SDK', '137.7151.04'` in Podfile |
| `build_runner` conflict | Pin to `^2.4.13` in pubspec.yaml |
| CocoaPods specs out of date | `pod repo update` then `pod install --repo-update` |
| Build fails on Flutter 3.44 | Switch to FVM 3.35.0 |
