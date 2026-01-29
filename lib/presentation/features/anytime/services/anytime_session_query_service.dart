import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';

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
    required SessionStreamCacheManager cacheManager,
    required SessionSharedDataService sharedDataService,
    required DemoModeService demoModeService,
    required DemoDataProvider demoDataProvider,
  }) : _projectRepository = projectRepository,
       _cacheManager = cacheManager,
       _sharedDataService = sharedDataService,
       _demoModeService = demoModeService,
       _demoDataProvider = demoDataProvider;

  final ProjectRepositoryContract _projectRepository;
  final SessionStreamCacheManager _cacheManager;
  final SessionSharedDataService _sharedDataService;
  final DemoModeService _demoModeService;
  final DemoDataProvider _demoDataProvider;
  final Set<_ScopeKey> _knownScopes = <_ScopeKey>{};

  void start() {
    // Prewarm global scope for instant Anytime tab load.
    _preloadScope(null);
  }

  Future<void> stop() async {
    final keys = _knownScopes.toList(growable: false);
    _knownScopes.clear();
    for (final key in keys) {
      await _cacheManager.evict(key);
    }
  }

  ValueStream<AnytimeProjectsSnapshot> watchProjects({AnytimeScope? scope}) {
    final key = _ScopeKey.fromScope(scope);
    _knownScopes.add(key);
    return _cacheManager.getOrCreate<AnytimeProjectsSnapshot>(
      key: key,
      source: () => _buildScopeStream(scope),
      pauseOnBackground: true,
    );
  }

  void _preloadScope(AnytimeScope? scope) {
    final key = _ScopeKey.fromScope(scope);
    _knownScopes.add(key);
    _cacheManager.preload<AnytimeProjectsSnapshot>(
      key: key,
      source: () => _buildScopeStream(scope),
      pauseOnBackground: true,
    );
  }

  Stream<AnytimeProjectsSnapshot> _buildScopeStream(AnytimeScope? scope) {
    final projects$ = _projectsForScope(scope);
    final values$ = _sharedDataService.watchValues();

    return switch (scope) {
      null =>
        Rx.combineLatest3<
          List<Project>,
          int,
          List<Value>,
          AnytimeProjectsSnapshot
        >(
          projects$,
          _sharedDataService.watchInboxTaskCount(),
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
  }

  Stream<List<Project>> _projectsForScope(AnytimeScope? scope) {
    const incompletePredicate = ProjectBoolPredicate(
      field: ProjectBoolField.completed,
      operator: BoolOperator.isFalse,
    );

    return _demoModeService.enabled.distinct().switchMap((enabled) {
      if (enabled) {
        return Stream<List<Project>>.value(
          _projectsForDemoScope(scope),
        );
      }

      return switch (scope) {
        null => _sharedDataService.watchIncompleteProjects(),
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
    });
  }

  List<Project> _projectsForDemoScope(AnytimeScope? scope) {
    final projects = _demoDataProvider.projects
        .where((project) => !project.completed)
        .toList(growable: false);

    return switch (scope) {
      null => projects,
      AnytimeProjectScope(:final projectId) =>
        [
          _demoDataProvider.projectById(projectId),
        ].whereType<Project>().toList(growable: false),
      AnytimeValueScope(:final valueId) =>
        projects
            .where((project) => project.primaryValueId == valueId)
            .toList(growable: false),
    };
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
