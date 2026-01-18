import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
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

  const factory AttentionInboxEvent.bucketFilterToggled({
    required AttentionBucket bucket,
  }) = AttentionInboxBucketFilterToggled;

  const factory AttentionInboxEvent.bucketFilterSet({
    required Set<AttentionBucket> buckets,
  }) = AttentionInboxBucketFilterSet;

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

  const factory AttentionInboxEvent.applyActionToMany({
    required List<String> itemKeys,
    required AttentionResolutionAction action,
  }) = AttentionInboxApplyActionToMany;

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
    required Set<AttentionBucket> bucketFilter,
    required AttentionInboxSort sort,
    required AttentionInboxGroupBy groupBy,
    required AttentionSeverity? minSeverity,
    required Set<AttentionEntityType> entityTypeFilter,
    required String searchQuery,
  }) = _AttentionInboxViewConfig;

  factory AttentionInboxViewConfig.defaults() => const AttentionInboxViewConfig(
    bucket: AttentionBucket.action,
    bucketFilter: <AttentionBucket>{
      AttentionBucket.action,
      AttentionBucket.review,
    },
    sort: AttentionInboxSort.detectedAtDesc,
    groupBy: AttentionInboxGroupBy.severity,
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
    required int actionVisibleCount,
    required int reviewVisibleCount,
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
    required List<AttentionInboxEntityVm> entities,
  }) = _AttentionInboxGroupVm;
}

@freezed
sealed class AttentionInboxEntityVm with _$AttentionInboxEntityVm {
  const factory AttentionInboxEntityVm({
    required String entityKey,
    required AttentionEntityType entityType,
    required String entityId,
    required AttentionSeverity severity,
    required AttentionInboxReasonVm headline,
    required List<AttentionInboxReasonVm> reasons,
  }) = _AttentionInboxEntityVm;
}

