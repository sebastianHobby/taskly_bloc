# Phase 3A: BLoC Layer

## AI Implementation Instructions

### Environment Setup
- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each file creation. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

### Phase Goal
Create SectionBloc to replace ViewBloc. This BLoC handles state management for section-based screens using SectionDataService. The UI layer (Phase 3B) will consume this BLoC.

### Prerequisites
- Phase 0 complete (foundation types exist)
- Phase 1 complete (SectionDataService exists)
- Phase 2 complete (ScreenDefinition has sections)

---

## Task 1: Create SectionBloc Events

**File**: `lib/presentation/features/screens/bloc/section_bloc.dart`

**Pattern Reference**: Examine existing `lib/presentation/features/screens/bloc/view_bloc.dart` for patterns.

```dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';
import 'package:taskly_bloc/domain/models/screens/fetch_result.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_service.dart';

part 'section_bloc.freezed.dart';

// =============================================================================
// Events
// =============================================================================

@freezed
sealed class SectionBlocEvent with _$SectionBlocEvent {
  /// Start watching all sections for a screen
  const factory SectionBlocEvent.started({
    required ScreenDefinition screen,
    /// Parent entity ID for detail screens (e.g., project ID)
    String? parentEntityId,
  }) = SectionBlocStarted;

  /// Refresh all section data
  const factory SectionBlocEvent.refreshed() = SectionBlocRefreshed;

  /// Toggle task completion (delegated to repository)
  const factory SectionBlocEvent.taskCompletionToggled({
    required Task task,
  }) = SectionBlocTaskCompletionToggled;

  /// Update display settings for a specific section
  const factory SectionBlocEvent.displaySettingsChanged({
    required int sectionIndex,
    required SectionDisplaySettings settings,
  }) = SectionBlocDisplaySettingsChanged;

  /// Collapse/expand a group within a section
  const factory SectionBlocEvent.groupToggled({
    required int sectionIndex,
    required String groupId,
  }) = SectionBlocGroupToggled;

  /// Change related data display mode for a section
  const factory SectionBlocEvent.relatedDisplayModeChanged({
    required int sectionIndex,
    required RelatedDisplayMode mode,
  }) = SectionBlocRelatedDisplayModeChanged;
}

// =============================================================================
// States
// =============================================================================

@freezed
sealed class SectionBlocState with _$SectionBlocState {
  const factory SectionBlocState.initial() = SectionBlocInitial;
  
  const factory SectionBlocState.loading() = SectionBlocLoading;

  /// All sections loaded successfully
  const factory SectionBlocState.loaded({
    required ScreenDefinition screen,
    required List<LoadedSection> sections,
    /// Parent entity ID (for detail screens)
    String? parentEntityId,
  }) = SectionBlocLoaded;

  /// Partial load - some sections failed
  const factory SectionBlocState.partiallyLoaded({
    required ScreenDefinition screen,
    required List<LoadedSection> sections,
    required List<SectionError> errors,
    String? parentEntityId,
  }) = SectionBlocPartiallyLoaded;

  const factory SectionBlocState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = SectionBlocError;
}

/// A section with its loaded data and display settings
@freezed
class LoadedSection with _$LoadedSection {
  const factory LoadedSection({
    /// Index in the screen's sections list
    required int index,
    /// The section definition
    required Section section,
    /// The loaded data for this section
    required SectionData data,
    /// User's display preferences for this section
    required SectionDisplaySettings displaySettings,
  }) = _LoadedSection;
}

/// Error for a specific section
@freezed
class SectionError with _$SectionError {
  const factory SectionError({
    required int sectionIndex,
    required Object error,
    StackTrace? stackTrace,
  }) = _SectionError;
}

// =============================================================================
// BLoC
// =============================================================================

/// BLoC for managing section-based screen state.
/// 
/// Replaces ViewBloc with a more flexible architecture that supports:
/// - Multiple sections per screen
/// - Different section types (data, support, navigation, allocation)
/// - Per-section display settings
/// - Related data with configurable display modes
class SectionBloc extends Bloc<SectionBlocEvent, SectionBlocState> {
  SectionBloc({
    required SectionDataService sectionDataService,
  })  : _sectionDataService = sectionDataService,
        super(const SectionBlocState.initial()) {
    on<SectionBlocStarted>(_onStarted);
    on<SectionBlocRefreshed>(_onRefreshed);
    on<SectionBlocTaskCompletionToggled>(_onTaskCompletionToggled);
    on<SectionBlocDisplaySettingsChanged>(_onDisplaySettingsChanged);
    on<SectionBlocGroupToggled>(_onGroupToggled);
    on<SectionBlocRelatedDisplayModeChanged>(_onRelatedDisplayModeChanged);
  }

  final SectionDataService _sectionDataService;

  ScreenDefinition? _currentScreen;
  String? _parentEntityId;
  final Map<int, StreamSubscription<SectionData>> _subscriptions = {};
  final Map<int, SectionData> _sectionData = {};
  final Map<int, SectionDisplaySettings> _displaySettings = {};

  @override
  Future<void> close() {
    _cancelAllSubscriptions();
    return super.close();
  }

  void _cancelAllSubscriptions() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  Future<void> _onStarted(
    SectionBlocStarted event,
    Emitter<SectionBlocState> emit,
  ) async {
    _currentScreen = event.screen;
    _parentEntityId = event.parentEntityId;
    _sectionData.clear();
    _displaySettings.clear();
    _cancelAllSubscriptions();

    emit(const SectionBlocState.loading());

    await _startWatchingAllSections(emit);
  }

  Future<void> _onRefreshed(
    SectionBlocRefreshed event,
    Emitter<SectionBlocState> emit,
  ) async {
    if (_currentScreen == null) return;
    
    emit(const SectionBlocState.loading());
    await _startWatchingAllSections(emit);
  }

  Future<void> _startWatchingAllSections(Emitter<SectionBlocState> emit) async {
    final screen = _currentScreen;
    if (screen == null) {
      emit(const SectionBlocState.error(
        error: 'No screen definition provided',
        stackTrace: StackTrace.empty,
      ));
      return;
    }

    final sections = screen.sections;
    if (sections.isEmpty) {
      emit(SectionBlocState.loaded(
        screen: screen,
        sections: [],
        parentEntityId: _parentEntityId,
      ));
      return;
    }

    // Initialize display settings for each section
    for (var i = 0; i < sections.length; i++) {
      _displaySettings[i] ??= const SectionDisplaySettings();
    }

    // Start watching each section
    final errors = <SectionError>[];
    
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      
      try {
        _subscriptions[i]?.cancel();
        _subscriptions[i] = _sectionDataService
            .watchSection(section, parentEntityId: _parentEntityId)
            .listen(
          (data) {
            _sectionData[i] = data;
            _emitCurrentState();
          },
          onError: (error, stackTrace) {
            talker.handle(error, stackTrace, '[SectionBloc] Section $i error');
            errors.add(SectionError(
              sectionIndex: i,
              error: error,
              stackTrace: stackTrace,
            ));
            _emitCurrentState();
          },
        );
      } catch (e, st) {
        talker.handle(e, st, '[SectionBloc] Failed to watch section $i');
        errors.add(SectionError(sectionIndex: i, error: e, stackTrace: st));
      }
    }

    // Wait briefly for initial data to arrive
    await Future.delayed(const Duration(milliseconds: 100));
    _emitCurrentState();
  }

  void _emitCurrentState() {
    final screen = _currentScreen;
    if (screen == null) return;

    final loadedSections = <LoadedSection>[];
    final errors = <SectionError>[];

    for (var i = 0; i < screen.sections.length; i++) {
      final data = _sectionData[i];
      if (data != null) {
        loadedSections.add(LoadedSection(
          index: i,
          section: screen.sections[i],
          data: data,
          displaySettings: _displaySettings[i] ?? const SectionDisplaySettings(),
        ));
      } else {
        // Section hasn't loaded yet - could be error or still loading
        // For now, just skip it
      }
    }

    if (errors.isNotEmpty) {
      emit(SectionBlocState.partiallyLoaded(
        screen: screen,
        sections: loadedSections,
        errors: errors,
        parentEntityId: _parentEntityId,
      ));
    } else if (loadedSections.length == screen.sections.length) {
      emit(SectionBlocState.loaded(
        screen: screen,
        sections: loadedSections,
        parentEntityId: _parentEntityId,
      ));
    }
    // If neither, we're still loading
  }

  Future<void> _onTaskCompletionToggled(
    SectionBlocTaskCompletionToggled event,
    Emitter<SectionBlocState> emit,
  ) async {
    // Task completion is handled by TaskRepository directly
    // The section data will update via the stream subscription
    talker.blocLog(
      'SectionBloc',
      'Task completion toggled for ${event.task.id} - will update via stream',
    );
  }

  Future<void> _onDisplaySettingsChanged(
    SectionBlocDisplaySettingsChanged event,
    Emitter<SectionBlocState> emit,
  ) async {
    _displaySettings[event.sectionIndex] = event.settings;
    _emitCurrentState();
    
    // TODO: Persist display settings to repository
  }

  Future<void> _onGroupToggled(
    SectionBlocGroupToggled event,
    Emitter<SectionBlocState> emit,
  ) async {
    final current = _displaySettings[event.sectionIndex] ?? 
        const SectionDisplaySettings();
    
    final collapsed = Set<String>.from(current.collapsedGroupIds);
    if (collapsed.contains(event.groupId)) {
      collapsed.remove(event.groupId);
    } else {
      collapsed.add(event.groupId);
    }
    
    _displaySettings[event.sectionIndex] = current.copyWith(
      collapsedGroupIds: collapsed,
    );
    _emitCurrentState();
  }

  Future<void> _onRelatedDisplayModeChanged(
    SectionBlocRelatedDisplayModeChanged event,
    Emitter<SectionBlocState> emit,
  ) async {
    final current = _displaySettings[event.sectionIndex] ?? 
        const SectionDisplaySettings();
    
    _displaySettings[event.sectionIndex] = current.copyWith(
      relatedDisplayMode: event.mode,
    );
    _emitCurrentState();
  }
}
```

