# Habit Buddy

<p align="center">
  <strong>A beautiful, offline-first habit tracker, daily journal, and lunar companion built with Flutter.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-%230175C2.svg?style=flat&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Database-SQLite%20(sqflite)-003B57?style=flat&logo=sqlite&logoColor=white" alt="SQLite" />
  <img src="https://img.shields.io/badge/Version-2.0.0-gold?style=flat" alt="Version 2.0.0" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat" alt="License" />
</p>

---

## 📌 Overview

**Habit Buddy** is a mindful, offline-first mobile application designed to help individuals build consistency, reflect on their personal journey, and establish long-term positive routines.

Unlike conventional habit trackers that demand online accounts, harvest private analytics, or gate basic functions behind subscriptions, Habit Buddy treats **privacy and reliability as first-class citizens**:
- **100% Offline-First**: All your habits, streaks, and personal journal thoughts remain strictly on your device.
- **Zero Cloud Reliance**: Functions smoothly in airplane mode or off the grid without external servers.
- **Holistic Daily Rhythm**: Blends flexible habit scheduling, daily journaling, interactive streak analytics, and astronomical moon phase tracking into a unified experience.

---

## ✨ Key Features

### 1. 🎯 Flexible Habit Tracking & Scheduling
- **Three Scheduling Modes**:
  - **Daily**: Habits you practice every day.
  - **Selected Days**: Choose specific days of the week (e.g., Mon, Wed, Fri for workouts).
  - **Weekly Target**: Flexible frequency goals (e.g., read 3 times a week).
- **Categorization & Styling**: Group habits into custom or default categories (*Health & Fitness*, *Mindset*, *Personal Growth*, etc.) with unique color palettes and icons.
- **Offline Reminder Notifications**: Configurable per-habit alerts that ring at your chosen time without cloud messaging.
- **Archive System**: Safely retire old habits without deleting their historical check-in records or breaking streak stats.

### 2. 📖 Daily Journal & Reflections
- **Mindful Check-Ins**: Jot down daily reflections, thoughts, and progress notes alongside your habits.
- **Chronological Timeline**: Organized month-by-month list view with instant keyword searching.
- **Date Navigation**: Jump to any past date to review prior entries or backfill reflections.

### 3. 🌙 Offline Moon Phase Tracker
- **Astronomic Calculation**: Uses an offline mean-lunation algorithm based on the synodic month (29.53 days) to calculate the precise lunar cycle without network requests.
- **Custom Canvas Rendering**: Accurately paints current moon illumination, waxing/waning direction, and 8 astronomical phases (*New Moon*, *Waxing Crescent*, *First Quarter*, *Waxing Gibbous*, *Full Moon*, *Waning Gibbous*, *Last Quarter*, *Waning Crescent*).
- **Interactive Lunar Sheet**: Tap to view moon age in days, illumination percentage, and upcoming dates for the next New Moon and Full Moon.

### 4. 📊 Analytics, Streaks & Insights
- **Smart Streak Engine**: Dynamically calculates current streaks, longest streaks, and completion rates tailored to each habit's specific schedule.
- **Interactive Visual Charts**: Powered by `fl_chart`, inspect check-in distribution over Weekly, Monthly, and Yearly periods.
- **Consistency Score**: High-level progress ring and ratio of completed check-ins vs. expected targets.

### 5. 📅 Calendar View
- Visual monthly calendar matrix displaying day-level completion statuses:
  - 🟢 **Completed**: All scheduled habits fulfilled.
  - 🟡 **Partially Done**: Some habits checked off.
  - 🔴 **Missed**: Past scheduled day with incomplete habits.
  - ⚪ **Scheduled**: Upcoming planned habits.
- Per-day drill-down to review or toggle completions retroactively.

### 6. 🏆 Achievement Badges & Milestones
- Earn badges based on real, stored performance history:
  - **Total Check-in Milestones**: 1st check-in, 10, 50, 100 (*Centurion*), and 500 check-ins (*Unstoppable*).
  - **Daily Streaks**: 3-day, 7-day, 14-day, 30-day, 60-day, and 100-day unbroken streaks.
  - **Weekly Streaks**: 4-week and 12-week consecutive targets achieved.

