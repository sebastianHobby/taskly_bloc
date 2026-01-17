import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/preferences.dart';

sealed class MyDayHeaderEvent {
  const MyDayHeaderEvent();
}

final class MyDayHeaderStarted extends MyDayHeaderEvent {
  const MyDayHeaderStarted();
}

final class MyDayHeaderFocusModeBannerTapped extends MyDayHeaderEvent {
  const MyDayHeaderFocusModeBannerTapped();
}

enum MyDayHeaderNav {
  openFocusSetupWizard,
}

@immutable
final class MyDayHeaderState {
  const MyDayHeaderState({
    required this.focusMode,
    this.nav,
    this.navRequestId = 0,
  });

  final FocusMode focusMode;

  /// One-shot navigation request.
  ///
  /// Use [navRequestId] for de-duplication in listeners.
  final MyDayHeaderNav? nav;
  final int navRequestId;

  MyDayHeaderState copyWith({
    FocusMode? focusMode,
    MyDayHeaderNav? nav,
    int? navRequestId,
  }) {
    return MyDayHeaderState(
      focusMode: focusMode ?? this.focusMode,
      nav: nav ?? this.nav,
      navRequestId: navRequestId ?? this.navRequestId,
    );
  }
}

class MyDayHeaderBloc extends Bloc<MyDayHeaderEvent, MyDayHeaderState> {
  MyDayHeaderBloc({required SettingsRepositoryContract settingsRepository})
    : _settingsRepository = settingsRepository,
      super(const MyDayHeaderState(focusMode: FocusMode.sustainable)) {
    on<MyDayHeaderStarted>(_onStarted);
    on<MyDayHeaderFocusModeBannerTapped>(_onFocusModeBannerTapped);
    on<_MyDayHeaderAllocationChanged>(_onAllocationChanged);
  }

  final SettingsRepositoryContract _settingsRepository;

  StreamSubscription<AllocationConfig>? _allocationSub;

  @override
  Future<void> close() async {
    await _allocationSub?.cancel();
    _allocationSub = null;
    return super.close();
  }

  Future<void> _onStarted(
    MyDayHeaderStarted event,
    Emitter<MyDayHeaderState> emit,
  ) async {
    await _allocationSub?.cancel();

    _allocationSub = _settingsRepository
        .watch<AllocationConfig>(SettingsKey.allocation)
        .listen((config) {
          add(_MyDayHeaderAllocationChanged(config.focusMode));
        });
  }

  void _onAllocationChanged(
    _MyDayHeaderAllocationChanged event,
    Emitter<MyDayHeaderState> emit,
  ) {
    if (event.focusMode == state.focusMode) return;
    emit(state.copyWith(focusMode: event.focusMode));
  }

  void _onFocusModeBannerTapped(
    MyDayHeaderFocusModeBannerTapped event,
    Emitter<MyDayHeaderState> emit,
  ) {
    emit(
      state.copyWith(
        nav: MyDayHeaderNav.openFocusSetupWizard,
        navRequestId: state.navRequestId + 1,
      ),
    );
  }
}

final class _MyDayHeaderAllocationChanged extends MyDayHeaderEvent {
  const _MyDayHeaderAllocationChanged(this.focusMode);

  final FocusMode focusMode;
}
