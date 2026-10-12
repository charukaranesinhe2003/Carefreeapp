# Cycle Care

An offline-first menstrual health and cycle tracking app for teenage girls in rural Sri Lankan
schools (SLIT IT3060 HCI, Assignment 2, group WE_05). Built with Flutter and Hive.

## Principles

- **Offline-first:** no core feature needs the network. Fonts and content are bundled.
- **Privacy by design:** PIN lock, discreet look, instant HIDE button.
- **Low cognitive load**, **bilingual (Sinhala / English)**, **calm, non-stigmatizing visuals**.

## Getting started

Requirements: Flutter (stable) with Dart `^3.13.4`.

```bash
flutter pub get
flutter run
```

On Windows, building with plugins requires Developer Mode (`start ms-settings:developers`).

## Common commands

```bash
flutter analyze                                              # lint
flutter test                                                 # unit and widget tests
flutter test integration_test                                # integration tests (device/emulator)
dart run build_runner build --delete-conflicting-outputs    # regenerate Hive adapters (*.g.dart)
```

Optional run-time flags (Member 3 subsystem):

```bash
flutter run --dart-define=DEMO_PIN=1234      # seed a demo PIN on first run
flutter run --dart-define=TEST_MODE=true     # enable the user-testing metrics overlay
```

## Project structure

```
lib/
  main.dart            # app entry, initialises Hive, disables runtime font fetching
  routes.dart          # navigation helpers
  models/              # Hive models (+ generated adapters)
  services/            # storage and other services
  theme/               # AppTheme
  screens/             # screens (stubs/ holds placeholders for other members)
  widgets/             # shared UI widgets
  content/             # bundled articles, tips and quiz content
  l10n/                # Sinhala / English strings
assets/google_fonts/   # bundled Outfit and Noto Sans Sinhala fonts
```

## Team subsystems

| # | Subsystem                | Owner               |
|---|--------------------------|---------------------|
| 1 | Privacy & Onboarding     | C G Gunasekera      |
| 2 | Core Tracking (calendar) | W V D S U Helanjith |
| 3 | Private Education        | A M S P Aththanayake|
| 4 | Healthcare Access        | K G L S Senadeera   |
