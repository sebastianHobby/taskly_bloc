import 'dart:async';

import 'package:flutter/services.dart';
import 'package:bloc/bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_domain/analytics.dart';

sealed class SelectionEvent {
  const SelectionEvent();
}

final class SelectionVisibleEntitiesUpdated extends SelectionEvent {
  const SelectionVisibleEntitiesUpdated(this.entities);

  final List<SelectionEntityMeta> entities;
}

final class SelectionExitRequested extends SelectionEvent {
  const SelectionExitRequested();
}

final class SelectionEnterRequested extends SelectionEvent {
  const SelectionEnterRequested({this.initialSelection});

  final SelectionKey? initialSelection;
}

final class SelectionToggleRequested extends SelectionEvent {
  const SelectionToggleRequested({
    required this.key,
    required this.extendRange,
  });

  final SelectionKey key;
  final bool extendRange;
}

final class SelectionEntityTapped extends SelectionEvent {
  const SelectionEntityTapped(this.key);

  final SelectionKey key;
}

class SelectionBloc extends Bloc<SelectionEvent, SelectionState> {
  SelectionBloc() : super(SelectionState.empty) {
    on<SelectionVisibleEntitiesUpdated>(_onVisibleEntitiesUpdated);
    on<SelectionExitRequested>(_onExitRequested);
    on<SelectionEnterRequested>(_onEnterRequested);
    on<SelectionToggleRequested>(_onToggleRequested);
    on<SelectionEntityTapped>(_onEntityTapped);
  }

  bool get isSelectionMode => state.isSelectionMode;

  void updateVisibleEntities(List<SelectionEntityMeta> entities) {
    add(SelectionVisibleEntitiesUpdated(entities));
  }

  bool isSelected(SelectionKey key) => state.selected.contains(key);

  void exitSelectionMode() {
    add(const SelectionExitRequested());
  }

  void enterSelectionMode({SelectionKey? initialSelection}) {
    add(SelectionEnterRequested(initialSelection: initialSelection));
  }

  void toggleSelection(SelectionKey key, {required bool extendRange}) {
    add(SelectionToggleRequested(key: key, extendRange: extendRange));
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

  void handleEntityTap(SelectionKey key) {
    add(SelectionEntityTapped(key));
  }

  SelectionComputedActions computeActions() {
    final selectedKeys = state.selected;
    final selectedTypes = selectedKeys.map((k) => k.entityType).toSet();

    final includesValue = selectedTypes.contains(EntityType.value);
    final includesNonValue =
        selectedTypes.contains(EntityType.task) ||
        selectedTypes.contains(EntityType.project);

    final onlyDelete = includesValue && includesNonValue;

    bool anyWhere(bool Function(SelectionEntityMeta meta) test) {
      for (final key in selectedKeys) {
        final meta = state.metaByKey[key];
        if (meta != null && test(meta)) return true;
      }
      return false;
    }

    final canDelete = selectedKeys.isNotEmpty;

    final canComplete = !onlyDelete && anyWhere((m) => m.completed == false);
    final canUncomplete = !onlyDelete && anyWhere((m) => m.completed ?? false);

    final canCompleteSeries =
        !onlyDelete && anyWhere((m) => m.canCompleteSeries);

    final tasksOnly =
        selectedTypes.length == 1 &&
        selectedTypes.contains(EntityType.task) &&
        selectedKeys.isNotEmpty;

    final canMoveToProject = !onlyDelete && tasksOnly;

    final available = <BulkActionAvailability>[
      BulkActionAvailability(
        kind: BulkActionKind.complete,
        enabled: canComplete,
      ),
      BulkActionAvailability(
        kind: BulkActionKind.uncomplete,
        enabled: canUncomplete,
      ),
      BulkActionAvailability(
        kind: BulkActionKind.completeSeries,
        enabled: canCompleteSeries,
      ),
      BulkActionAvailability(
        kind: BulkActionKind.moveToProject,
        enabled: canMoveToProject,
      ),
      BulkActionAvailability(kind: BulkActionKind.delete, enabled: canDelete),
    ];

    return SelectionComputedActions(available: available);
  }

  List<SelectionEntityMeta> selectedEntitiesMeta() {
    return state.selected
        .map((k) => state.metaByKey[k])
        .whereType<SelectionEntityMeta>()
        .toList(growable: false);
  }

  Future<void> runSequential(
    Future<void> Function(SelectionKey key) action,
  ) async {
    for (final key in state.selected) {
      await action(key);
    }
  }

  void _onVisibleEntitiesUpdated(
    SelectionVisibleEntitiesUpdated event,
    Emitter<SelectionState> emit,
  ) {
    final order = event.entities.map((e) => e.key).toList(growable: false);

    final updatedMeta = Map<SelectionKey, SelectionEntityMeta>.from(
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
    SelectionExitRequested event,
    Emitter<SelectionState> emit,
  ) {
    emit(SelectionState.empty);
  }

  void _onEnterRequested(
    SelectionEnterRequested event,
    Emitter<SelectionState> emit,
  ) {
    if (state.isSelectionMode) return;

    final selected = <SelectionKey>{...state.selected};
    SelectionKey? anchor = state.anchor;

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
    SelectionToggleRequested event,
    Emitter<SelectionState> emit,
  ) {
    if (!state.isSelectionMode) {
      add(SelectionEnterRequested(initialSelection: event.key));
      return;
    }

    if (event.extendRange && state.anchor != null) {
      _selectRange(event.key, emit);
      return;
    }

    final selected = <SelectionKey>{...state.selected};
    if (selected.contains(event.key)) {
      selected.remove(event.key);
    } else {
      selected.add(event.key);
    }

    final nextAnchor = selected.isEmpty ? null : event.key;

    emit(state.copyWith(selected: selected, anchor: nextAnchor));

    if (selected.isEmpty) {
      add(const SelectionExitRequested());
    }
  }

  void _onEntityTapped(
    SelectionEntityTapped event,
    Emitter<SelectionState> emit,
  ) {
    final modifiers = currentModifiers();

    if (!state.isSelectionMode && modifiers.isCtrlOrMetaPressed) {
      add(SelectionEnterRequested(initialSelection: event.key));
      return;
    }

    if (!state.isSelectionMode) return;

    add(
      SelectionToggleRequested(
        key: event.key,
        extendRange: modifiers.isShiftPressed,
      ),
    );
  }

  void _selectRange(SelectionKey to, Emitter<SelectionState> emit) {
    final from = state.anchor;
    if (from == null) {
      add(SelectionToggleRequested(key: to, extendRange: false));
      return;
    }

    final order = state.visibleOrder;
    final fromIndex = order.indexOf(from);
    final toIndex = order.indexOf(to);

    if (fromIndex < 0 || toIndex < 0) {
      add(SelectionToggleRequested(key: to, extendRange: false));
      return;
    }

    final start = fromIndex < toIndex ? fromIndex : toIndex;
    final end = fromIndex < toIndex ? toIndex : fromIndex;

    final selected = <SelectionKey>{...state.selected};
    order.sublist(start, end + 1).forEach(selected.add);

    emit(state.copyWith(selected: selected, anchor: to));
  }
}
