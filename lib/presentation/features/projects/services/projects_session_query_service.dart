import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/projects_scope.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';

@immutable
final class ProjectsSnapshot {
  const ProjectsSnapshot({
    required this.projects,
    required this.inboxTaskCount,
    required this.values,
    required this.ratings,
  });

  final List<Project> projects;
  final int? inboxTaskCount;
  final List<Value> values;
  final List<ValueWeeklyRating> ratings;
}

final class ProjectsSessionQueryService {
  ProjectsSessionQueryService({
    required ProjectRepositoryContract projectRepository,
    required ValueRatingsRepositoryContract valueRatingsRepository,
    required SessionStreamCacheManager cacheManager,
    required SessionSharedDataService sharedDataService,
    required DemoModeService demoModeService,
    required DemoDataProvider demoDataProvider,
  }) : _projectRepository = projectRepository,
       _valueRatingsRepository = valueRatingsRepository,
       _cacheManager = cacheManager,
       _sharedDataService = sharedDataService,
       _demoModeService = demoModeService,
       _demoDataProvider = demoDataProvider;

  final ProjectRepositoryContract _projectRepository;
  final ValueRatingsRepositoryContract _valueRatingsRepository;
  final SessionStreamCacheManager _cacheManager;
  final SessionSharedDataService _sharedDataService;
  final DemoModeService _demoModeService;
  final DemoDataProvider _demoDataProvider;
  final Set<_ScopeKey> _knownScopes = <_ScopeKey>{};
  static const int _ratingsHistoryWeeks = 8;

  void start() {
    // Prewarm global scope for instant Projects tab load.
    _preloadScope(null);
  }

  Future<void> stop() async {
    final keys = _knownScopes.toList(growable: false);
    _knownScopes.clear();
    for (final key in keys) {
      await _cacheManager.evict(key);
    }
  }

  ValueStream<ProjectsSnapshot> watchProjects({ProjectsScope? scope}) {
    final key = _ScopeKey.fromScope(scope);
    _knownScopes.add(key);
    return _cacheManager.getOrCreate<ProjectsSnapshot>(
      key: key,
      source: () => _buildScopeStream(scope),
      pauseOnBackground: true,
    );
  }

  void _preloadScope(ProjectsScope? scope) {
    final key = _ScopeKey.fromScope(scope);
    _knownScopes.add(key);
    _cacheManager.preload<ProjectsSnapshot>(
      key: key,
      source: () => _buildScopeStream(scope),
      pauseOnBackground: true,
    );
  }

  Stream<ProjectsSnapshot> _buildScopeStream(ProjectsScope? scope) {
    final projects$ = _projectsForScope(scope);
    final values$ = _sharedDataService.watchValues();
    final ratings$ = _ratingsStream();

    return switch (scope) {
      null =>
        Rx.combineLatest4<
          List<Project>,
          int,
          List<Value>,
          List<ValueWeeklyRating>,
          ProjectsSnapshot
        >(
          projects$,
          _sharedDataService.watchInboxTaskCount(),
          values$,
          ratings$,
          (projects, inboxTaskCount, values, ratings) => ProjectsSnapshot(
            projects: projects,
            inboxTaskCount: inboxTaskCount,
            values: values,
            ratings: ratings,
          ),
        ),
      _ =>
        Rx.combineLatest3<
          List<Project>,
          List<Value>,
          List<ValueWeeklyRating>,
          ProjectsSnapshot
        >(
          projects$,
          values$,
          ratings$,
          (projects, values, ratings) => ProjectsSnapshot(
            projects: projects,
            inboxTaskCount: null,
            values: values,
            ratings: ratings,
          ),
        ),
    };
  }

  Stream<List<Project>> _projectsForScope(ProjectsScope? scope) {
    return _demoModeService.enabled.distinct().switchMap((enabled) {
      if (enabled) {
        return Stream<List<Project>>.value(
          _projectsForDemoScope(scope),
        );
      }

      return switch (scope) {
        null => _sharedDataService.watchAllProjects(),
        ProjectsProjectScope(:final projectId) =>
          _projectRepository
              .watchById(projectId)
              .map((project) => project == null ? const [] : [project]),
        ProjectsValueScope(:final valueId) => _projectRepository.watchAll(
          ProjectQuery.byValues([valueId]),
        ),
      };
    });
  }

  List<Project> _projectsForDemoScope(ProjectsScope? scope) {
    final projects = _demoDataProvider.projects.toList(growable: false);

    return switch (scope) {
      null => projects,
      ProjectsProjectScope(:final projectId) => [
        _demoDataProvider.projectById(projectId),
      ].whereType<Project>().toList(growable: false),
      ProjectsValueScope(:final valueId) =>
        projects
            .where((project) => project.primaryValueId == valueId)
            .toList(growable: false),
    };
  }

  Stream<List<ValueWeeklyRating>> _ratingsStream() {
    return _demoModeService.enabled.distinct().switchMap((enabled) {
      if (enabled) {
        return Stream<List<ValueWeeklyRating>>.value(
          _demoDataProvider.buildValueRatingsHistory(
            weeks: _ratingsHistoryWeeks,
          ),
        );
      }
      return _valueRatingsRepository.watchAll(weeks: _ratingsHistoryWeeks);
    });
  }
}

final class _ScopeKey {
  const _ScopeKey._(this.kind, this.id);

  factory _ScopeKey.fromScope(ProjectsScope? scope) {
    return switch (scope) {
      null => const _ScopeKey._('global', ''),
      ProjectsProjectScope(:final projectId) => _ScopeKey._(
        'project',
        projectId,
      ),
      ProjectsValueScope(:final valueId) => _ScopeKey._('value', valueId),
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
