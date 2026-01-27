import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';

import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';

/// Session-level shared streams for common, cross-screen data.
final class SessionSharedDataService {
  SessionSharedDataService({
    required SessionStreamCacheManager cacheManager,
    required ValueRepositoryContract valueRepository,
    required ProjectRepositoryContract projectRepository,
    required TaskRepositoryContract taskRepository,
  }) : _cacheManager = cacheManager,
       _valueRepository = valueRepository,
       _projectRepository = projectRepository,
       _taskRepository = taskRepository;

  final SessionStreamCacheManager _cacheManager;
  final ValueRepositoryContract _valueRepository;
  final ProjectRepositoryContract _projectRepository;
  final TaskRepositoryContract _taskRepository;

  static const Object _valuesKey = 'session.values.all';
  static const Object _projectsAllKey = 'session.projects.all';
  static const Object _projectsIncompleteKey = 'session.projects.incomplete';
  static const Object _inboxCountKey = 'session.tasks.inbox.count';
  static const Object _tasksAllCountKey = 'session.tasks.all.count';

  ValueStream<List<Value>> watchValues() {
    return _cacheManager.getOrCreate<List<Value>>(
      key: _valuesKey,
      source: _valueRepository.watchAll,
      pauseOnBackground: true,
    );
  }

  ValueStream<List<Project>> watchAllProjects() {
    return _cacheManager.getOrCreate<List<Project>>(
      key: _projectsAllKey,
      source: _projectRepository.watchAll,
      pauseOnBackground: true,
    );
  }

  ValueStream<List<Project>> watchIncompleteProjects() {
    return _cacheManager.getOrCreate<List<Project>>(
      key: _projectsIncompleteKey,
      source: () => _projectRepository.watchAll(ProjectQuery.incomplete()),
      pauseOnBackground: true,
    );
  }

  ValueStream<int> watchInboxTaskCount() {
    return _cacheManager.getOrCreate<int>(
      key: _inboxCountKey,
      source: () => _taskRepository.watchAllCount(TaskQuery.inbox()),
      pauseOnBackground: true,
    );
  }

  ValueStream<int> watchAllTaskCount() {
    return _cacheManager.getOrCreate<int>(
      key: _tasksAllCountKey,
      source: _taskRepository.watchAllCount,
      pauseOnBackground: true,
    );
  }

  void preloadDefaults() {
    _cacheManager.preload<List<Value>>(
      key: _valuesKey,
      source: _valueRepository.watchAll,
      pauseOnBackground: true,
    );
    _cacheManager.preload<List<Project>>(
      key: _projectsIncompleteKey,
      source: () => _projectRepository.watchAll(ProjectQuery.incomplete()),
      pauseOnBackground: true,
    );
    _cacheManager.preload<int>(
      key: _inboxCountKey,
      source: () => _taskRepository.watchAllCount(TaskQuery.inbox()),
      pauseOnBackground: true,
    );
  }

  Future<void> stop() async {
    await _cacheManager.evict(_valuesKey);
    await _cacheManager.evict(_projectsAllKey);
    await _cacheManager.evict(_projectsIncompleteKey);
    await _cacheManager.evict(_inboxCountKey);
    await _cacheManager.evict(_tasksAllCountKey);
  }
}