---

## Task 2: Create ScreenSectionsBloc (Alternative Simpler Pattern)

If the above pattern seems complex, here's a simpler alternative that uses `emit.forEach` per section:

**File**: `lib/presentation/features/screens/bloc/screen_sections_bloc.dart`

```dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';
import 'package:taskly_bloc/domain/models/screens/fetch_result.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_service.dart';

part 'screen_sections_bloc.freezed.dart';

// Events
@freezed
sealed class ScreenSectionsEvent with _$ScreenSectionsEvent {
  const factory ScreenSectionsEvent.started({
    required ScreenDefinition screen,
    String? parentEntityId,
  }) = _Started;

  const factory ScreenSectionsEvent.refreshed() = _Refreshed;
}

// State
@freezed
sealed class ScreenSectionsState with _$ScreenSectionsState {
  const factory ScreenSectionsState.initial() = _Initial;
  const factory ScreenSectionsState.loading() = _Loading;
  const factory ScreenSectionsState.loaded({
    required ScreenDefinition screen,
    required Map<int, SectionData> sectionData,
    String? parentEntityId,
  }) = _Loaded;
  const factory ScreenSectionsState.error({
    required Object error,
    StackTrace? stackTrace,
  }) = _Error;
}

/// Simpler BLoC that combines all section streams into one
class ScreenSectionsBloc extends Bloc<ScreenSectionsEvent, ScreenSectionsState> {
  ScreenSectionsBloc({
    required SectionDataService sectionDataService,
  })  : _sectionDataService = sectionDataService,
        super(const ScreenSectionsState.initial()) {
    on<_Started>(_onStarted);
    on<_Refreshed>(_onRefreshed);
  }

  final SectionDataService _sectionDataService;
  ScreenDefinition? _screen;
  String? _parentEntityId;

  Future<void> _onStarted(
    _Started event,
    Emitter<ScreenSectionsState> emit,
  ) async {
    _screen = event.screen;
    _parentEntityId = event.parentEntityId;
    
    emit(const ScreenSectionsState.loading());
    
    final screen = event.screen;
    if (screen.sections.isEmpty) {
      emit(ScreenSectionsState.loaded(
        screen: screen,
        sectionData: {},
        parentEntityId: _parentEntityId,
      ));
      return;
    }

    // Create a stream for each section
    final sectionStreams = <Stream<MapEntry<int, SectionData>>>[];
    
    for (var i = 0; i < screen.sections.length; i++) {
      final section = screen.sections[i];
      sectionStreams.add(
        _sectionDataService
            .watchSection(section, parentEntityId: _parentEntityId)
            .map((data) => MapEntry(i, data)),
      );
    }

    // Combine all streams - emit whenever any section updates
    final combinedStream = Rx.combineLatestList(
      sectionStreams.map((s) => s.asBroadcastStream()),
    ).map((entries) => {for (final e in entries) e.key: e.value});

    await emit.forEach<Map<int, SectionData>>(
      combinedStream,
      onData: (sectionData) => ScreenSectionsState.loaded(
        screen: screen,
        sectionData: sectionData,
        parentEntityId: _parentEntityId,
      ),
      onError: (error, stackTrace) => ScreenSectionsState.error(
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  Future<void> _onRefreshed(
    _Refreshed event,
    Emitter<ScreenSectionsState> emit,
  ) async {
    if (_screen != null) {
      add(ScreenSectionsEvent.started(
        screen: _screen!,
        parentEntityId: _parentEntityId,
      ));
    }
  }
}
```

