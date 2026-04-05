# Grounded — Flutter App

A focus productivity app that breaks down big goals with AI and blocks distracting apps while you work.

## Features

- **Onboarding** — animated welcome screen on first launch
- **Task Management** — create, edit, delete, and complete tasks
- **AI Breakdown** — uses Gemini 1.5 Flash to split tasks into 3–5 subtasks with time estimates
- **App Blocking (Simulated)** — tap simulated app icons on the home screen to trigger the blocked overlay
- **Break Timer** — take a timed break that temporarily unlocks apps
- **Dark Mode** — full dark/light theme support
- **Persistent Storage** — tasks and settings saved via `shared_preferences`

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Add your Gemini API key

You can get a free key at [aistudio.google.com](https://aistudio.google.com).

Enter it in **Settings → Gemini API Key** inside the app.

### 3. Run

```bash
flutter run
```

Works on **iOS**, **Android**, **macOS**, **Web**, and **Windows**.

## Project Structure

```
lib/
├── main.dart                   # Entry point + MaterialApp
├── app_state.dart              # ChangeNotifier — all app state & logic
├── models.dart                 # Task, SubTask, AppSettings data models
├── theme.dart                  # AppColors + ThemeData (light/dark)
├── services/
│   ├── ai_service.dart         # Gemini REST API integration
│   └── storage_service.dart    # SharedPreferences persistence
└── screens/
    ├── onboarding_screen.dart  # First-launch welcome flow
    ├── home_screen.dart        # Task list + simulated launcher
    ├── create_task_screen.dart # Add / edit task + AI breakdown
    ├── settings_screen.dart    # Preferences + API key
    └── blocked_screen.dart     # App-blocked overlay
```

## Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `shared_preferences` | Local persistence |
| `http` | Gemini API calls |
| `google_fonts` | Inter typeface |

## Notes

- Real app blocking requires system-level OS permissions not available in Flutter by default. The blocking feature is **simulated** exactly as in the original web version — tap the emoji buttons at the bottom of the home screen.
- The Gemini model used is `gemini-1.5-flash`. You can swap it for `gemini-2.0-flash` or another model in `lib/services/ai_service.dart`.
