# Chime — Flutter Video Meetings (Twilio Video SDK)

A Flutter app that demonstrates creating and joining video meetings using the Twilio Video SDK with a clean architecture (BLoC, repositories, services) and native platform integrations.

## Quick Start

- **Requirements**
  - Flutter SDK 3.24+ (Dart 3.9+)
  - Android Studio / Xcode 15+
  - CocoaPods (for iOS)
  - Java 11 toolchain (Android)

- **Install dependencies**
  ```bash
  flutter pub get
  ```

- **Run on Android**
  ```bash
  flutter run -d android
  ```

- **Run on iOS**
  ```bash
  cd ios && pod install && cd -
  flutter run -d ios
  ```

- **Web/Windows/Linux**
  - The UI builds, but Twilio Video is only wired for Android and iOS in this repo.

## Project Structure (high-level)

- `lib/app/` — App bootstrapping, routes
- `lib/common/` — DI, services, utils, widgets
- `lib/meetings/` — Meetings feature (BLoC, models, repository, views)
- `lib/login/`, `lib/home/`, `lib/users/` — Other features
- `android/app/src/...` — Native Android Twilio bridge and views
- `ios/Runner/...` — Native iOS Twilio bridge and views

## Build & Run Instructions

### 1) Environment
- Ensure Flutter 3.24+ and Dart 3.9+ (from `pubspec.yaml: environment sdk ^3.9.2`).
- Use Java 11 for Android builds (Gradle config targets Java 11).
- iOS minimum platform is 12.2 (see `ios/Podfile`).

### 2) Install packages
```bash
flutter pub get
```

### 3) Platform setup
- Android: Gradle pulls `com.twilio:video-android:7.9.1` automatically.
- iOS: CocoaPods installs `TwilioVideo 5.10.2`.

If CocoaPods is not initialized or you see pod errors:
```bash
cd ios
pod repo update
pod install
cd -
```

### 4) Configure Twilio credentials (required for meetings)
Update `lib/common/config/twilio_config.dart` with your own Twilio credentials (see SDK Setup below). Then run the app:
```bash
flutter run
```

### 5) Typical flows
- Create a meeting from the Meetings screen.
- Join a meeting to connect to the Twilio Video room.
- Use the bottom bar to toggle audio/video and screen share (Android).

## SDK Setup / Configuration

Twilio Video requires access tokens (JWT) signed with an API Key. For development/testing, this project includes client‑side token generation. For production, move token generation to a backend.

### 1) Create API Key in Twilio Console
- Open `https://console.twilio.com` → Account → API Keys & Tokens → Create API Key
- Save both values:
  - API Key SID (starts with `SK...`)
  - API Key Secret (shown once)

### 2) Update app configuration
Edit `lib/common/config/twilio_config.dart` and set:
```dart
static const String accountSid = 'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
static const String authToken  = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
static const String apiKeySid  = 'SKxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
static const String apiKeySecret = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
```
Notes:
- The repository contains test values for convenience. Replace them with your own for reliable testing.
- Never commit real production secrets.

### 3) Android specifics
- Min SDK is 24; Java 11 is configured.
- Twilio dependency is declared in `android/app/build.gradle.kts`:
  ```
  implementation("com.twilio:video-android:7.9.1")
  ```
- Platform view factory and method channels are registered in:
  - `android/app/src/main/kotlin/task/amazon/chime/MainActivity.kt`
  - `android/app/src/main/kotlin/task/amazon/chime/TwilioSdkMethodHandler.kt`
- Screen sharing uses a foreground service for Android 14+.

### 4) iOS specifics
- Pod dependency is declared in `ios/Podfile`:
  ```
  pod 'TwilioVideo', '5.10.2'
  ```
- Plugin and platform view registration:
  - `ios/Runner/TwilioSdkPlugin.swift` (registers channels and view factory)
  - `ios/Runner/AppDelegate.swift` (invokes plugin registration)

### 5) Permissions
- Camera/Microphone permissions are required on both platforms.
- The app uses `permission_handler` to request runtime permissions.

## Common Tasks

- Clean builds
  ```bash
  flutter clean && flutter pub get
  (cd ios && pod deintegrate && pod install || true)
  ```

- Specify build flavors (example)
  ```bash
  flutter run --release -d android
  flutter run --release -d ios
  ```

## Assumptions & Limitations

- Client-side token generation
  - Tokens are generated on-device using `dart_jsonwebtoken` for convenience.
  - This is OK for testing but not recommended for production. Move token generation to a secure backend.

- Backend stubs / mock data
  - `MeetingsRepository` contains mocked flows for list/create/join; intended to be replaced by real backend APIs.

- Screen sharing
  - Android: Implemented (with foreground service and permission flow). Device quirks handled with retries.
  - iOS: Placeholder in the plugin; ReplayKit flow is not fully implemented in this repo.

- Supported platforms
  - Full video support is wired for Android and iOS. Desktop/Web builds are not wired for Twilio video views.

- Minimum OS versions
  - Android minSdk 24; iOS 12.2.

- Known UX behaviors
  - Video tiles appear after tracks are ready; the UI tries a few times to obtain view IDs.
  - Participant list and basic meeting controls are available; layout aims for an equal-grid experience.

## Troubleshooting

- Pod install / iOS build errors
  - Run `pod repo update`, `pod install`, then `flutter clean && flutter pub get`.

- Cannot connect to room
  - Verify the Twilio credentials and API Key values in `twilio_config.dart`.
  - Ensure device has internet and camera/mic permissions.

- No video
  - Confirm permissions granted.
  - For Android, ensure front camera is available; logs will show camera selection.

- Screen share issues (Android)
  - Ensure the screen capture permission dialog was accepted.
  - Foreground service notification should appear during sharing.

## Security Notes

- Do not ship secrets in client apps.
- Generate Twilio access tokens on a backend service in production.
- Use per-environment credentials and rotate periodically.

## References

- Twilio Video Android: `https://www.twilio.com/docs/video/android-getting-started`
- Twilio Video iOS: `https://www.twilio.com/docs/video/ios-getting-started`
- Access Tokens: `https://www.twilio.com/docs/video/tutorials/user-identity-access-tokens`
