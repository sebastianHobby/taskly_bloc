import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_domain/analytics.dart';

class SelectionCubit extends Cubit<SelectionState> {
  SelectionCubit() : super(SelectionState.empty);

  bool get isSelectionMode => state.isSelectionMode;

  void updateVisibleEntities(List<SelectionEntityMeta> entities) {
    final order = entities.map((e) => e.key).toList(growable: false);

    final updatedMeta = Map<SelectionKey, SelectionEntityMeta>.from(
      state.metaByKey,
    );
    for (final entity in entities) {
      updatedMeta[entity.key] = entity;
    }

    emit(
      state.copyWith(
        visibleOrder: order,
        metaByKey: updatedMeta,
      ),
    );
  }

  bool isSelected(SelectionKey key) => state.selected.contains(key);

  void exitSelectionMode() {
    emit(SelectionState.empty);
  }

  void enterSelectionMode({SelectionKey? initialSelection}) {
    if (state.isSelectionMode) return;

    final selected = <SelectionKey>{...state.selected};
    SelectionKey? anchor = state.anchor;

    if (initialSelection != null) {
      selected.add(initialSelection);
      anchor = initialSelection;
    }

    emit(
      state.copyWith(
        isSelectionMode: true,
        selected: selected,
        anchor: anchor,
      ),
    );
  }

  void toggleSelection(SelectionKey key, {required bool extendRange}) {
    if (!state.isSelectionMode) {
      enterSelectionMode(initialSelection: key);
      return;
    }

    if (extendRange && state.anchor != null) {
      _selectRange(state.anchor!, key);
      return;
    }

    final selected = <SelectionKey>{...state.selected};
    if (selected.contains(key)) {
      selected.remove(key);
    } else {
      selected.add(key);
    }

    final nextAnchor = selected.isEmpty ? null : key;

    emit(state.copyWith(selected: selected, anchor: nextAnchor));

    if (selected.isEmpty) {
      exitSelectionMode();
    }
  }

  void _selectRange(SelectionKey from, SelectionKey to) {
    final order = state.visibleOrder;
    final fromIndex = order.indexOf(from);
    final toIndex = order.indexOf(to);

    if (fromIndex < 0 || toIndex < 0) {
      toggleSelection(to, extendRange: false);
      return;
    }

    final start = fromIndex < toIndex ? fromIndex : toIndex;
    final end = fromIndex < toIndex ? toIndex : fromIndex;

    final selected = <SelectionKey>{...state.selected};
    order.sublist(start, end + 1).forEach(selected.add);

    emit(state.copyWith(selected: selected, anchor: to));
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
    final modifiers = currentModifiers();

    if (!state.isSelectionMode && modifiers.isCtrlOrMetaPressed) {
      enterSelectionMode(initialSelection: key);
      return;
    }

    if (!state.isSelectionMode) return;

    toggleSelection(key, extendRange: modifiers.isShiftPressed);
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

    final canPin = !onlyDelete && anyWhere((m) => m.pinned == false);
    final canUnpin = !onlyDelete && anyWhere((m) => m.pinned ?? false);

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
      BulkActionAvailability(kind: BulkActionKind.pin, enabled: canPin),
      BulkActionAvailability(kind: BulkActionKind.unpin, enabled: canUnpin),
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
}