@freezed
sealed class AttentionInboxReasonVm with _$AttentionInboxReasonVm {
  const factory AttentionInboxReasonVm({
    required String key,
    required AttentionItem item,
  }) = _AttentionInboxReasonVm;
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
    required AttentionRepositoryContract repository,
    required IdGenerator idGenerator,
    required NowService nowService,
    Duration undoWindow = const Duration(seconds: 5),
  }) : _engine = engine,
       _repository = repository,
       _idGenerator = idGenerator,
       _nowService = nowService,
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
    on<AttentionInboxBucketFilterToggled>(_onBucketFilterToggled);
    on<AttentionInboxBucketFilterSet>(_onBucketFilterSet);
    on<AttentionInboxGroupByChanged>(_onGroupByChanged);
    on<AttentionInboxSortChanged>(_onSortChanged);
    on<AttentionInboxMinSeverityChanged>(_onMinSeverityChanged);
    on<AttentionInboxSearchQueryChanged>(_onSearchQueryChanged);
    on<AttentionInboxEntityTypeToggled>(_onEntityTypeToggled);
    on<AttentionInboxToggleSelected>(_onToggleSelected);
    on<AttentionInboxClearSelection>(_onClearSelection);
    on<AttentionInboxApplyActionToSelection>(_onApplyActionToSelection);
    on<AttentionInboxApplyActionToItem>(_onApplyActionToItem);
    on<AttentionInboxApplyActionToMany>(_onApplyActionToMany);
    on<AttentionInboxApplyActionToVisible>(_onApplyActionToVisible);
    on<AttentionInboxCommitPending>(_onCommitPending);
    on<AttentionInboxUndoRequested>(_onUndoRequested);

    add(const AttentionInboxEvent.subscriptionRequested());
  }

  final AttentionEngineContract _engine;
  final AttentionRepositoryContract _repository;
  final IdGenerator _idGenerator;
  final NowService _nowService;
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

  void _onBucketFilterToggled(
    AttentionInboxBucketFilterToggled event,
    Emitter<AttentionInboxState> emit,
  ) {
    final next = {..._viewConfig.bucketFilter};
    if (next.contains(event.bucket)) {
      next.remove(event.bucket);
    } else {
      next.add(event.bucket);
    }
    _viewConfig = _viewConfig.copyWith(bucketFilter: next);
    _selectedKeys.clear();
    emit(_buildLoadedState());
  }

  void _onBucketFilterSet(
    AttentionInboxBucketFilterSet event,
    Emitter<AttentionInboxState> emit,
  ) {
    _viewConfig = _viewConfig.copyWith(bucketFilter: {...event.buckets});
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

  Future<void> _onApplyActionToMany(
    AttentionInboxApplyActionToMany event,
    Emitter<AttentionInboxState> emit,
  ) async {
    final keys = event.itemKeys.toList(growable: false);
    await _applyAction(emit, action: event.action, keys: keys);
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
      keys: items.map(_reasonKey).toSet(),
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
        final now = _nowService.nowUtc();

        final details = switch (pending.action) {
          AttentionResolutionAction.snoozed => <String, dynamic>{
            'snooze_until': now.add(const Duration(days: 1)).toIso8601String(),
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
    List<AttentionItem> visibleFor(AttentionBucket bucket) {
      final items = _itemsByBucket[bucket] ?? const <AttentionItem>[];
      return items
          .where((i) => !_hiddenKeys.contains(_reasonKey(i)))
          .where(_matchesFilters)
          .toList(growable: false);
    }

    final actionVisible = visibleFor(AttentionBucket.action);
    final reviewVisible = visibleFor(AttentionBucket.review);

    final visible = <AttentionItem>[...actionVisible, ...reviewVisible];

    final entities = _groupByEntity(visible);
    final groups = _groupEntitiesBySeverity(entities);

    final existingUndo = state.maybeWhen(
      loaded:
          (
            _,
            __,
            ___,
            ____,
            _____,
            ______,
            pendingUndo,
            _______,
          ) => pendingUndo,
      orElse: () => null,
    );

    final resolvedUndo = clearUndo ? null : pendingUndo ?? existingUndo;

    return AttentionInboxState.loaded(
      viewConfig: _viewConfig,
      groups: groups,
      totalVisibleCount: visible.length,
      actionVisibleCount: actionVisible.length,
      reviewVisibleCount: reviewVisible.length,
      selectedKeys: {..._selectedKeys},
      pendingUndo: resolvedUndo,
      errorMessage: errorMessage,
    );
  }

  bool _matchesFilters(AttentionItem item) {
    final buckets = _viewConfig.bucketFilter;
    if (buckets.isNotEmpty && !buckets.contains(item.bucket)) {
      return false;
    }

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

  List<AttentionInboxEntityVm> _groupByEntity(List<AttentionItem> items) {
    final Map<String, List<AttentionItem>> byEntity = {};
    for (final i in items) {
      (byEntity[_entityKey(i)] ??= []).add(i);
    }

    final entities = <AttentionInboxEntityVm>[];
    for (final entry in byEntity.entries) {
      final reasons = [...entry.value]..sort(_compareReasons);
      final reasonVms = reasons
          .map((r) => AttentionInboxReasonVm(key: _reasonKey(r), item: r))
          .toList(growable: false);

      final headline = reasonVms.first;
      final severity = reasons
          .map((r) => _severityIndex(r.severity))
          .reduce((a, b) => a > b ? a : b);
      final maxSeverity = switch (severity) {
        2 => AttentionSeverity.critical,
        1 => AttentionSeverity.warning,
        _ => AttentionSeverity.info,
      };

      entities.add(
        AttentionInboxEntityVm(
          entityKey: entry.key,
          entityType: headline.item.entityType,
          entityId: headline.item.entityId,
          severity: maxSeverity,
          headline: headline,
          reasons: reasonVms,
        ),
      );
    }

    entities.sort(_compareEntities);
    return entities;
  }

  int _compareReasons(AttentionItem a, AttentionItem b) {
    final s = _severityIndex(b.severity).compareTo(_severityIndex(a.severity));
    if (s != 0) return s;
    final d = b.detectedAt.compareTo(a.detectedAt);
    if (d != 0) return d;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  int _compareEntities(AttentionInboxEntityVm a, AttentionInboxEntityVm b) {
    final s = _severityIndex(b.severity).compareTo(_severityIndex(a.severity));
    if (s != 0) return s;

    final d = b.headline.item.detectedAt.compareTo(a.headline.item.detectedAt);
    if (d != 0) return d;

    final ta = a.headline.item.title.toLowerCase();
    final tb = b.headline.item.title.toLowerCase();
    return ta.compareTo(tb);
  }

  List<AttentionInboxGroupVm> _groupEntitiesBySeverity(
    List<AttentionInboxEntityVm> entities,
  ) {
    final critical = <AttentionInboxEntityVm>[];
    final warning = <AttentionInboxEntityVm>[];
    final info = <AttentionInboxEntityVm>[];

    for (final e in entities) {
      switch (e.severity) {
        case AttentionSeverity.critical:
          critical.add(e);
        case AttentionSeverity.warning:
          warning.add(e);
        case AttentionSeverity.info:
          info.add(e);
      }
    }

    final groups = <AttentionInboxGroupVm>[];
    if (critical.isNotEmpty) {
      groups.add(AttentionInboxGroupVm(title: 'CRITICAL', entities: critical));
    }
    if (warning.isNotEmpty) {
      groups.add(AttentionInboxGroupVm(title: 'WARNING', entities: warning));
    }
    if (info.isNotEmpty) {
      groups.add(AttentionInboxGroupVm(title: 'INFO', entities: info));
    }
    return groups;
  }

  String _reasonKey(AttentionItem item) =>
      '${item.ruleId}::${item.entityType.name}::${item.entityId}';

  String _entityKey(AttentionItem item) =>
      '${item.entityType.name}::${item.entityId}';

  Set<String> _currentAllKeys() {
    final all = <String>{};
    for (final bucket in AttentionBucket.values) {
      final items = _itemsByBucket[bucket] ?? const <AttentionItem>[];
      for (final item in items) {
        all.add(_reasonKey(item));
      }
    }
    return all;
  }

  Set<String> _currentVisibleKeys() {
    final keys = <String>{};
    for (final bucket in AttentionBucket.values) {
      final items = _itemsByBucket[bucket] ?? const <AttentionItem>[];
      for (final item in items) {
        final k = _reasonKey(item);
        if (_hiddenKeys.contains(k)) continue;
        if (!_matchesFilters(item)) continue;
        keys.add(k);
      }
    }
    return keys;
  }

  List<AttentionItem> _itemsForKeys(List<String> keys) {
    final keySet = keys.toSet();

    final result = <AttentionItem>[];
    for (final bucket in AttentionBucket.values) {
      final items = _itemsByBucket[bucket] ?? const <AttentionItem>[];
      for (final item in items) {
        final k = _reasonKey(item);
        if (keySet.contains(k) && !_hiddenKeys.contains(k)) {
          result.add(item);
        }
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
