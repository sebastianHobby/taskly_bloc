import 'package:flutter/foundation.dart';

@immutable
final class RoutineSelectionKey {
  const RoutineSelectionKey(this.routineId);

  final String routineId;

  @override
  bool operator ==(Object other) {
    return other is RoutineSelectionKey && other.routineId == routineId;
  }

  @override
  int get hashCode => routineId.hashCode;
}

@immutable
final class RoutineSelectionMeta {
  const RoutineSelectionMeta({
    required this.key,
    required this.displayName,
    required this.completedToday,
    required this.isActive,
  });

  final RoutineSelectionKey key;
  final String displayName;
  final bool completedToday;
  final bool isActive;
}

@immutable
final class RoutineSelectionState {
  const RoutineSelectionState({
    required this.isSelectionMode,
    required this.selected,
    required this.visibleOrder,
    required this.metaByKey,
    this.anchor,
  });

  final bool isSelectionMode;
  final Set<RoutineSelectionKey> selected;
  final List<RoutineSelectionKey> visibleOrder;
  final Map<RoutineSelectionKey, RoutineSelectionMeta> metaByKey;
  final RoutineSelectionKey? anchor;

  int get selectedCount => selected.length;

  RoutineSelectionState copyWith({
    bool? isSelectionMode,
    Set<RoutineSelectionKey>? selected,
    List<RoutineSelectionKey>? visibleOrder,
    Map<RoutineSelectionKey, RoutineSelectionMeta>? metaByKey,
    RoutineSelectionKey? anchor,
  }) {
    return RoutineSelectionState(
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selected: selected ?? this.selected,
      visibleOrder: visibleOrder ?? this.visibleOrder,
      metaByKey: metaByKey ?? this.metaByKey,
      anchor: anchor ?? this.anchor,
    );
  }

  static const RoutineSelectionState empty = RoutineSelectionState(
    isSelectionMode: false,
    selected: <RoutineSelectionKey>{},
    visibleOrder: <RoutineSelectionKey>[],
    metaByKey: <RoutineSelectionKey, RoutineSelectionMeta>{},
  );
}
