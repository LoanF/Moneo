# Moneo

Personal finance tracking app built with **Flutter**. Connects to the [Moneo API](https://github.com/LoanF/moneo-api).

## Features

- **Dashboard** — Global balance across all accounts, transaction list with swipe-to-check and swipe-to-delete
- **Statistics** — Monthly income/expense breakdown, 6-month bar chart, category breakdown, savings rate
- **Accounts manager** — Create and manage multiple bank accounts
- **Categories manager** — Custom categories with icons and colors
- **Payment methods** — Track transactions by payment method (card, cash, transfer…)
- **Recurring payments** — Define monthly operations that auto-generate transactions server-side
- **Authentication** — Email/password + Google Sign-In, email verification, password reset
- **Biometric lock** — Face ID / fingerprint auto-lock with configurable timeout
- **Push notifications** — Monthly recap and activity reminders via Firebase Cloud Messaging
- **Realtime sync** — Live data updates via Server-Sent Events; changes on one device appear instantly on another
- **Setup wizard** — First-launch flow to create accounts and payment methods before accessing the app

## Tech stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3 / Dart 3 |
| State management | [Provider](https://pub.dev/packages/provider) (ChangeNotifier) |
| Dependency injection | [get_it](https://pub.dev/packages/get_it) |
| Navigation | [go_router](https://pub.dev/packages/go_router) |
| HTTP client | [Dio](https://pub.dev/packages/dio) with token refresh interceptor |
| Secure storage | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) |
| Push notifications | [firebase_messaging](https://pub.dev/packages/firebase_messaging) |
| Google auth | [google_sign_in](https://pub.dev/packages/google_sign_in) |
| Biometrics | [local_auth](https://pub.dev/packages/local_auth) |

## Architecture

```
lib/
├── core/
│   ├── di.dart              # GetIt dependency injection setup
│   ├── interceptor/         # Dio API client with auth + token refresh
│   ├── notifiers/           # Auth state, biometric lock (ChangeNotifier)
│   ├── repositories/        # Data access layer (one per entity)
│   ├── routes/              # GoRouter config + route constants
│   ├── services/            # Auth, biometrics, realtime SSE
│   ├── themes/              # Dark theme, color palette
│   └── utils/               # Error handler
├── data/
│   ├── models/              # Dart data classes (Transaction, BankAccount…)
│   └── constants/           # API base URL, asset paths, config keys
└── presentation/
    ├── views/               # 15 screens (pages)
    ├── view_models/         # Business logic, state for each screen
    └── widgets/             # Reusable UI components (sheets, tiles…)
```

**Data flow:** `View → ViewModel → Repository → ApiClient (Dio) → API`

**Auth flow:** `App launch → check stored token → /auth/me → GoRouter redirect`

**Realtime flow:** `RealtimeService (SSE) → RealtimeEvent → ViewModel.listen → notifyListeners()`

## Prerequisites

- Flutter SDK 3.x (`flutter --version`)
- Dart 3.10+
- A running instance of the [Moneo API](https://github.com/LoanF/moneo-api)
- Firebase project with Android and iOS apps registered
- Google Sign-In configured (`google-services.json` / `GoogleService-Info.plist`)

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure the API URL

Edit `lib/data/constants/assets.dart` and set `apiUrl` to your API base URL:

```dart
static const String apiUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator
// static const String apiUrl = 'http://localhost:3000/api/v1'; // iOS simulator
// static const String apiUrl = 'https://api.your-domain.com/api/v1'; // Production
```

### 3. Firebase

Place the Firebase config files in the correct locations:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

### 4. Google Sign-In

Set your Google OAuth server client ID in `lib/data/constants/assets.dart`:

```dart
static const String googleServerClientId = 'YOUR_SERVER_CLIENT_ID.apps.googleusercontent.com';
```

## Run

```bash
# Debug mode
flutter run

# Specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

## Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

## Project structure details

### ViewModels

| ViewModel | Responsibility |
|---|---|
| `AuthViewModel` | Login, register, setup, profile update, account deletion |
| `HomeViewModel` | Transactions, accounts, categories, payment methods, realtime |
| `StatsViewModel` | Statistics calculations, month navigation, realtime refresh |

### Key services

| Service | Responsibility |
|---|---|
| `AuthService` | API auth calls, token storage, Google Sign-In |
| `RealtimeService` | SSE connection, auto-reconnect, event stream |
| `BiometricService` | local_auth wrapper for Face ID / fingerprint |

### Route guards

GoRouter redirects based on auth state:

| State | Redirect |
|---|---|
| Not authenticated | `/login` |
| Authenticated, email not verified | `/verify-email` |
| Authenticated, setup not completed | `/setup` |
| Authenticated, setup completed | `/home` |

## App info

- **Package name:** `com.lfxtech.moneo`
- **Min Android SDK:** 21
- **iOS deployment target:** 12+
- **Supported orientations:** Portrait