### 7. 💾 Complete Data Ownership (Backup & Export)
- **JSON Backup & Restore**:
  - Export a full snapshot of habits, completion timestamps, journal entries, categories, and settings.
  - Restore via **Merge** (add missing items while keeping existing ones) or **Replace All** with confirmation protection.
- **CSV Data Export**: Export completion logs as standard `.csv` files for spreadsheets or personal data analysis.

### 8. 🎨 Material 3 Warm Aesthetic
- **Warm Gold & Charcoal Palette**: Distinctive visual design with high readability and pleasant contrast.
- **Theme Support**: Seamless switching between System, Light, and Dark modes.

---

## 🏗️ Architecture & Technology Stack

Habit Buddy follows a clean, reactive architecture with a separation of concerns across models, repositories, business logic services, and UI layers:

```
lib/
├── controllers/          # State management (AppController ChangeNotifier)
├── database/             # SQLite open helpers & migrations (DatabaseHelper)
├── models/               # Domain models (Habit, Completion, JournalEntry, BackupData)
├── repositories/         # Direct SQLite data access & query operations
├── screens/              # Top-level UI screens and dialogs
├── services/             # Pure business logic (StreakCalculator, MoonPhaseService, etc.)
├── theme/                # Material 3 colors, typography, and component themes
├── utils/                # Date math, validation, and ID utilities
└── widgets/              # Reusable UI components (HabitTile, ProgressRing, MoonPainter)
```

### Libraries & Dependencies

| Package | Purpose |
| :--- | :--- |
| **`flutter`** | Mobile framework (Material 3) |
| **`sqflite`** | Native SQLite local database engine |
| **`sqflite_common_ffi_web`** | Web-compatible SQLite WASM bindings |
| **`shared_preferences`** | Lightweight storage for preferences (theme, notification toggle) |
| **`fl_chart`** | Interactive bar and trend charts |
| **`flutter_local_notifications`** | Local schedule-based alarms and habit reminders |
| **`timezone` & `flutter_timezone`** | Timezone-aware notification triggers |
| **`file_picker`** | Native file dialogs for JSON backup & CSV export |
| **`path` & `path_provider`** | Internal directory resolution across Android, iOS, and desktop |

---

## 🗄️ Database Schema

The app uses SQLite (schema v2) with foreign keys enabled:

- **`habits`**: Stores habit name, category, icon key, color, schedule frequency (`daily`, `selectedDays`, `weeklyTarget`), target counts, reminder time, and archive status.
- **`completions`**: Junction table recording check-in date (`YYYY-MM-DD`), optional notes, and timestamps linked to habits via cascading delete foreign keys.
- **`journal_entries`**: Local journal table recording unique IDs, entry date, title, body markdown/text, and timestamps.
- **`categories`**: User and default category metadata with display sort order.

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.8.0`)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VS Code with Flutter extensions
- Android device or emulator with API Level 21+

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/habit_buddy.git
   cd habit_buddy
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify Flutter setup**:
   ```bash
   flutter doctor
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing

The project includes unit tests for calculations, serialization, models, and widgets:

```bash
# Run all tests
flutter test

# Run a specific test suite
flutter test test/streak_calculator_test.dart
flutter test test/moon_phase_service_test.dart
flutter test test/backup_serialization_test.dart
```

---

## 📦 Building for Production

### Android APK
```bash
flutter build apk --release
```
The output file will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Google Play)
```bash
flutter build appbundle --release
```
The bundle will be located at:
`build/app/outputs/bundle/release/app-release.aab`

---

## 🔒 Privacy & Permissions

- **Internet Access**: Not required. Habit Buddy does not transmit any user data over the network.
- **Notifications**: Used strictly to trigger scheduled reminders locally on your device.
- **Storage / File Access**: Used exclusively when you explicitly create or import a JSON backup or CSV export file.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