**Choose ONE of the above patterns** based on complexity needs. The first (SectionBloc) gives more control over individual sections. The second (ScreenSectionsBloc) is simpler but less flexible.

---

## Task 3: Create SectionDisplaySettingsRepository

**File**: `lib/domain/interfaces/section_display_settings_repository_contract.dart`

```dart
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';

/// Repository for persisting user's section display preferences
abstract class SectionDisplaySettingsRepositoryContract {
  /// Get display settings for a specific section
  /// Returns default settings if none saved
  Future<SectionDisplaySettings> getSettings({
    required String screenId,
    required int sectionIndex,
  });

  /// Watch display settings changes
  Stream<SectionDisplaySettings> watchSettings({
    required String screenId,
    required int sectionIndex,
  });

  /// Save display settings for a section
  Future<void> saveSettings({
    required String screenId,
    required int sectionIndex,
    required SectionDisplaySettings settings,
  });

  /// Get all settings for a screen (all sections)
  Future<Map<int, SectionDisplaySettings>> getAllSettingsForScreen(
    String screenId,
  );

  /// Delete settings for a screen (when screen is deleted)
  Future<void> deleteSettingsForScreen(String screenId);
}
```

**File**: `lib/data/features/screens/section_display_settings_repository.dart`

```dart
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/database.dart';
import 'package:taskly_bloc/domain/interfaces/section_display_settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';

class SectionDisplaySettingsRepository 
    implements SectionDisplaySettingsRepositoryContract {
  SectionDisplaySettingsRepository({
    required AppDatabase database,
  }) : _database = database;

  final AppDatabase _database;

  // Cache for quick access
  final _cache = <String, SectionDisplaySettings>{};

  String _cacheKey(String screenId, int sectionIndex) => 
      '$screenId:$sectionIndex';

  @override
  Future<SectionDisplaySettings> getSettings({
    required String screenId,
    required int sectionIndex,
  }) async {
    final key = _cacheKey(screenId, sectionIndex);
    
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    // TODO: Query from database
    // For now, return defaults
    return const SectionDisplaySettings();
  }

  @override
  Stream<SectionDisplaySettings> watchSettings({
    required String screenId,
    required int sectionIndex,
  }) async* {
    // TODO: Implement with Drift watch query
    yield const SectionDisplaySettings();
  }

  @override
  Future<void> saveSettings({
    required String screenId,
    required int sectionIndex,
    required SectionDisplaySettings settings,
  }) async {
    final key = _cacheKey(screenId, sectionIndex);
    _cache[key] = settings;

    // TODO: Persist to database
  }

  @override
  Future<Map<int, SectionDisplaySettings>> getAllSettingsForScreen(
    String screenId,
  ) async {
    // TODO: Query all settings for screen
    return {};
  }

  @override
  Future<void> deleteSettingsForScreen(String screenId) async {
    // Remove from cache
    _cache.removeWhere((key, _) => key.startsWith('$screenId:'));
    
    // TODO: Delete from database
  }
}
```

