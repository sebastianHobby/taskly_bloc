import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';

@immutable
final class AnytimeBaseSnapshot {
  const AnytimeBaseSnapshot({
    required this.todayDayKeyUtc,
    required this.tasks,
    required this.todaySelectedTaskIds,
  });

  final DateTime todayDayKeyUtc;
  final List<Task> tasks;
  final Set<String> todaySelectedTaskIds;
}

final class AnytimeSessionQueryService {
  AnytimeSessionQueryService({
    required OccurrenceReadService occurrenceReadService,
    required MyDayRepositoryContract myDayRepository,
    required SessionDayKeyService sessionDayKeyService,
    required AppLifecycleService appLifecycleService,
  }) : _occurrenceReadService = occurrenceReadService,
       _myDayRepository = myDayRepository,
       _sessionDayKeyService = sessionDayKeyService,
       _appLifecycleService = appLifecycleService;

  final OccurrenceReadService _occurrenceReadService;
  final MyDayRepositoryContract _myDayRepository;
  final SessionDayKeyService _sessionDayKeyService;
  final AppLifecycleService _appLifecycleService;

  final Map<_ScopeKey, _ScopeEntry> _scopes = <_ScopeKey, _ScopeEntry>{};

  StreamSubscription<AppLifecycleEvent>? _lifecycleSub;
  bool _started = false;
  bool _foreground = true;

  void start() {
    if (_started) return;
    _started = true;

    // Prewarm global scope for instant Anytime tab load.
    _ensureScope(null);

    _lifecycleSub = _appLifecycleService.events.listen((event) {
      switch (event) {
        case AppLifecycleEvent.resumed:
          _foreground = true;
          _resumeAll();
        case AppLifecycleEvent.inactive:
        case AppLifecycleEvent.paused:
        case AppLifecycleEvent.detached:
          _foreground = false;
          _pauseAll();
      }
    });

    if (_foreground) _resumeAll();
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;

    await _lifecycleSub?.cancel();
    _lifecycleSub = null;

    await Future.wait<void>(_scopes.values.map((e) => e.dispose()));

    _scopes.clear();
  }

  ValueStream<AnytimeBaseSnapshot> watchBase({AnytimeScope? scope}) {
    if (!_started) start();
    final entry = _ensureScope(scope);
    if (_started && _foreground) {
      _resumeScope(scope);
    }
    return entry.subject;
  }

  _ScopeEntry _ensureScope(AnytimeScope? scope) {
    final key = _ScopeKey.fromScope(scope);
    return _scopes.putIfAbsent(key, () {
      final subject = BehaviorSubject<AnytimeBaseSnapshot>();
      return _ScopeEntry(scope: scope, subject: subject);
    });
  }

  void _pauseAll() {
    for (final entry in _scopes.values) {
      unawaited(entry.subscription?.cancel());
      entry.subscription = null;
    }
  }

  void _resumeAll() {
    for (final entry in _scopes.values) {
      _resumeScope(entry.scope);
    }
  }

  void _resumeScope(AnytimeScope? scope) {
    final key = _ScopeKey.fromScope(scope);
    final entry = _scopes[key];
    if (entry == null) return;
    if (entry.subscription != null) return;

    final dayKey$ = _sessionDayKeyService.todayDayKeyUtc;

    final tasks$ = dayKey$.switchMap((dayKey) {
      final preview = OccurrencePolicy.anytimePreview(asOfDayKey: dayKey);
      final query = _scopeQuery(TaskQuery.incomplete(), scope);
      return _occurrenceReadService.watchTasksWithOccurrencePreview(
        query: query,
        preview: preview,
      );
    });

    final todaySelectionIds$ = dayKey$
        .switchMap(_myDayRepository.watchDay)
        .map((picks) {
          if (picks.ritualCompletedAtUtc == null) return <String>{};
          return picks.selectedTaskIds
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty)
              .toSet();
        })
        .distinct(_areSetsEqual);

    final combined$ =
        Rx.combineLatest3<
          DateTime,
          List<Task>,
          Set<String>,
          AnytimeBaseSnapshot
        >(
          dayKey$,
          tasks$,
          todaySelectionIds$,
          (dayKey, tasks, todaySelectionIds) => AnytimeBaseSnapshot(
            todayDayKeyUtc: dayKey,
            tasks: tasks,
            todaySelectedTaskIds: todaySelectionIds,
          ),
        );

    entry.subscription = combined$.listen(
      entry.subject.add,
      onError: entry.subject.addError,
    );
  }

  TaskQuery _scopeQuery(TaskQuery base, AnytimeScope? scope) {
    if (scope == null) return base;

    return switch (scope) {
      AnytimeProjectScope(:final projectId) => base.withAdditionalPredicates([
        TaskProjectPredicate(
          operator: ProjectOperator.matches,
          projectId: projectId,
        ),
      ]),
      AnytimeValueScope(:final valueId) => base.withAdditionalPredicates([
        TaskValuePredicate(
          operator: ValueOperator.hasAll,
          valueIds: [valueId],
          includeInherited: true,
        ),
      ]),
    };
  }

  bool _areSetsEqual(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}

final class _ScopeEntry {
  _ScopeEntry({
    required this.scope,
    required this.subject,
  });

  final AnytimeScope? scope;
  final BehaviorSubject<AnytimeBaseSnapshot> subject;

  /// Owned by this entry; cancelled in [dispose].
  StreamSubscription<AnytimeBaseSnapshot>? subscription;

  Future<void> dispose() async {
    await subscription?.cancel();
    subscription = null;
    await subject.close();
  }
}

final class _ScopeKey {
  const _ScopeKey._(this.kind, this.id);

  factory _ScopeKey.fromScope(AnytimeScope? scope) {
    return switch (scope) {
      null => const _ScopeKey._('global', ''),
      AnytimeProjectScope(:final projectId) => _ScopeKey._(
        'project',
        projectId,
      ),
      AnytimeValueScope(:final valueId) => _ScopeKey._('value', valueId),
    };
  }

  final String kind;
  final String id;

  @override
  bool operator ==(Object other) {
    return other is _ScopeKey && other.kind == kind && other.id == id;
  }

  @override
  int get hashCode => Object.hash(kind, id);
}
