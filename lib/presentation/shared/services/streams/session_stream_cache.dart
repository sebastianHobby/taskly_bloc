import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/services.dart';

/// Session-scoped stream cache with lifecycle-aware pausing.
///
/// - Cached streams are replaying [ValueStream]s.
/// - Subscriptions pause on background if configured.
/// - Sources are re-subscribed on resume.
final class SessionStreamCacheManager {
  SessionStreamCacheManager({
    required AppLifecycleService appLifecycleService,
  }) : _appLifecycleService = appLifecycleService;

  final AppLifecycleService _appLifecycleService;
  final Map<Object, _CacheEntry<dynamic>> _entries = <Object, _CacheEntry>{};

  StreamSubscription<AppLifecycleEvent>? _lifecycleSub;
  bool _foreground = true;

  void start() {
    _ensureLifecycleSubscription();
  }

  Future<void> stop() async {
    await _lifecycleSub?.cancel();
    _lifecycleSub = null;
    _foreground = true;
  }

  ValueStream<T> getOrCreate<T>({
    required Object key,
    required Stream<T> Function() source,
    bool pauseOnBackground = true,
  }) {
    _ensureLifecycleSubscription();

    final existing = _entries[key];
    if (existing is _CacheEntry<T>) {
      existing.pauseOnBackground = pauseOnBackground;
      _ensureEntryActive(existing);
      return existing.subject;
    }

    final entry = _CacheEntry<T>(
      source: source,
      pauseOnBackground: pauseOnBackground,
    );
    _entries[key] = entry;
    _ensureEntryActive(entry);
    return entry.subject;
  }

  void preload<T>({
    required Object key,
    required Stream<T> Function() source,
    bool pauseOnBackground = true,
  }) {
    getOrCreate<T>(
      key: key,
      source: source,
      pauseOnBackground: pauseOnBackground,
    );
  }

  Future<void> evict(Object key) async {
    final entry = _entries.remove(key);
    if (entry == null) return;
    await entry.dispose();
  }

  Future<void> dispose() async {
    await stop();
    final entries = _entries.values.toList();
    _entries.clear();
    for (final entry in entries) {
      await entry.dispose();
    }
  }

  void _ensureLifecycleSubscription() {
    if (_lifecycleSub != null) return;
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
  }

  void _pauseAll() {
    _entries.values
        .where((entry) => entry.pauseOnBackground)
        .forEach((entry) => entry.pause());
  }

  void _resumeAll() {
    _entries.values.forEach(_ensureEntryActive);
  }

  void _ensureEntryActive(_CacheEntry<dynamic> entry) {
    if (_foreground || !entry.pauseOnBackground) {
      entry.resume();
    }
  }
}

final class _CacheEntry<T> {
  _CacheEntry({
    required Stream<T> Function() source,
    required this.pauseOnBackground,
  }) : _source = source,
       subject = BehaviorSubject<T>();

  final Stream<T> Function() _source;
  final BehaviorSubject<T> subject;

  bool pauseOnBackground;
  StreamSubscription<T>? _subscription;

  void resume() {
    if (_subscription != null) return;
    _subscription = _source().listen(
      subject.add,
      onError: subject.addError,
      onDone: subject.close,
    );
  }

  void pause() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await subject.close();
  }
}
