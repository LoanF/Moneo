# Moneo

<div align="center">

<img src="https://img.shields.io/badge/Flutter-3-02569B?logo=flutter&logoColor=white" alt="flutter" />
<img src="https://img.shields.io/badge/Dart-3-0175C2?logo=dart&logoColor=white" alt="dart" />

[![CI/CD Status](https://github.com/LoanF/Moneo/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/LoanF/Moneo/actions/workflows/ci-cd.yml)
![Latest Release](https://img.shields.io/github/v/release/LoanF/Moneo?label=version&color=blue)
[![Codecov](https://codecov.io/github/LoanF/Moneo/graph/badge.svg?token=CE717LW0U9)](https://codecov.io/github/LoanF/Moneo)
![License](https://img.shields.io/github/license/LoanF/Moneo)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)

**Application mobile de suivi des finances personnelles** *Construite avec Flutter, connectée à l'[API Moneo](https://github.com/LoanF/moneo-api)*

</div>

## Features

- **Dashboard** — Solde global sur tous les comptes, liste des transactions avec swipe-to-check et swipe-to-delete
- **Statistics** — Décomposition revenus/dépenses mensuelle, graphique en barres sur 6 mois, répartition par catégorie, taux d'épargne
- **Accounts manager** — Création et gestion de plusieurs comptes bancaires
- **Categories manager** — Catégories personnalisées avec icônes et couleurs
- **Payment methods** — Suivi des transactions par moyen de paiement (carte, espèces, virement…)
- **Recurring payments** — Paiements mensuels récurrents générés automatiquement côté serveur
- **Authentication** — Email/mot de passe + Google Sign-In, vérification email, réinitialisation du mot de passe
- **Biometric lock** — Verrouillage automatique Face ID / empreinte avec délai configurable
- **Push notifications** — Récapitulatif mensuel et rappels d'activité via Firebase Cloud Messaging
- **Realtime sync** — Mises à jour en temps réel via Server-Sent Events ; les modifications d'un appareil apparaissent instantanément sur les autres
- **Setup wizard** — Assistant de premier lancement pour créer des comptes et moyens de paiement

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
| CI | GitHub Actions |

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
# Android App Bundle (Play Store)
flutter build appbundle --release

# Android APK
flutter build apk --release

# iOS (requires macOS + Xcode)
flutter build ios --release --no-codesign
```

## Tests

```bash
# Lancer tous les tests
flutter test

# Mode watch
flutter test --watch
```

### Ce qui est couvert

| Fichier | Ce qui est testé |
|---|---|
| `test/widget_test.dart` | `Transaction.fromJson` (champs de base, détection `isMonthly`, types d'amount) |
| | `BankAccount.fromJson` (tous les champs, `pointedBalance` par défaut) |
| | `Category.fromJson` (`colorValue` en int ou String) |
| | `MonthlyPayment.fromJson` (alias `lastProcessed`/`lastApplied`, valeur null) |
| | `AppUser.fromJson` (uid depuis `id`, `notificationPrefs` par défaut) |

## CI/CD

Le pipeline GitHub Actions se déclenche sur chaque push vers `develop` et `master`.

```
push → [check] flutter analyze + flutter test
             ↓ (master uniquement)
       [version_bump] bump pubspec.yaml + CHANGELOG
             ↓
       [build_android] flutter build appbundle  →  artifact AAB (30 j)
       [build_ios]     flutter build ios         →  artifact .app (30 j)
```

### Intégration continue (toutes branches)

1. Analyse statique (`flutter analyze`)
2. Tests unitaires (`flutter test`)

### Déploiement continu (master uniquement)

1. **Version bump** — `standard-version` lit et bumpe la version dans `pubspec.yaml` selon les [Conventional Commits](https://conventionalcommits.org), génère le `CHANGELOG.md`, crée le tag Git et la release GitHub
2. **Build Android** — produit un AAB signé avec la debug key (artefact archivé 30 jours)
3. **Build iOS** — compile sans signature de distribution (artefact archivé 30 jours)

> Pour publier sur le Play Store ou l'App Store, il faudra configurer les secrets de signing et ajouter une étape de déploiement.

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
