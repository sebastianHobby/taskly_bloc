import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/taskly_domain.dart' show AllocationOrchestrator;

sealed class MyDayPrewarmStatus {
  const MyDayPrewarmStatus();
}

final class MyDayPrewarmIdle extends MyDayPrewarmStatus {
  const MyDayPrewarmIdle();
}

final class MyDayPrewarmRunning extends MyDayPrewarmStatus {
  const MyDayPrewarmRunning();
}

final class MyDayPrewarmReady extends MyDayPrewarmStatus {
  const MyDayPrewarmReady();
}

final class MyDayPrewarmFailure extends MyDayPrewarmStatus {
  const MyDayPrewarmFailure(this.message);

  final String message;
}

final class MyDayPrewarmState {
  const MyDayPrewarmState({required this.status});

  factory MyDayPrewarmState.idle() =>
      const MyDayPrewarmState(status: MyDayPrewarmIdle());

  final MyDayPrewarmStatus status;
}

class MyDayPrewarmCubit extends Cubit<MyDayPrewarmState> {
  MyDayPrewarmCubit({
    required AllocationOrchestrator allocationOrchestrator,
    required SettingsRepositoryContract settingsRepository,
    required ValueRepositoryContract valueRepository,
    required MyDayRepositoryContract myDayRepository,
    required HomeDayKeyService dayKeyService,
  }) : _allocationOrchestrator = allocationOrchestrator,
       _settingsRepository = settingsRepository,
       _valueRepository = valueRepository,
       _myDayRepository = myDayRepository,
       _dayKeyService = dayKeyService,
       super(MyDayPrewarmState.idle());

  final AllocationOrchestrator _allocationOrchestrator;
  final SettingsRepositoryContract _settingsRepository;
  final ValueRepositoryContract _valueRepository;
  final MyDayRepositoryContract _myDayRepository;
  final HomeDayKeyService _dayKeyService;

  Future<void>? _inFlight;

  void _safeEmit(MyDayPrewarmState state) {
    if (isClosed) return;
    emit(state);
  }

  Future<void> start() {
    final status = state.status;
    if (status is MyDayPrewarmReady) return Future.value();
    if (_inFlight != null) return _inFlight!;

    _safeEmit(const MyDayPrewarmState(status: MyDayPrewarmRunning()));

    final future = _run();
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<void> _run() async {
    try {
      final dayKeyUtc = _dayKeyService.todayDayKeyUtc();

      await Future.wait([
        _settingsRepository.load(SettingsKey.global),
        _settingsRepository.load(SettingsKey.allocation),
        _valueRepository.getAll(),
        _myDayRepository.loadDay(dayKeyUtc),
        _allocationOrchestrator.getAllocationSnapshot(),
      ]);

      _safeEmit(const MyDayPrewarmState(status: MyDayPrewarmReady()));
    } catch (e) {
      // Soft-fail: do not block routing.
      _safeEmit(MyDayPrewarmState(status: MyDayPrewarmFailure('$e')));
      _safeEmit(const MyDayPrewarmState(status: MyDayPrewarmReady()));
    }
  }
}