---

## Task 4: Create Drift Table for Display Settings

**File**: Add to `lib/data/drift/features/screen_tables.drift.dart`

```sql
-- Section display settings table
CREATE TABLE section_display_settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  screen_id TEXT NOT NULL,
  section_index INTEGER NOT NULL,
  settings_json TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE(screen_id, section_index)
) AS SectionDisplaySettingsTable;
```

---

## Task 5: Register BLoC and Repository in DI

**File**: `lib/core/dependency_injection/dependency_injection.dart`

Add registrations:

```dart
// Repository
..registerLazySingleton<SectionDisplaySettingsRepositoryContract>(
  () => SectionDisplaySettingsRepository(
    database: getIt<AppDatabase>(),
  ),
)

// BLoC - register as factory (new instance per screen)
..registerFactory<SectionBloc>(
  () => SectionBloc(
    sectionDataService: getIt<SectionDataService>(),
  ),
)
```

---

## Task 6: Create BLoC Provider Helper

**File**: `lib/presentation/features/screens/bloc/section_bloc_provider.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/section_bloc.dart';

/// Helper widget to provide SectionBloc for a screen
class SectionBlocProvider extends StatelessWidget {
  const SectionBlocProvider({
    required this.screen,
    required this.child,
    this.parentEntityId,
    super.key,
  });

  final ScreenDefinition screen;
  final Widget child;
  final String? parentEntityId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('section_bloc_${screen.id}'),
      create: (_) => getIt<SectionBloc>()
        ..add(SectionBlocEvent.started(
          screen: screen,
          parentEntityId: parentEntityId,
        )),
      child: child,
    );
  }
}
```

