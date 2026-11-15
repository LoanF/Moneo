# Moneo

<div align="center">

<img src="https://img.shields.io/badge/Flutter-3-02569B?logo=flutter&logoColor=white" alt="flutter" />
<img src="https://img.shields.io/badge/Dart-3-0175C2?logo=dart&logoColor=white" alt="dart" />

[![CI/CD Status](https://github.com/LoanF/Moneo/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/LoanF/Moneo/actions/workflows/ci-cd.yml)
![Latest Release](https://img.shields.io/github/v/release/LoanF/Moneo?label=version&color=blue)
[![Codecov](https://codecov.io/gh/LoanF/Moneo/graph/badge.svg?token=CE717LW0U9)](https://codecov.io/gh/LoanF/Moneo)
![License](https://img.shields.io/github/license/LoanF/Moneo)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)

**Application mobile de suivi des finances personnelles** *Construite avec Flutter, connectée à l'[API Moneo](https://github.com/LoanF/moneo-api)*

</div>

## Features

- **Fast entry** — the amount is the hero of the sheet, labels already used suggest category, payment method and amount, today by default, quick day entry (`14` → the 14th of this month), duplicate an operation
- **Three balances per account** — remaining, checked ("pointé") and as-of-today, always computed by the API; swipe between accounts on the home screen
- **Reconciliation** — tap the badge or swipe to check an operation against the bank statement
- **Transfers, chequebooks** — paired transfers between accounts, automatic cheque numbering
- **Recurring payments** — per-month amounts, one-tap setup of the month, three generation modes
- **Budgets, insights** — category budgets with alerts, monthly summary, 12-month trend, balance forecast, pivot table (period → category → subcategory)
- **Search and filters** — text, account, type, category, payment method, period, amount; debit/credit totals of the result
- **Works offline** — the last known state opens instantly; operations created without network are queued and sent when it returns
- **Notifications** — in-app centre, push on every device, quiet hours
- **Password managers** — sign-in, sign-up, reset and change-password forms expose the right autofill hints (Proton Pass, 1Password, Bitwarden, iCloud Keychain, Google)
- **Security** — biometric lock, per-device sessions with remote sign-out, account deletion
- **Import / export** — imports the `Comptes.xlsm` tracking workbook, CSV and JSON export
- **Custom UI** — dark-first, fully custom component kit, light theme available; French UI

## Tech stack

| Layer | Technology |
|---|---|
| UI | Flutter 3.50+, `material_ui` as a base, custom component kit (`lib/ui/widgets/kit.dart`) |
| State | [Riverpod 3](https://riverpod.dev) (`Notifier` / `AsyncNotifier`, no code generation) |
| Navigation | `go_router` with a stateful shell (5 tabs) |
| HTTP | `dio`, single-flight token refresh, SSE for realtime |
| Storage | `flutter_secure_storage` (tokens), JSON files (cache, offline queue, device preferences) |
| Charts | `fl_chart` |
| Push / errors | Firebase Messaging (optional), Sentry (optional) |

## Architecture

```
lib/
├── main.dart            # Bootstrap: locale, device preferences, Sentry
├── app.dart             # Router with session-driven redirects, themes, lock overlay
├── core/                # Config, formatting, API client, local JSON store
├── data/                # Immutable models and the typed API (`MoneoApi`)
├── state/               # Riverpod providers: session, shared data, lists, offline queue, services
└── ui/
    ├── theme/           # Design tokens (colours, spacing, motion) and theme
    ├── widgets/         # kit.dart (custom components) and shared states
    ├── auth/  home/  editor/  insights/  plan/  settings/
    └── shell.dart       # Floating dock, lock screen, first-run setup, notification centre
```

- **Single source of truth**: balances and statistics come from the API; the app never recomputes them.
- **`appDataProvider`** holds accounts, categories, payment methods, recurring payments and budgets, loaded in one `/bootstrap` call, cached on disk and refreshed on every server event.
- **`dataVersionProvider`** is bumped on any change; lists and statistics watch it and reload.
- **Offline queue** (`outboxProvider`): creations carry a client-generated id, so replaying them is idempotent.

The visual system is documented in [DESIGN.md](DESIGN.md), the product in [PRODUCT.md](PRODUCT.md).

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

The API URL and the Google client id are compile-time values:

```bash
flutter run --dart-define=API_URL=http://10.0.2.2:3000/api/v1   # Android emulator → local API
flutter build appbundle --release --dart-define=API_URL=https://moneo-app.com/api/v1
```

Without `API_URL`, the app targets `https://moneo-app.com/api/v1`. The app requires the Moneo API v2.

### 3. Firebase (optional)

`lib/firebase_options.dart` is not versioned: generate it with `flutterfire configure`, and place
`android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`. Without a valid
configuration the app runs normally and push notifications are simply disabled.

### 4. Google Sign-In

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_SERVER_CLIENT_ID.apps.googleusercontent.com
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
| `test/core_test.dart` | Mise en forme des montants et des dates, saisie rapide du jour, modèles, filtres ; client API : renouvellement unique de la session, fermeture sur refus du serveur, session conservée lors d'une coupure réseau |
| `test/app_test.dart` | L'app réelle pilotée contre un faux serveur : champs reconnus par les gestionnaires de mots de passe, connexion, vérification d'adresse, accueil et soldes, pointage, masquage des montants, ouverture hors-ligne sur le cache, file d'attente hors-ligne, parcours des cinq onglets |

Captures d'écran des principaux écrans (rendu de test, thème sombre) :

```bash
flutter test --dart-define=SCREENSHOTS=true --update-goldens   # écrit test/screens/*.png
```

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

## App info

- **Package name:** `com.lfxtech.moneo`
- **Min Android SDK:** 21
- **iOS deployment target:** 12+
- **Supported orientations:** Portrait
