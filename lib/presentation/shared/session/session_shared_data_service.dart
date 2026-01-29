import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';

import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';

/// Session-level shared streams for common, cross-screen data.
final class SessionSharedDataService {
  SessionSharedDataService({
    required SessionStreamCacheManager cacheManager,
    required ValueRepositoryContract valueRepository,
    required ProjectRepositoryContract projectRepository,
    required TaskRepositoryContract taskRepository,
    required DemoModeService demoModeService,
    required DemoDataProvider demoDataProvider,
  }) : _cacheManager = cacheManager,
       _valueRepository = valueRepository,
       _projectRepository = projectRepository,
       _taskRepository = taskRepository,
       _demoModeService = demoModeService,
       _demoDataProvider = demoDataProvider;

  final SessionStreamCacheManager _cacheManager;
  final ValueRepositoryContract _valueRepository;
  final ProjectRepositoryContract _projectRepository;
  final TaskRepositoryContract _taskRepository;
  final DemoModeService _demoModeService;
  final DemoDataProvider _demoDataProvider;

  static const Object _valuesKey = 'session.values.all';
  static const Object _projectsAllKey = 'session.projects.all';
  static const Object _projectsIncompleteKey = 'session.projects.incomplete';
  static const Object _inboxCountKey = 'session.tasks.inbox.count';
  static const Object _tasksAllCountKey = 'session.tasks.all.count';

  ValueStream<List<Value>> watchValues() {
    return _cacheManager.getOrCreate<List<Value>>(
      key: _valuesKey,
      source: _valuesSource,
      pauseOnBackground: true,
    );
  }

  ValueStream<List<Project>> watchAllProjects() {
    return _cacheManager.getOrCreate<List<Project>>(
      key: _projectsAllKey,
      source: _projectsAllSource,
      pauseOnBackground: true,
    );
  }

  ValueStream<List<Project>> watchIncompleteProjects() {
    return _cacheManager.getOrCreate<List<Project>>(
      key: _projectsIncompleteKey,
      source: _projectsIncompleteSource,
      pauseOnBackground: true,
    );
  }

  ValueStream<int> watchInboxTaskCount() {
    return _cacheManager.getOrCreate<int>(
      key: _inboxCountKey,
      source: _inboxCountSource,
      pauseOnBackground: true,
    );
  }

  ValueStream<int> watchAllTaskCount() {
    return _cacheManager.getOrCreate<int>(
      key: _tasksAllCountKey,
      source: _allTaskCountSource,
      pauseOnBackground: true,
    );
  }

  void preloadDefaults() {
    _cacheManager.preload<List<Value>>(
      key: _valuesKey,
      source: _valuesSource,
      pauseOnBackground: true,
    );
    _cacheManager.preload<List<Project>>(
      key: _projectsIncompleteKey,
      source: _projectsIncompleteSource,
      pauseOnBackground: true,
    );
    _cacheManager.preload<int>(
      key: _inboxCountKey,
      source: _inboxCountSource,
      pauseOnBackground: true,
    );
  }

  Stream<List<Value>> _valuesSource() {
    return _demoModeService.enabled.distinct().switchMap((enabled) {
      if (enabled) {
        return Stream<List<Value>>.value(_demoDataProvider.values);
      }
      return _valueRepository.watchAll();
    });
  }

  Stream<List<Project>> _projectsAllSource() {
    return _demoModeService.enabled.distinct().switchMap((enabled) {
      if (enabled) {
        return Stream<List<Project>>.value(_demoDataProvider.projects);
      }
      return _projectRepository.watchAll();
    });
  }

  Stream<List<Project>> _projectsIncompleteSource() {
    return _demoModeService.enabled.distinct().switchMap((enabled) {
      if (enabled) {
        final projects = _demoDataProvider.projects
            .where((project) => !project.completed)
            .toList(growable: false);
        return Stream<List<Project>>.value(projects);
      }
      return _projectRepository.watchAll(ProjectQuery.incomplete());
    });
  }

  Stream<int> _inboxCountSource() {
    return _demoModeService.enabled.distinct().switchMap((enabled) {
      if (enabled) {
        return Stream<int>.value(_demoDataProvider.inboxTaskCount);
      }
      return _taskRepository.watchAllCount(TaskQuery.inbox()).startWith(0);
    });
  }

  Stream<int> _allTaskCountSource() {
    return _demoModeService.enabled.distinct().switchMap((enabled) {
      if (enabled) {
        return Stream<int>.value(_demoDataProvider.tasks.length);
      }
      return _taskRepository.watchAllCount();
    });
  }

  Future<void> stop() async {
    await _cacheManager.evict(_valuesKey);
    await _cacheManager.evict(_projectsAllKey);
    await _cacheManager.evict(_projectsIncompleteKey);
    await _cacheManager.evict(_inboxCountKey);
    await _cacheManager.evict(_tasksAllCountKey);
  }
}
