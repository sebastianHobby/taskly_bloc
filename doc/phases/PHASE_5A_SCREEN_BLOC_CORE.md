# Phase 5A: Unified ScreenBloc - Core

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Create the unified `ScreenBloc` with events and state definitions.

**Decisions Implemented**: DR-017 (Unified Screen Model)

---

## Prerequisites

- Phase 4A complete (SectionDataService exists)
- Phase 4B complete (Repository query methods exist)

---

## Task 1: Create ScreenEvent

**File**: `lib/presentation/features/screens/bloc/screen_event.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';

part 'screen_event.freezed.dart';

/// Events for the unified ScreenBloc
@freezed
sealed class ScreenEvent with _$ScreenEvent {
  /// Load screen by definition
  const factory ScreenEvent.load({
    required ScreenDefinition definition,
  }) = ScreenLoadEvent;

  /// Load screen by ID (fetches definition from repository)
  const factory ScreenEvent.loadById({
    required String screenId,
  }) = ScreenLoadByIdEvent;

  /// Refresh all sections data
  const factory ScreenEvent.refresh() = ScreenRefreshEvent;

  /// Refresh specific section by index
  const factory ScreenEvent.refreshSection({
    required int sectionIndex,
  }) = ScreenRefreshSectionEvent;

  /// Entity action (tap, complete, etc.)
  const factory ScreenEvent.entityAction({
    required String entityId,
    required String entityType,
    required EntityAction action,
  }) = ScreenEntityActionEvent;

  /// Navigate to entity detail
  const factory ScreenEvent.navigateToEntity({
    required String entityId,
    required String entityType,
  }) = ScreenNavigateToEntityEvent;

  /// Support block action
  const factory ScreenEvent.supportBlockAction({
    required int blockIndex,
    required String actionId,
    Map<String, dynamic>? params,
  }) = ScreenSupportBlockActionEvent;
}

/// Actions that can be performed on entities
enum EntityAction {
  tap,
  complete,
  uncomplete,
  delete,
  archive,
  move,
  edit,
}
```

---

## Task 2: Create ScreenState

**File**: `lib/presentation/features/screens/bloc/screen_state.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/services/section_data_result.dart';
import 'package:taskly_bloc/domain/services/support_block_result.dart';

part 'screen_state.freezed.dart';

/// State for the unified ScreenBloc
@freezed
sealed class ScreenState with _$ScreenState {
  /// Initial state before loading
  const factory ScreenState.initial() = ScreenInitialState;

  /// Loading state
  const factory ScreenState.loading({
    ScreenDefinition? definition,
  }) = ScreenLoadingState;

  /// Loaded state with all data
  const factory ScreenState.loaded({
    required ScreenDefinition definition,
    required List<SectionData> sections,
    required List<SupportBlockData> supportBlocks,
    @Default(false) bool isRefreshing,
  }) = ScreenLoadedState;

  /// Error state
  const factory ScreenState.error({
    required String message,
    ScreenDefinition? definition,
    Object? error,
    StackTrace? stackTrace,
  }) = ScreenErrorState;
}

/// Data for a rendered section
@freezed
class SectionData with _$SectionData {
  const factory SectionData({
    required int index,
    required String? title,
    required SectionDataResult data,
    @Default(false) bool isLoading,
    String? error,
  }) = _SectionData;
}

/// Data for a rendered support block
@freezed
class SupportBlockData with _$SupportBlockData {
  const factory SupportBlockData({
    required int index,
    required SupportBlock config,
    required SupportBlockResult result,
  }) = _SupportBlockData;
}
```

---

## Task 3: Create ScreenBloc Shell

**File**: `lib/presentation/features/screens/bloc/screen_bloc.dart`

```dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/repositories/screen_repository.dart';
import 'package:taskly_bloc/domain/services/section_data_service.dart';
import 'package:taskly_bloc/domain/services/support_block_computer.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';

/// Unified bloc for all screen types (DR-017)
class ScreenBloc extends Bloc<ScreenEvent, ScreenState> {
  final ScreenRepository _screenRepository;
  final SectionDataService _sectionDataService;
  final SupportBlockComputer _supportBlockComputer;

  ScreenBloc({
    required ScreenRepository screenRepository,
    required SectionDataService sectionDataService,
    required SupportBlockComputer supportBlockComputer,
  })  : _screenRepository = screenRepository,
        _sectionDataService = sectionDataService,
        _supportBlockComputer = supportBlockComputer,
        super(const ScreenState.initial()) {
    on<ScreenLoadEvent>(_onLoad);
    on<ScreenLoadByIdEvent>(_onLoadById);
    on<ScreenRefreshEvent>(_onRefresh);
    on<ScreenRefreshSectionEvent>(_onRefreshSection);
    on<ScreenEntityActionEvent>(_onEntityAction);
    on<ScreenNavigateToEntityEvent>(_onNavigateToEntity);
    on<ScreenSupportBlockActionEvent>(_onSupportBlockAction);
  }

  // Event handlers will be implemented in Phase 5B
  Future<void> _onLoad(
    ScreenLoadEvent event,
    Emitter<ScreenState> emit,
  ) async {
    // TODO: Implement in Phase 5B
  }

  Future<void> _onLoadById(
    ScreenLoadByIdEvent event,
    Emitter<ScreenState> emit,
  ) async {
    // TODO: Implement in Phase 5B
  }

  Future<void> _onRefresh(
    ScreenRefreshEvent event,
    Emitter<ScreenState> emit,
  ) async {
    // TODO: Implement in Phase 5B
  }

  Future<void> _onRefreshSection(
    ScreenRefreshSectionEvent event,
    Emitter<ScreenState> emit,
  ) async {
    // TODO: Implement in Phase 5B
  }

  Future<void> _onEntityAction(
    ScreenEntityActionEvent event,
    Emitter<ScreenState> emit,
  ) async {
    // TODO: Implement in Phase 5B
  }

  Future<void> _onNavigateToEntity(
    ScreenNavigateToEntityEvent event,
    Emitter<ScreenState> emit,
  ) async {
    // TODO: Implement in Phase 5B
  }

  Future<void> _onSupportBlockAction(
    ScreenSupportBlockActionEvent event,
    Emitter<ScreenState> emit,
  ) async {
    // TODO: Implement in Phase 5B
  }
}
```

---

## Task 4: Create Bloc Barrel Export

**File**: `lib/presentation/features/screens/bloc/bloc.dart`

```dart
export 'screen_bloc.dart';
export 'screen_event.dart';
export 'screen_state.dart';
```

---

## Task 5: Update Screens Feature Export

**File**: `lib/presentation/features/screens/screens.dart`

Add bloc export:

```dart
export 'bloc/bloc.dart';
// ... existing widget exports
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `screen_event.freezed.dart` generated
- [ ] `screen_state.freezed.dart` generated
- [ ] `ScreenBloc` compiles without errors
- [ ] All events are registered in the bloc constructor
- [ ] `EntityAction` enum has all needed values

---

## Files Created

| File | Purpose |
|------|---------|
| `lib/presentation/features/screens/bloc/screen_event.dart` | Bloc events |
| `lib/presentation/features/screens/bloc/screen_state.dart` | Bloc state |
| `lib/presentation/features/screens/bloc/screen_bloc.dart` | Bloc shell |
| `lib/presentation/features/screens/bloc/bloc.dart` | Barrel export |

## Files Modified

| File | Change |
|------|--------|
| `lib/presentation/features/screens/screens.dart` | Add bloc export |

---

## Next Phase

Proceed to **Phase 5B: Unified ScreenBloc - Handlers** after validation passes.
