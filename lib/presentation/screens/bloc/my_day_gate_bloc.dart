import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/preferences.dart';

sealed class MyDayGateState {
  const MyDayGateState();
}

final class MyDayGateLoading extends MyDayGateState {
  const MyDayGateLoading();
}

final class MyDayGateLoaded extends MyDayGateState {
  const MyDayGateLoaded({
    required this.needsFocusModeSetup,
    required this.needsValuesSetup,
    required this.ctaLabel,
    required this.ctaIcon,
  });

  final bool needsFocusModeSetup;
  final bool needsValuesSetup;

  final String ctaLabel;
  final IconData ctaIcon;
}

final class MyDayGateError extends MyDayGateState {
  const MyDayGateError(this.message);

  final String message;
}

class MyDayGateBloc extends Cubit<MyDayGateState> {
  MyDayGateBloc({
    required SettingsRepositoryContract settingsRepository,
    required ValueRepositoryContract valueRepository,
  }) : _settingsRepository = settingsRepository,
       _valueRepository = valueRepository,
       super(const MyDayGateLoading()) {
    _subscribe();
  }

  final SettingsRepositoryContract _settingsRepository;
  final ValueRepositoryContract _valueRepository;

  StreamSubscription<MyDayGateLoaded>? _sub;

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }

  void _subscribe() {
    final allocation$ = _settingsRepository
        .watch<AllocationConfig>(SettingsKey.allocation)
        .map<AllocationConfig?>((value) => value)
        .startWith(null);

    // Use a real DB snapshot to avoid showing "Add Values" when values exist
    // but the watch stream is delayed or never emits.
    //
    // We intentionally seed locally (per consumer) instead of turning the
    // repository stream into a replaying subject, to keep lifecycle/memory
    // ownership in the presentation layer.
    final values$ = Rx.concat<List<Value>>([
      Stream.fromFuture(_valueRepository.getAll()),
      _valueRepository.watchAll(),
    ]);

    _sub =
        Rx.combineLatest2<AllocationConfig?, List<Value>, MyDayGateLoaded>(
          allocation$,
          values$,
          (allocation, values) {
            final needsFocusModeSetup =
                !(allocation?.hasSelectedFocusMode ?? false);
            final needsValuesSetup = values.isEmpty;

            final ctaLabel = needsFocusModeSetup
                ? 'Start Setup'
                : needsValuesSetup
                ? 'Add Values'
                : 'Continue';

            final ctaIcon = needsFocusModeSetup
                ? Icons.tune
                : needsValuesSetup
                ? Icons.favorite_outline
                : Icons.arrow_forward;

            return MyDayGateLoaded(
              needsFocusModeSetup: needsFocusModeSetup,
              needsValuesSetup: needsValuesSetup,
              ctaLabel: ctaLabel,
              ctaIcon: ctaIcon,
            );
          },
        ).listen(
          emit,
          onError: (Object e) {
            emit(MyDayGateError('Failed to load My Day prerequisites: $e'));
          },
        );
  }
}
