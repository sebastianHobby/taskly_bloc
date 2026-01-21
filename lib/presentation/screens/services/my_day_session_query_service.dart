import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/screens/models/my_day_models.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_query_service.dart';
import 'package:taskly_domain/services.dart';

final class MyDaySessionQueryService {
  MyDaySessionQueryService({
    required MyDayQueryService queryService,
    required AppLifecycleService appLifecycleService,
  }) : _queryService = queryService,
       _appLifecycleService = appLifecycleService;

  final MyDayQueryService _queryService;
  final AppLifecycleService _appLifecycleService;

  BehaviorSubject<MyDayViewModel>? _subject;

  StreamSubscription<MyDayViewModel>? _vmSub;
  StreamSubscription<AppLifecycleEvent>? _lifecycleSub;

  bool _started = false;
  bool _foreground = true;

  ValueStream<MyDayViewModel> get viewModel {
    if (!_started) start();
    _subject ??= BehaviorSubject<MyDayViewModel>();
    return _subject!;
  }

  void start() {
    if (_started) return;
    _started = true;

    _subject ??= BehaviorSubject<MyDayViewModel>();

    _lifecycleSub = _appLifecycleService.events.listen((event) {
      switch (event) {
        case AppLifecycleEvent.resumed:
          _foreground = true;
          _resume();
        case AppLifecycleEvent.inactive:
        case AppLifecycleEvent.paused:
        case AppLifecycleEvent.detached:
          _foreground = false;
          _pause();
      }
    });

    if (_foreground) _resume();
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;

    await _lifecycleSub?.cancel();
    _lifecycleSub = null;

    await _vmSub?.cancel();
    _vmSub = null;

    await _subject?.close();
    _subject = null;
  }

  void _pause() {
    unawaited(_vmSub?.cancel());
    _vmSub = null;
  }

  void _resume() {
    if (_vmSub != null) return;

    final subject = _subject;
    if (subject == null || subject.isClosed) return;

    _vmSub = _queryService.watchMyDayViewModel().listen(
      subject.add,
      onError: subject.addError,
    );
  }
}
