import 'package:collection/collection.dart';
import 'package:taskly_domain/taskly_domain.dart';

/// Identifies an entity in selection mode.
class SelectionKey {
  const SelectionKey({required this.entityType, required this.entityId});

  final EntityType entityType;
  final String entityId;

  @override
  bool operator ==(Object other) {
    return other is SelectionKey &&
        other.entityType == entityType &&
        other.entityId == entityId;
  }

  @override
  int get hashCode => Object.hash(entityType, entityId);
}

class SelectionEntityMeta {
  const SelectionEntityMeta({
    required this.key,
    required this.displayName,
    required this.canDelete,
    this.completed,
    this.pinned,
    this.canCompleteSeries = false,
  });

  final SelectionKey key;
  final String displayName;
  final bool canDelete;
  final bool? completed;
  final bool? pinned;
  final bool canCompleteSeries;
}

enum BulkActionKind {
  complete,
  uncomplete,
  pin,
  unpin,
  completeSeries,
  moveToProject,
  delete,
}

class BulkActionAvailability {
  const BulkActionAvailability({required this.kind, required this.enabled});

  final BulkActionKind kind;
  final bool enabled;
}

class SelectionComputedActions {
  const SelectionComputedActions({
    required this.available,
  });

  final List<BulkActionAvailability> available;

  bool get hasAnyEnabled => available.any((a) => a.enabled);

  bool isEnabled(BulkActionKind kind) =>
      available.firstWhereOrNull((a) => a.kind == kind)?.enabled ?? false;

  Iterable<BulkActionKind> get enabledKinds =>
      available.where((a) => a.enabled).map((a) => a.kind);
}

class SelectionState {
  const SelectionState({
    required this.isSelectionMode,
    required this.selected,
    required this.visibleOrder,
    required this.metaByKey,
    required this.anchor,
  });

  final bool isSelectionMode;
  final Set<SelectionKey> selected;
  final List<SelectionKey> visibleOrder;
  final Map<SelectionKey, SelectionEntityMeta> metaByKey;
  final SelectionKey? anchor;

  int get selectedCount => selected.length;

  SelectionState copyWith({
    bool? isSelectionMode,
    Set<SelectionKey>? selected,
    List<SelectionKey>? visibleOrder,
    Map<SelectionKey, SelectionEntityMeta>? metaByKey,
    SelectionKey? anchor,
  }) {
    return SelectionState(
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selected: selected ?? this.selected,
      visibleOrder: visibleOrder ?? this.visibleOrder,
      metaByKey: metaByKey ?? this.metaByKey,
      anchor: anchor,
    );
  }

  static const SelectionState empty = SelectionState(
    isSelectionMode: false,
    selected: <SelectionKey>{},
    visibleOrder: <SelectionKey>[],
    metaByKey: <SelectionKey, SelectionEntityMeta>{},
    anchor: null,
  );
}
