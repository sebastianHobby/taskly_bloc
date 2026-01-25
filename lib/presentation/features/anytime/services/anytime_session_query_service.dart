import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';

@immutable
final class AnytimeProjectsSnapshot {
  const AnytimeProjectsSnapshot({
    required this.projects,
    required this.inboxTaskCount,
    required this.values,
  });

  final List<Project> projects;
  final int? inboxTaskCount;
  final List<Value> values;
}

final class AnytimeSessionQueryService {
  AnytimeSessionQueryService({
    required ProjectRepositoryContract projectRepository,
    required TaskRepositoryContract taskRepository,
    required ValueRepositoryContract valueRepository,
    required AppLifecycleService appLifecycleService,
  }) : _projectRepository = projectRepository,
       _taskRepository = taskRepository,
       _valueRepository = valueRepository,
       _appLifecycleService = appLifecycleService;

  final ProjectRepositoryContract _projectRepository;
  final TaskRepositoryContract _taskRepository;
  final ValueRepositoryContract _valueRepository;
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

  ValueStream<AnytimeProjectsSnapshot> watchProjects({AnytimeScope? scope}) {
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
      final subject = BehaviorSubject<AnytimeProjectsSnapshot>();
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

    final projects$ = _projectsForScope(scope);
    final values$ = _valueRepository.watchAll();

    final combined$ = switch (scope) {
      null =>
        Rx.combineLatest3<
          List<Project>,
          int,
          List<Value>,
          AnytimeProjectsSnapshot
        >(
          projects$,
          _taskRepository.watchAllCount(TaskQuery.inbox()),
          values$,
          (projects, inboxTaskCount, values) => AnytimeProjectsSnapshot(
            projects: projects,
            inboxTaskCount: inboxTaskCount,
            values: values,
          ),
        ),
      _ =>
        Rx.combineLatest2<List<Project>, List<Value>, AnytimeProjectsSnapshot>(
          projects$,
          values$,
          (projects, values) => AnytimeProjectsSnapshot(
            projects: projects,
            inboxTaskCount: null,
            values: values,
          ),
        ),
    };

    entry.subscription = combined$.listen(
      entry.subject.add,
      onError: entry.subject.addError,
    );
  }

  Stream<List<Project>> _projectsForScope(AnytimeScope? scope) {
    const incompletePredicate = ProjectBoolPredicate(
      field: ProjectBoolField.completed,
      operator: BoolOperator.isFalse,
    );

    return switch (scope) {
      null => _projectRepository.watchAll(ProjectQuery.incomplete()),
      AnytimeProjectScope(:final projectId) =>
        _projectRepository
            .watchById(projectId)
            .map((project) => project == null ? const [] : [project]),
      AnytimeValueScope(:final valueId) => _projectRepository.watchAll(
        ProjectQuery.byValues([valueId]).withAdditionalPredicates([
          incompletePredicate,
        ]),
      ),
    };
  }
}

final class _ScopeEntry {
  _ScopeEntry({
    required this.scope,
    required this.subject,
  });

  final AnytimeScope? scope;
  final BehaviorSubject<AnytimeProjectsSnapshot> subject;

  /// Owned by this entry; cancelled in [dispose].
  StreamSubscription<AnytimeProjectsSnapshot>? subscription;

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
