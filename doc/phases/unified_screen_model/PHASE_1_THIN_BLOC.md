# Phase 1: Thin ScreenBloc

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each task. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Reuse**: Check existing patterns in codebase before creating new ones.
- **Imports**: Use absolute imports (`package:taskly_bloc/...`).

---

## Goal

Create the thin ScreenBloc that delegates all logic to domain services. The bloc becomes a simple state holder that connects the UI to `ScreenDataInterpreter`.

**Design Decisions Implemented**:
- D2: Service-driven + Thin Bloc (~80 LOC)
- D3: Keep ScreenDefinitionBloc separate (SRP)

---

## Prerequisites

- Phase 0 complete (`ScreenDataInterpreter`, `EntityActionService`, `ScreenData` exist)
- Existing `ScreenBloc` at `lib/presentation/features/screens/bloc/screen_bloc.dart` (will be replaced)

---

## Important: Freezed Syntax

**Codebase convention**:
- **`sealed class`** → for union types with multiple variants (events, states)
- **`abstract class`** → for single-variant data models

---

## Task 1.1: Create New ScreenEvent (Minimal)

**File**: `lib/presentation/features/screens/bloc/screen_event.dart`

Replace the existing file with a minimal event set. The bloc no longer handles entity actions directly.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';

part 'screen_event.freezed.dart';

/// Events for the thin ScreenBloc.
///
/// Note: Entity actions (complete, delete, etc.) are handled directly
/// by widgets via [EntityActionService], not through the bloc.
@freezed
sealed class ScreenEvent with _$ScreenEvent {
  /// Load screen by definition and start watching for changes.
  const factory ScreenEvent.load({
    required ScreenDefinition definition,
  }) = ScreenLoadEvent;

  /// Load screen by ID (fetches definition from repository first).
  const factory ScreenEvent.loadById({
    required String screenId,
  }) = ScreenLoadByIdEvent;

  /// Force refresh (re-fetch all data).
  const factory ScreenEvent.refresh() = ScreenRefreshEvent;

  /// Stop watching and reset to initial state.
  const factory ScreenEvent.reset() = ScreenResetEvent;
}
```

---

## Task 1.2: Create New ScreenState

**File**: `lib/presentation/features/screens/bloc/screen_state.dart`

Replace existing file. State now wraps `ScreenData` from the interpreter.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';

part 'screen_state.freezed.dart';

/// State for the thin ScreenBloc.
@freezed
sealed class ScreenState with _$ScreenState {
  /// Initial state before loading.
  const factory ScreenState.initial() = ScreenInitialState;

  /// Loading state while fetching screen data.
  const factory ScreenState.loading({
    ScreenDefinition? definition,
  }) = ScreenLoadingState;

  /// Loaded state with screen data from interpreter.
  const factory ScreenState.loaded({
    required ScreenData data,
    @Default(false) bool isRefreshing,
  }) = ScreenLoadedState;

  /// Error state.
  const factory ScreenState.error({
    required String message,
    ScreenDefinition? definition,
    Object? error,
    StackTrace? stackTrace,
  }) = ScreenErrorState;
}
```

---

## Task 1.3: Create New Thin ScreenBloc

**File**: `lib/presentation/features/screens/bloc/screen_bloc.dart`

Replace the existing heavy bloc (~400 LOC) with a thin delegate (~80 LOC).

```dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';

/// Thin bloc for screen rendering (DR-017).
///
/// This bloc is a simple state holder that delegates all logic to
/// [ScreenDataInterpreter]. It subscribes to the interpreter's stream
/// and emits state changes.
///
/// Entity actions (complete, delete, etc.) are NOT handled here.
/// Widgets call [EntityActionService] directly for mutations.
class ScreenBloc extends Bloc<ScreenEvent, ScreenState> {
  ScreenBloc({
    required ScreenDefinitionsRepositoryContract screenRepository,
    required ScreenDataInterpreter interpreter,
  }) : _screenRepository = screenRepository,
       _interpreter = interpreter,
       super(const ScreenState.initial()) {
    on<ScreenLoadEvent>(_onLoad);
    on<ScreenLoadByIdEvent>(_onLoadById);
    on<ScreenRefreshEvent>(_onRefresh);
    on<ScreenResetEvent>(_onReset);
  }

  final ScreenDefinitionsRepositoryContract _screenRepository;
  final ScreenDataInterpreter _interpreter;

  StreamSubscription<void>? _dataSubscription;
  ScreenDefinition? _currentDefinition;

  Future<void> _onLoad(
    ScreenLoadEvent event,
    Emitter<ScreenState> emit,
  ) async {
    talker.blocLog('ScreenBloc', 'load: ${event.definition.id}');

    _currentDefinition = event.definition;
    emit(ScreenState.loading(definition: event.definition));

    await _subscribeToData(event.definition, emit);
  }

  Future<void> _onLoadById(
    ScreenLoadByIdEvent event,
    Emitter<ScreenState> emit,
  ) async {
    talker.blocLog('ScreenBloc', 'loadById: ${event.screenId}');

    emit(const ScreenState.loading());

    try {
      final definition = await _screenRepository.getById(event.screenId);
      if (definition == null) {
        emit(ScreenState.error(
          message: 'Screen not found: ${event.screenId}',
        ));
        return;
      }

      _currentDefinition = definition;
      emit(ScreenState.loading(definition: definition));

      await _subscribeToData(definition, emit);
    } catch (e, st) {
      talker.handle(e, st, '[ScreenBloc] loadById failed');
      emit(ScreenState.error(
        message: 'Failed to load screen: $e',
        error: e,
        stackTrace: st,
      ));
    }
  }

  Future<void> _onRefresh(
    ScreenRefreshEvent event,
    Emitter<ScreenState> emit,
  ) async {
    talker.blocLog('ScreenBloc', 'refresh');

    final definition = _currentDefinition;
    if (definition == null) return;

    // Mark as refreshing
    final currentState = state;
    if (currentState is ScreenLoadedState) {
      emit(currentState.copyWith(isRefreshing: true));
    }

    // Re-subscribe to get fresh data
    await _subscribeToData(definition, emit);
  }

  Future<void> _onReset(
    ScreenResetEvent event,
    Emitter<ScreenState> emit,
  ) async {
    talker.blocLog('ScreenBloc', 'reset');

    await _dataSubscription?.cancel();
    _dataSubscription = null;
    _currentDefinition = null;

    emit(const ScreenState.initial());
  }

  Future<void> _subscribeToData(
    ScreenDefinition definition,
    Emitter<ScreenState> emit,
  ) async {
    // Cancel existing subscription
    await _dataSubscription?.cancel();

    // Subscribe to interpreter stream
    await emit.forEach(
      _interpreter.watchScreen(definition),
      onData: (data) {
        if (data.error != null) {
          return ScreenState.error(
            message: data.error!,
            definition: definition,
          );
        }
        return ScreenState.loaded(data: data);
      },
      onError: (error, stackTrace) {
        talker.handle(error, stackTrace, '[ScreenBloc] stream error');
        return ScreenState.error(
          message: 'Stream error: $error',
          definition: definition,
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _dataSubscription?.cancel();
    return super.close();
  }
}
```

---

## Task 1.4: Update Bloc Barrel Export

**File**: `lib/presentation/features/screens/bloc/bloc.dart`

Verify exports are correct:

```dart
export 'screen_bloc.dart';
export 'screen_definition_bloc.dart';
export 'screen_event.dart';
export 'screen_state.dart';
```

---

## Task 1.5: Verify ScreenDefinitionBloc Unchanged

**File**: `lib/presentation/features/screens/bloc/screen_definition_bloc.dart`

This bloc should remain unchanged per D3 (SRP). Verify it still exists and compiles.

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `screen_event.freezed.dart` regenerated
- [ ] `screen_state.freezed.dart` regenerated
- [ ] `ScreenBloc` compiles without errors
- [ ] `ScreenBloc` is ~80-100 LOC (not 400+)
- [ ] No entity action handlers in bloc
- [ ] `ScreenDefinitionBloc` still works

---

## Files Modified

| File | Change |
|------|--------|
| `lib/presentation/features/screens/bloc/screen_event.dart` | Replace with minimal events |
| `lib/presentation/features/screens/bloc/screen_state.dart` | Replace with ScreenData-based state |
| `lib/presentation/features/screens/bloc/screen_bloc.dart` | Replace with thin delegate |
| `lib/presentation/features/screens/bloc/bloc.dart` | Verify exports |

---

## Migration Note

The old `ScreenBloc` had these handlers that are now removed:
- `_onEntityAction` → Widgets call `EntityActionService` directly
- `_onNavigateToEntity` → Widgets use `EntityNavigator` directly
- `_onSupportBlockAction` → Handled by widget callbacks
- `_onRefreshSection` → Not needed with streams (auto-updates)

The old `SectionData` and `SupportBlockData` classes in state are replaced by `ScreenData` from the interpreter.

---

## Next Phase

Proceed to **Phase 2: UnifiedScreenPage** after validation passes.