---

## Task 7: Update Exports

**File**: `lib/presentation/features/screens/bloc/bloc.dart` (create if not exists)

```dart
export 'section_bloc.dart';
export 'section_bloc_provider.dart';
export 'screen_definition_bloc.dart';
export 'view_bloc.dart'; // Keep for now, deprecated in Phase 6
```

---

## Validation Checklist

After completing all tasks:

1. [ ] Run `flutter analyze` - expect 0 errors, 0 warnings
2. [ ] Verify `section_bloc.freezed.dart` generates
3. [ ] Verify SectionBloc can be instantiated via DI
4. [ ] Verify SectionDisplaySettingsRepository compiles
5. [ ] Existing ViewBloc untouched (still works)

---

## Files Created This Phase

| File | Purpose |
|------|---------|
| `lib/presentation/features/screens/bloc/section_bloc.dart` | Main BLoC for sections |
| `lib/presentation/features/screens/bloc/section_bloc_provider.dart` | Helper widget |
| `lib/domain/interfaces/section_display_settings_repository_contract.dart` | Settings contract |
| `lib/data/features/screens/section_display_settings_repository.dart` | Settings implementation |

## Files Modified This Phase

| File | Change |
|------|--------|
| `lib/data/drift/features/screen_tables.drift.dart` | Add settings table |
| `lib/core/dependency_injection/dependency_injection.dart` | Register BLoC and repo |
| `lib/presentation/features/screens/bloc/bloc.dart` | Add exports |

---

## Architecture Notes

### State Flow
```
ScreenDefinition.sections
        ↓
SectionDataService.watchSection() (per section)
        ↓
SectionBloc combines streams
        ↓
SectionBlocState.loaded(List<LoadedSection>)
        ↓
UI renders each LoadedSection
```

### Display Settings Flow
```
User changes setting
        ↓
SectionBlocEvent.displaySettingsChanged
        ↓
SectionBloc updates _displaySettings map
        ↓
_emitCurrentState() with updated LoadedSection
        ↓
(Background) Save to SectionDisplaySettingsRepository
```

---

## Next Phase
Proceed to **Phase 3B: UI Layer** after all validation passes.
