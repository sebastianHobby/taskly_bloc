import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_repository_contract.dart'
    as attention_repo_v2;
import 'package:taskly_bloc/domain/attention/model/attention_item.dart';
import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';
import 'package:taskly_bloc/domain/attention/query/attention_query.dart';
import 'package:uuid/uuid.dart';

part 'attention_inbox_bloc.freezed.dart';

@freezed
sealed class AttentionInboxEvent with _$AttentionInboxEvent {
  const factory AttentionInboxEvent.subscriptionRequested() =
      AttentionInboxSubscriptionRequested;

  const factory AttentionInboxEvent.itemsUpdated({
    required List<AttentionItem> items,
  }) = _AttentionInboxItemsUpdated;

  const factory AttentionInboxEvent.watchFailed({
    required Object error,
    required StackTrace stackTrace,
  }) = _AttentionInboxWatchFailed;

  const factory AttentionInboxEvent.bucketChanged({
    required AttentionBucket bucket,
  }) = AttentionInboxBucketChanged;

  const factory AttentionInboxEvent.groupByChanged({
    required AttentionInboxGroupBy groupBy,
  }) = AttentionInboxGroupByChanged;

  const factory AttentionInboxEvent.sortChanged({
    required AttentionInboxSort sort,
  }) = AttentionInboxSortChanged;

  const factory AttentionInboxEvent.minSeverityChanged({
    required AttentionSeverity? minSeverity,
  }) = AttentionInboxMinSeverityChanged;

  const factory AttentionInboxEvent.searchQueryChanged({
    required String query,
  }) = AttentionInboxSearchQueryChanged;

  const factory AttentionInboxEvent.entityTypeToggled({
    required AttentionEntityType entityType,
  }) = AttentionInboxEntityTypeToggled;

  const factory AttentionInboxEvent.toggleSelected({
    required String itemKey,
  }) = AttentionInboxToggleSelected;

  const factory AttentionInboxEvent.clearSelection() =
      AttentionInboxClearSelection;

  const factory AttentionInboxEvent.applyActionToSelection({
    required AttentionResolutionAction action,
  }) = AttentionInboxApplyActionToSelection;

  const factory AttentionInboxEvent.applyActionToItem({
    required String itemKey,
    required AttentionResolutionAction action,
  }) = AttentionInboxApplyActionToItem;

  /// Applies the action to all visible (filtered) items in the current bucket.
  const factory AttentionInboxEvent.applyActionToVisible({
    required AttentionResolutionAction action,
  }) = AttentionInboxApplyActionToVisible;

  /// Internal: commit a pending batch after the undo window elapsed.
  const factory AttentionInboxEvent.commitPending({
    required String undoId,
  }) = AttentionInboxCommitPending;

  const factory AttentionInboxEvent.undoRequested({
    required String undoId,
  }) = AttentionInboxUndoRequested;
}

enum AttentionInboxSort {
  detectedAtDesc,
  severityDesc,
  titleAsc,
}

enum AttentionInboxGroupBy {
  none,
  severity,
  entityType,
  rule,
}

@freezed
sealed class AttentionInboxViewConfig with _$AttentionInboxViewConfig {
  const factory AttentionInboxViewConfig({
    required AttentionBucket bucket,
    required AttentionInboxSort sort,
    required AttentionInboxGroupBy groupBy,
    required AttentionSeverity? minSeverity,
    required Set<AttentionEntityType> entityTypeFilter,
    required String searchQuery,
  }) = _AttentionInboxViewConfig;

  factory AttentionInboxViewConfig.defaults() => const AttentionInboxViewConfig(
    bucket: AttentionBucket.action,
    sort: AttentionInboxSort.detectedAtDesc,
    groupBy: AttentionInboxGroupBy.none,
    minSeverity: null,
    entityTypeFilter: <AttentionEntityType>{},
    searchQuery: '',
  );
}

@freezed
sealed class AttentionInboxState with _$AttentionInboxState {
  const factory AttentionInboxState.loading({
    required AttentionInboxViewConfig viewConfig,
  }) = AttentionInboxLoading;

  const factory AttentionInboxState.loaded({
    required AttentionInboxViewConfig viewConfig,
    required List<AttentionInboxGroupVm> groups,
    required int totalVisibleCount,
    required Set<String> selectedKeys,
    required AttentionInboxPendingUndo? pendingUndo,
    required String? errorMessage,
  }) = AttentionInboxLoaded;

  const factory AttentionInboxState.error({
    required AttentionInboxViewConfig viewConfig,
    required String message,
  }) = AttentionInboxError;
}

