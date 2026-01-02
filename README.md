# Taskly

![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A comprehensive task management and personal productivity application built with Flutter and the BLoC pattern.

---

## ✨ Features

### 📋 Task Management
- **Create & organize tasks** with names, descriptions, start dates, and deadlines
- **Priority levels** (P1-P4) for task importance ranking
- **Recurring tasks** with iCal RRULE support for flexible scheduling patterns
- **Task occurrences** - track individual instances of recurring tasks separately
- **Completion tracking** with optional notes for each occurrence

### 📁 Project Organization
- **Projects** to group related tasks together
- **Recurring projects** with the same flexible scheduling as tasks
- **Project-level priorities** and deadlines
- **Project task counts** for quick overview

### 🏷️ Labels & Values
- **Labels** for categorization with custom colors and icons
- **Value tags** - special label type for personal values/goals alignment
- **System labels** (e.g., pinned items) for special functionality
- **Multi-label support** - attach multiple labels to tasks and projects

### 🎯 Next Actions / Smart Allocation
- **Intelligent task allocation** based on your personal values and priorities
- **Multiple allocation strategies**:
  - Proportional allocation across value categories
  - Urgency-weighted prioritization
  - Round-robin distribution
  - Top categories focus
- **Pinned tasks** for items you always want on your focus list
- **Allocation transparency** - see why tasks were included or excluded
- **Configurable daily task limits**

### 📊 Analytics & Insights
- **Task statistics** - completion rates, on-time performance, overdue tracking
- **Mood trends** - track your mood over time with visual charts
- **Correlation analysis** - discover relationships between your habits and outcomes
- **Statistical significance** metrics for correlations
- **Trend visualization** with configurable time ranges
- **Distribution charts** for mood and tracker data

### 🧘 Wellbeing Tracking
- **Journal entries** with mood ratings (5-level scale with emoji)
- **Custom trackers** with multiple response types:
  - Choice (multiple options)
  - Scale (numeric range)
  - Yes/No (binary)
- **Daily and per-entry tracking** scopes
- **Wellbeing dashboard** for overview and insights

### 🔄 Workflows
- **Customizable workflow definitions** with multiple steps
- **Workflow triggers** for scheduled or manual execution
- **Step-by-step workflow runner**
- **Problem detection** with configurable thresholds:
  - Urgent deadline warnings
  - Stale task detection
- **Review tracking** - track when items were last reviewed

### 🖥️ Configurable Screens
- **Collection views** - simple lists (Inbox, Projects, Labels)
- **Agenda views** - date-grouped displays (Today, Upcoming)
- **Detail views** - project and label detail pages
- **Allocated views** - smart next actions display
- **Customizable display settings**:
  - Group by (project, value, label, date, priority)
  - Multi-level sorting
  - Show/hide completed items

### 🔍 Advanced Filtering
- **Rule-based task filtering** with multiple rule types:
  - Date rules (deadline, start date, relative dates)
  - Boolean rules (completed, has project, has labels)
  - Label rules (has specific labels/values)
  - Project rules (belongs to project)
  - Value rules (associated with values)
- **Combinable rule sets** with AND/OR logic

### ⚙️ Settings & Customization
- **Light/Dark theme** support with system preference detection
- **Configurable date formats**
- **Allocation strategy settings**
- **Soft gates thresholds** for problem detection
- **Priority rankings** for values, projects, and contexts

### 🔐 Authentication
- **User authentication** via Supabase
- **Sign up / Sign in** flows
- **Password recovery**

### ☁️ Sync & Storage
- **Cloud sync** via Supabase backend
- **Offline-first** architecture with PowerSync
- **Local Drift database** for fast local operations

---

## 🏗️ Architecture

### Clean Architecture Layers

```
lib/
├── core/           # Shared utilities, DI, routing, theming
├── data/           # Repositories, database, API implementations
├── domain/         # Business logic, models, interfaces, services
└── presentation/   # UI layer - BLoCs, views, widgets
```

### State Management
- **BLoC pattern** using `flutter_bloc` for predictable state management
- **Reactive streams** with RxDart for complex data flows
- **Freezed** for immutable data classes and unions

### Key Technologies
| Category | Technology |
|----------|------------|
| State Management | flutter_bloc, rxdart |
| Local Database | Drift (SQLite) |
| Cloud Sync | Supabase, PowerSync |
| Routing | go_router |
| Code Generation | freezed, json_serializable, build_runner |
| Charts | fl_chart |
| Forms | flutter_form_builder |
| Analysis | very_good_analysis |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ^3.35.0
- Dart SDK ^3.9.0

### Setup

1. **Clone the repository**
   ```sh
   git clone https://github.com/sebastianHobby/taskly_bloc.git
   cd taskly_bloc
   ```

2. **Install dependencies**
   ```sh
   flutter pub get
   ```

3. **Generate code** (models, serializers)
   ```sh
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Configure environment**
   - See [ENVIRONMENT_SETUP.md](ENVIRONMENT_SETUP.md) for Supabase configuration

5. **Run the app**
   ```sh
   flutter run
   ```

---

## 🧪 Testing

```sh
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Filter coverage (excludes generated files)
dart run tool/coverage_filter.dart

# Generate HTML report
genhtml coverage/lcov_filtered.info -o coverage/html
```

See [test/README.md](test/README.md) for testing guidelines and [test/QUICK_REFERENCE.md](test/QUICK_REFERENCE.md) for quick reference.

---

## 🌐 Internationalization

This project uses [flutter_localizations][flutter_localizations_link] following the [official internationalization guide][internationalization_link].

### Adding Strings

1. Add new strings to `lib/core/l10n/arb/app_en.arb`:
   ```arb
   {
       "helloWorld": "Hello World",
       "@helloWorld": {
           "description": "Hello World Text"
       }
   }
   ```

2. Use in your widgets:
   ```dart
   import 'package:taskly_bloc/core/l10n/l10n.dart';

   Text(context.l10n.helloWorld);
   ```

3. Generate translations:
   ```sh
   flutter gen-l10n --arb-dir="lib/core/l10n/arb"
   ```

---

## 📱 Supported Platforms

| Platform | Status |
|----------|--------|
| iOS | ✅ |
| Android | ✅ |
| Web | ✅ |
| Windows | ✅ |
| macOS | ✅ |

