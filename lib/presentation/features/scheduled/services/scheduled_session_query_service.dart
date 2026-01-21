import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/taskly_domain.dart';

final class ScheduledSessionQueryService {
  ScheduledSessionQueryService({
    required ScheduledOccurrencesService scheduledOccurrencesService,
    required SessionDayKeyService sessionDayKeyService,
    required AppLifecycleService appLifecycleService,
  }) : _scheduledOccurrencesService = scheduledOccurrencesService,
       _sessionDayKeyService = sessionDayKeyService,
       _appLifecycleService = appLifecycleService;

  final ScheduledOccurrencesService _scheduledOccurrencesService;
  final SessionDayKeyService _sessionDayKeyService;
  final AppLifecycleService _appLifecycleService;

  final Map<_ScopeKey, _ScopeEntry> _scopes = <_ScopeKey, _ScopeEntry>{};

  StreamSubscription<AppLifecycleEvent>? _lifecycleSub;
  bool _started = false;
  bool _foreground = true;

  static const Duration _window = Duration(days: 30);

  void start() {
    if (_started) return;
    _started = true;

    // Prewarm global scope for instant Scheduled tab load.
    _ensureScope(const GlobalScheduledScope());

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

  ValueStream<ScheduledOccurrencesResult> watchScheduledOccurrences({
    required ScheduledScope scope,
  }) {
    final entry = _ensureScope(scope);
    if (_started && _foreground) {
      _resumeScope(scope);
    }
    return entry.subject;
  }

  _ScopeEntry _ensureScope(ScheduledScope scope) {
    final key = _ScopeKey.fromScope(scope);
    return _scopes.putIfAbsent(key, () {
      final subject = BehaviorSubject<ScheduledOccurrencesResult>();
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

  void _resumeScope(ScheduledScope scope) {
    final key = _ScopeKey.fromScope(scope);
    final entry = _scopes[key];
    if (entry == null) return;
    if (entry.subscription != null) return;

    entry.subscription = _sessionDayKeyService.todayDayKeyUtc
        .switchMap((todayDayKeyUtc) {
          final rangeStart = todayDayKeyUtc;
          final rangeEnd = todayDayKeyUtc.add(_window);
          return _scheduledOccurrencesService.watchScheduledOccurrences(
            rangeStartDay: rangeStart,
            rangeEndDay: rangeEnd,
            scope: scope,
          );
        })
        .listen(
          entry.subject.add,
          onError: entry.subject.addError,
        );
  }
}

final class _ScopeEntry {
  _ScopeEntry({
    required this.scope,
    required this.subject,
  });

  final ScheduledScope scope;
  final BehaviorSubject<ScheduledOccurrencesResult> subject;

  /// Owned by this entry; cancelled in [dispose].
  StreamSubscription<ScheduledOccurrencesResult>? subscription;

  Future<void> dispose() async {
    await subscription?.cancel();
    subscription = null;
    await subject.close();
  }
}

final class _ScopeKey {
  const _ScopeKey._(this.kind, this.id);

  factory _ScopeKey.fromScope(ScheduledScope scope) {
    return switch (scope) {
      GlobalScheduledScope() => const _ScopeKey._('global', ''),
      ProjectScheduledScope(:final projectId) => _ScopeKey._(
        'project',
        projectId,
      ),
      ValueScheduledScope(:final valueId) => _ScopeKey._('value', valueId),
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