@freezed
sealed class AttentionInboxGroupVm with _$AttentionInboxGroupVm {
  const factory AttentionInboxGroupVm({
    required String title,
    required List<AttentionInboxItemVm> items,
  }) = _AttentionInboxGroupVm;
}

@freezed
sealed class AttentionInboxItemVm with _$AttentionInboxItemVm {
  const factory AttentionInboxItemVm({
    required String key,
    required AttentionItem item,
    required bool selected,
  }) = _AttentionInboxItemVm;
}

@freezed
sealed class AttentionInboxPendingUndo with _$AttentionInboxPendingUndo {
  const factory AttentionInboxPendingUndo({
    required String undoId,
    required AttentionResolutionAction action,
    required int count,
  }) = _AttentionInboxPendingUndo;
}

class AttentionInboxBloc
    extends Bloc<AttentionInboxEvent, AttentionInboxState> {
  AttentionInboxBloc({
    required AttentionEngineContract engine,
    required attention_repo_v2.AttentionRepositoryContract repository,
    required IdGenerator idGenerator,
    Duration undoWindow = const Duration(seconds: 5),
  }) : _engine = engine,
       _repository = repository,
       _idGenerator = idGenerator,
       _undoWindow = undoWindow,
       super(
         AttentionInboxState.loading(
           viewConfig: AttentionInboxViewConfig.defaults(),
         ),
       ) {
    on<AttentionInboxSubscriptionRequested>(_onSubscriptionRequested);
    on<_AttentionInboxItemsUpdated>(_onItemsUpdated);
    on<_AttentionInboxWatchFailed>(_onWatchFailed);
    on<AttentionInboxBucketChanged>(_onBucketChanged);
    on<AttentionInboxGroupByChanged>(_onGroupByChanged);
    on<AttentionInboxSortChanged>(_onSortChanged);
    on<AttentionInboxMinSeverityChanged>(_onMinSeverityChanged);
    on<AttentionInboxSearchQueryChanged>(_onSearchQueryChanged);
    on<AttentionInboxEntityTypeToggled>(_onEntityTypeToggled);
    on<AttentionInboxToggleSelected>(_onToggleSelected);
    on<AttentionInboxClearSelection>(_onClearSelection);
    on<AttentionInboxApplyActionToSelection>(_onApplyActionToSelection);
    on<AttentionInboxApplyActionToItem>(_onApplyActionToItem);
    on<AttentionInboxApplyActionToVisible>(_onApplyActionToVisible);
    on<AttentionInboxCommitPending>(_onCommitPending);
    on<AttentionInboxUndoRequested>(_onUndoRequested);

    add(const AttentionInboxEvent.subscriptionRequested());
  }

  final AttentionEngineContract _engine;
  final attention_repo_v2.AttentionRepositoryContract _repository;
  final IdGenerator _idGenerator;
  final Duration _undoWindow;

  final _uuid = const Uuid();

  StreamSubscription<List<AttentionItem>>? _sub;

  var _viewConfig = AttentionInboxViewConfig.defaults();
  var _itemsByBucket = <AttentionBucket, List<AttentionItem>>{
    AttentionBucket.action: const <AttentionItem>[],
    AttentionBucket.review: const <AttentionItem>[],
  };

  /// Optimistic local hides to support undo.
  final Set<String> _hiddenKeys = <String>{};

  /// Selection for batching.
  final Set<String> _selectedKeys = <String>{};

  Timer? _pendingCommitTimer;
  _PendingCommit? _pendingCommit;

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    _pendingCommitTimer?.cancel();
    _pendingCommitTimer = null;
    _pendingCommit = null;
    return super.close();
  }

  Future<void> _onSubscriptionRequested(
    AttentionInboxSubscriptionRequested event,
    Emitter<AttentionInboxState> emit,
  ) async {
    emit(AttentionInboxState.loading(viewConfig: _viewConfig));

    await _sub?.cancel();
    _sub = null;

    final items$ = _engine
        .watch(
          const AttentionQuery(
            buckets: {AttentionBucket.action, AttentionBucket.review},
          ),
        )
        .startWith(const <AttentionItem>[]);

    _sub = items$.listen(
      (items) {
        add(AttentionInboxEvent.itemsUpdated(items: items));
      },
      onError: (Object e, StackTrace s) {
        add(AttentionInboxEvent.watchFailed(error: e, stackTrace: s));
      },
    );
  }

  void _onItemsUpdated(
    _AttentionInboxItemsUpdated event,
    Emitter<AttentionInboxState> emit,
  ) {
    final action = <AttentionItem>[];
    final review = <AttentionItem>[];

    for (final item in event.items) {
      switch (item.bucket) {
        case AttentionBucket.action:
          action.add(item);
        case AttentionBucket.review:
          review.add(item);
      }
    }

    _itemsByBucket = {
      AttentionBucket.action: action,
      AttentionBucket.review: review,
    };

    _pruneHiddenKeys();
    _selectedKeys.removeWhere((k) => !_currentAllKeys().contains(k));

    emit(_buildLoadedState());
  }

  void _onWatchFailed(
    _AttentionInboxWatchFailed event,
    Emitter<AttentionInboxState> emit,
  ) {
    emit(
      AttentionInboxState.error(
        viewConfig: _viewConfig,
        message: 'Failed to load attention: ${event.error}',
      ),
    );
  }

  void _onBucketChanged(
    AttentionInboxBucketChanged event,
    Emitter<AttentionInboxState> emit,
  ) {
    _viewConfig = _viewConfig.copyWith(bucket: event.bucket);
    _selectedKeys.clear();
    emit(_buildLoadedState());
  }

  void _onGroupByChanged(
    AttentionInboxGroupByChanged event,
    Emitter<AttentionInboxState> emit,
  ) {
    _viewConfig = _viewConfig.copyWith(groupBy: event.groupBy);
    emit(_buildLoadedState());
  }

  void _onSortChanged(
    AttentionInboxSortChanged event,
    Emitter<AttentionInboxState> emit,
  ) {
    _viewConfig = _viewConfig.copyWith(sort: event.sort);
    emit(_buildLoadedState());
  }

  void _onMinSeverityChanged(
    AttentionInboxMinSeverityChanged event,
    Emitter<AttentionInboxState> emit,
  ) {
    _viewConfig = _viewConfig.copyWith(minSeverity: event.minSeverity);
    emit(_buildLoadedState());
  }

  void _onSearchQueryChanged(
    AttentionInboxSearchQueryChanged event,
    Emitter<AttentionInboxState> emit,
  ) {
    _viewConfig = _viewConfig.copyWith(searchQuery: event.query);
    emit(_buildLoadedState());
  }

  void _onEntityTypeToggled(
    AttentionInboxEntityTypeToggled event,
    Emitter<AttentionInboxState> emit,
  ) {
    final next = {..._viewConfig.entityTypeFilter};
    if (next.contains(event.entityType)) {
      next.remove(event.entityType);
    } else {
      next.add(event.entityType);
    }

    _viewConfig = _viewConfig.copyWith(entityTypeFilter: next);
    emit(_buildLoadedState());
  }

  void _onToggleSelected(
    AttentionInboxToggleSelected event,
    Emitter<AttentionInboxState> emit,
  ) {
    if (_selectedKeys.contains(event.itemKey)) {
      _selectedKeys.remove(event.itemKey);
    } else {
      _selectedKeys.add(event.itemKey);
    }
    emit(_buildLoadedState());
  }

  void _onClearSelection(
    AttentionInboxClearSelection event,
    Emitter<AttentionInboxState> emit,
  ) {
    _selectedKeys.clear();
    emit(_buildLoadedState());
  }

  Future<void> _onApplyActionToSelection(
    AttentionInboxApplyActionToSelection event,
    Emitter<AttentionInboxState> emit,
  ) async {
    final keys = _selectedKeys.toList(growable: false);
    await _applyAction(emit, action: event.action, keys: keys);
  }

  Future<void> _onApplyActionToItem(
    AttentionInboxApplyActionToItem event,
    Emitter<AttentionInboxState> emit,
  ) async {
    await _applyAction(emit, action: event.action, keys: [event.itemKey]);
  }

  Future<void> _onApplyActionToVisible(
    AttentionInboxApplyActionToVisible event,
    Emitter<AttentionInboxState> emit,
  ) async {
    final keys = _currentVisibleKeys().toList(growable: false);
    await _applyAction(emit, action: event.action, keys: keys);
  }

  void _onUndoRequested(
    AttentionInboxUndoRequested event,
    Emitter<AttentionInboxState> emit,
  ) {
    final pending = _pendingCommit;
    if (pending == null || pending.undoId != event.undoId) return;

    _pendingCommitTimer?.cancel();
    _pendingCommitTimer = null;
    _pendingCommit = null;

    _hiddenKeys.removeAll(pending.keys);
    emit(_buildLoadedState(clearUndo: true));
  }

  Future<void> _onCommitPending(
    AttentionInboxCommitPending event,
    Emitter<AttentionInboxState> emit,
  ) async {
    final pending = _pendingCommit;
    if (pending == null || pending.undoId != event.undoId) return;

    final error = await _flushPendingCommit();
    emit(_buildLoadedState(clearUndo: true, errorMessage: error));
  }

  Future<void> _applyAction(
    Emitter<AttentionInboxState> emit, {
    required AttentionResolutionAction action,
    required List<String> keys,
  }) async {
    if (keys.isEmpty) return;

    // Only support one pending undo window at a time for now.
    // If a new action happens, commit the previous immediately.
    final previousError = await _flushPendingCommit();
    if (previousError != null) {
      emit(_buildLoadedState(clearUndo: true, errorMessage: previousError));
    }

    final items = _itemsForKeys(keys);
    if (items.isEmpty) return;

    final undoId = _uuid.v4();
    final commit = _PendingCommit(
      undoId: undoId,
      action: action,
      items: items,
      keys: items.map(_itemKey).toSet(),
    );

    _pendingCommit = commit;
    _pendingCommitTimer?.cancel();
    _pendingCommitTimer = Timer(
      _undoWindow,
      () {
        if (isClosed) return;
        add(AttentionInboxEvent.commitPending(undoId: undoId));
      },
    );

    _hiddenKeys.addAll(commit.keys);
    _selectedKeys.removeWhere(commit.keys.contains);

    emit(
      _buildLoadedState(
        pendingUndo: AttentionInboxPendingUndo(
          undoId: undoId,
          action: action,
          count: commit.keys.length,
        ),
      ),
    );
  }

  Future<String?> _flushPendingCommit() async {
    final pending = _pendingCommit;
    if (pending == null) return null;

    _pendingCommitTimer?.cancel();
    _pendingCommitTimer = null;
    _pendingCommit = null;

    try {
      for (final item in pending.items) {
        final now = DateTime.now();

        final details = switch (pending.action) {
          AttentionResolutionAction.snoozed => <String, dynamic>{
            'snooze_until': now
                .toUtc()
                .add(const Duration(days: 1))
                .toIso8601String(),
          },
          AttentionResolutionAction.dismissed => _dismissDetails(item),
          AttentionResolutionAction.reviewed ||
          AttentionResolutionAction.skipped => null,
        };

        // If dismiss isn't possible, skip it rather than failing the batch.
        if (pending.action == AttentionResolutionAction.dismissed &&
            details == null) {
          continue;
        }

        final resolution = AttentionResolution(
          id: _idGenerator.attentionResolutionId(),
          ruleId: item.ruleId,
          entityId: item.entityId,
          entityType: item.entityType,
          resolvedAt: now,
          createdAt: now,
          resolutionAction: pending.action,
          actionDetails: details,
        );

        await _repository.recordResolution(resolution);
      }
      return null;
    } catch (e) {
      // On failure, unhide so the user can try again.
      _hiddenKeys.removeAll(pending.keys);
      return 'Failed to record action(s): $e';
    }
  }

  Map<String, dynamic>? _dismissDetails(AttentionItem item) {
    final raw = item.metadata?['state_hash'];
    if (raw is! String || raw.isEmpty) return null;
    return <String, dynamic>{'state_hash': raw};
  }

  AttentionInboxState _buildLoadedState({
    AttentionInboxPendingUndo? pendingUndo,
    bool clearUndo = false,
    String? errorMessage,
  }) {
    final currentBucketItems =
        _itemsByBucket[_viewConfig.bucket] ?? const <AttentionItem>[];

    final visible = currentBucketItems
        .where((i) => !_hiddenKeys.contains(_itemKey(i)))
        .where(_matchesFilters)
        .toList(growable: false);

    final sorted = [...visible]..sort(_compare);

    final grouped = _group(sorted);

    final vms = grouped
        .map(
          (g) => AttentionInboxGroupVm(
            title: g.title,
            items: g.items
                .map(
                  (i) => AttentionInboxItemVm(
                    key: _itemKey(i),
                    item: i,
                    selected: _selectedKeys.contains(_itemKey(i)),
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

    final existingUndo = state.maybeWhen(
      loaded: (_, __, ___, ____, pendingUndo, _____) => pendingUndo,
      orElse: () => null,
    );

    final resolvedUndo = clearUndo ? null : pendingUndo ?? existingUndo;

    return AttentionInboxState.loaded(
      viewConfig: _viewConfig,
      groups: vms,
      totalVisibleCount: visible.length,
      selectedKeys: {..._selectedKeys},
      pendingUndo: resolvedUndo,
      errorMessage: errorMessage,
    );
  }

  bool _matchesFilters(AttentionItem item) {
    final minSeverity = _viewConfig.minSeverity;
    if (minSeverity != null &&
        _severityIndex(item.severity) < _severityIndex(minSeverity)) {
      return false;
    }

    final entityTypes = _viewConfig.entityTypeFilter;
    if (entityTypes.isNotEmpty && !entityTypes.contains(item.entityType)) {
      return false;
    }

    final q = _viewConfig.searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      final hay = '${item.title}\n${item.description}'.toLowerCase();
      if (!hay.contains(q)) return false;
    }

    return true;
  }

  int _severityIndex(AttentionSeverity s) {
    return switch (s) {
      AttentionSeverity.info => 0,
      AttentionSeverity.warning => 1,
      AttentionSeverity.critical => 2,
    };
  }

  int _compare(AttentionItem a, AttentionItem b) {
    return switch (_viewConfig.sort) {
      AttentionInboxSort.detectedAtDesc => b.detectedAt.compareTo(a.detectedAt),
      AttentionInboxSort.severityDesc => _severityIndex(
        b.severity,
      ).compareTo(_severityIndex(a.severity)),
      AttentionInboxSort.titleAsc => a.title.toLowerCase().compareTo(
        b.title.toLowerCase(),
      ),
    };
  }

  List<_Group> _group(List<AttentionItem> items) {
    final groupBy = _viewConfig.groupBy;
    if (groupBy == AttentionInboxGroupBy.none) {
      return [
        _Group(title: '', items: items),
      ];
    }

    final Map<String, List<AttentionItem>> by = {};

    String keyFor(AttentionItem i) {
      return switch (groupBy) {
        AttentionInboxGroupBy.severity => i.severity.name,
        AttentionInboxGroupBy.entityType => i.entityType.name,
        AttentionInboxGroupBy.rule => i.ruleKey,
        AttentionInboxGroupBy.none => '',
      };
    }

    for (final i in items) {
      (by[keyFor(i)] ??= []).add(i);
    }

    final keys = by.keys.toList()..sort();

    return [
      for (final k in keys)
        _Group(title: _titleForGroup(groupBy, k), items: by[k]!),
    ];
  }

  String _titleForGroup(AttentionInboxGroupBy groupBy, String rawKey) {
    return switch (groupBy) {
      AttentionInboxGroupBy.severity => rawKey.toUpperCase(),
      AttentionInboxGroupBy.entityType => rawKey,
      AttentionInboxGroupBy.rule => rawKey,
      AttentionInboxGroupBy.none => '',
    };
  }

  String _itemKey(AttentionItem item) => '${item.ruleId}::${item.entityId}';

  Set<String> _currentAllKeys() {
    final all = <String>{};
    for (final bucket in AttentionBucket.values) {
      final items = _itemsByBucket[bucket] ?? const <AttentionItem>[];
      for (final item in items) {
        all.add(_itemKey(item));
      }
    }
    return all;
  }

  Set<String> _currentVisibleKeys() {
    final items = _itemsByBucket[_viewConfig.bucket] ?? const <AttentionItem>[];
    return items
        .where((i) => !_hiddenKeys.contains(_itemKey(i)))
        .where(_matchesFilters)
        .map(_itemKey)
        .toSet();
  }

  List<AttentionItem> _itemsForKeys(List<String> keys) {
    final keySet = keys.toSet();

    final items = _itemsByBucket[_viewConfig.bucket] ?? const <AttentionItem>[];
    final result = <AttentionItem>[];
    for (final item in items) {
      final k = _itemKey(item);
      if (keySet.contains(k) && !_hiddenKeys.contains(k)) {
        result.add(item);
      }
    }
    return result;
  }

  void _pruneHiddenKeys() {
    // Keep hides while an undo is pending.
    final pendingKeys = _pendingCommit?.keys ?? const <String>{};

    final allKeys = _currentAllKeys();
    _hiddenKeys.removeWhere(
      (k) => !pendingKeys.contains(k) && !allKeys.contains(k),
    );
  }
}

class _Group {
  const _Group({required this.title, required this.items});

  final String title;
  final List<AttentionItem> items;
}

class _PendingCommit {
  const _PendingCommit({
    required this.undoId,
    required this.action,
    required this.items,
    required this.keys,
  });

  final String undoId;
  final AttentionResolutionAction action;
  final List<AttentionItem> items;
  final Set<String> keys;
}
