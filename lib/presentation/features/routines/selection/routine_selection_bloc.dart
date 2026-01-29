import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:taskly_bloc/presentation/features/routines/selection/routine_selection_models.dart';

sealed class RoutineSelectionEvent {
  const RoutineSelectionEvent();
}

final class RoutineSelectionVisibleEntitiesUpdated
    extends RoutineSelectionEvent {
  const RoutineSelectionVisibleEntitiesUpdated(this.entities);

  final List<RoutineSelectionMeta> entities;
}

final class RoutineSelectionExitRequested extends RoutineSelectionEvent {
  const RoutineSelectionExitRequested();
}

final class RoutineSelectionEnterRequested extends RoutineSelectionEvent {
  const RoutineSelectionEnterRequested({this.initialSelection});

  final RoutineSelectionKey? initialSelection;
}

final class RoutineSelectionToggleRequested extends RoutineSelectionEvent {
  const RoutineSelectionToggleRequested({
    required this.key,
    required this.extendRange,
  });

  final RoutineSelectionKey key;
  final bool extendRange;
}

final class RoutineSelectionEntityTapped extends RoutineSelectionEvent {
  const RoutineSelectionEntityTapped(this.key);

  final RoutineSelectionKey key;
}

class RoutineSelectionBloc
    extends Bloc<RoutineSelectionEvent, RoutineSelectionState> {
  RoutineSelectionBloc() : super(RoutineSelectionState.empty) {
    on<RoutineSelectionVisibleEntitiesUpdated>(_onVisibleEntitiesUpdated);
    on<RoutineSelectionExitRequested>(_onExitRequested);
    on<RoutineSelectionEnterRequested>(_onEnterRequested);
    on<RoutineSelectionToggleRequested>(_onToggleRequested);
    on<RoutineSelectionEntityTapped>(_onEntityTapped);
  }

  bool get isSelectionMode => state.isSelectionMode;

  void updateVisibleEntities(List<RoutineSelectionMeta> entities) {
    add(RoutineSelectionVisibleEntitiesUpdated(entities));
  }

  bool isSelected(RoutineSelectionKey key) => state.selected.contains(key);

  void exitSelectionMode() {
    add(const RoutineSelectionExitRequested());
  }

  void enterSelectionMode({RoutineSelectionKey? initialSelection}) {
    add(RoutineSelectionEnterRequested(initialSelection: initialSelection));
  }

  void toggleSelection(RoutineSelectionKey key, {required bool extendRange}) {
    add(RoutineSelectionToggleRequested(key: key, extendRange: extendRange));
  }

  ({bool isCtrlOrMetaPressed, bool isShiftPressed}) currentModifiers() {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;

    final isCtrlOrMeta =
        keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);

    final isShift =
        keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight);

    return (isCtrlOrMetaPressed: isCtrlOrMeta, isShiftPressed: isShift);
  }

  bool shouldInterceptTapAsSelection() {
    if (state.isSelectionMode) return true;

    final modifiers = currentModifiers();
    return modifiers.isCtrlOrMetaPressed;
  }

  void handleEntityTap(RoutineSelectionKey key) {
    add(RoutineSelectionEntityTapped(key));
  }

  List<RoutineSelectionMeta> selectedEntitiesMeta() {
    return state.selected
        .map((k) => state.metaByKey[k])
        .whereType<RoutineSelectionMeta>()
        .toList(growable: false);
  }

  void _onVisibleEntitiesUpdated(
    RoutineSelectionVisibleEntitiesUpdated event,
    Emitter<RoutineSelectionState> emit,
  ) {
    final order = event.entities.map((e) => e.key).toList(growable: false);

    final updatedMeta = Map<RoutineSelectionKey, RoutineSelectionMeta>.from(
      state.metaByKey,
    );
    for (final entity in event.entities) {
      updatedMeta[entity.key] = entity;
    }

    emit(
      state.copyWith(
        visibleOrder: order,
        metaByKey: updatedMeta,
      ),
    );
  }

  void _onExitRequested(
    RoutineSelectionExitRequested event,
    Emitter<RoutineSelectionState> emit,
  ) {
    emit(RoutineSelectionState.empty);
  }

  void _onEnterRequested(
    RoutineSelectionEnterRequested event,
    Emitter<RoutineSelectionState> emit,
  ) {
    if (state.isSelectionMode) return;

    final selected = <RoutineSelectionKey>{...state.selected};
    RoutineSelectionKey? anchor = state.anchor;

    if (event.initialSelection != null) {
      selected.add(event.initialSelection!);
      anchor = event.initialSelection;
    }

    emit(
      state.copyWith(
        isSelectionMode: true,
        selected: selected,
        anchor: anchor,
      ),
    );
  }

  void _onToggleRequested(
    RoutineSelectionToggleRequested event,
    Emitter<RoutineSelectionState> emit,
  ) {
    if (!state.isSelectionMode) {
      add(RoutineSelectionEnterRequested(initialSelection: event.key));
      return;
    }

    if (event.extendRange && state.anchor != null) {
      _selectRange(event.key, emit);
      return;
    }

    final selected = <RoutineSelectionKey>{...state.selected};
    if (selected.contains(event.key)) {
      selected.remove(event.key);
    } else {
      selected.add(event.key);
    }

    final nextAnchor = selected.isEmpty ? null : event.key;

    emit(state.copyWith(selected: selected, anchor: nextAnchor));

    if (selected.isEmpty) {
      add(const RoutineSelectionExitRequested());
    }
  }

  void _onEntityTapped(
    RoutineSelectionEntityTapped event,
    Emitter<RoutineSelectionState> emit,
  ) {
    final modifiers = currentModifiers();

    if (!state.isSelectionMode && modifiers.isCtrlOrMetaPressed) {
      add(RoutineSelectionEnterRequested(initialSelection: event.key));
      return;
    }

    if (!state.isSelectionMode) return;

    add(
      RoutineSelectionToggleRequested(
        key: event.key,
        extendRange: modifiers.isShiftPressed,
      ),
    );
  }

  void _selectRange(
    RoutineSelectionKey to,
    Emitter<RoutineSelectionState> emit,
  ) {
    final from = state.anchor;
    if (from == null) {
      add(RoutineSelectionToggleRequested(key: to, extendRange: false));
      return;
    }

    final order = state.visibleOrder;
    final fromIndex = order.indexOf(from);
    final toIndex = order.indexOf(to);

    if (fromIndex < 0 || toIndex < 0) {
      add(RoutineSelectionToggleRequested(key: to, extendRange: false));
      return;
    }

    final start = fromIndex < toIndex ? fromIndex : toIndex;
    final end = fromIndex < toIndex ? toIndex : fromIndex;

    final selected = <RoutineSelectionKey>{...state.selected};
    order.sublist(start, end + 1).forEach(selected.add);

    emit(state.copyWith(selected: selected, anchor: to));
  }
}
