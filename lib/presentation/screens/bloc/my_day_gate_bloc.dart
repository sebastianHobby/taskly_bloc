import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
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

  StreamSubscription<AllocationConfig?>? _allocationSub;
  StreamSubscription<List<Value>>? _valuesSub;

  AllocationConfig? _latestAllocation;
  List<Value>? _latestValues;

  @override
  Future<void> close() async {
    await _allocationSub?.cancel();
    await _valuesSub?.cancel();
    _allocationSub = null;
    _valuesSub = null;
    return super.close();
  }

  void _subscribe() {
    // Seed with null so the UI can treat this as "not configured" until a real
    // AllocationConfig arrives.
    final Stream<AllocationConfig?> allocation$ = (() async* {
      yield null;
      yield* _settingsRepository
          .watch<AllocationConfig>(SettingsKey.allocation)
          .map<AllocationConfig?>((value) => value);
    })();

    // Use a real DB snapshot to avoid showing "Add Values" when values exist
    // but the watch stream is delayed or never emits.
    //
    // We intentionally seed locally (per consumer) instead of turning the
    // repository stream into a replaying subject, to keep lifecycle/memory
    // ownership in the presentation layer.
    final Stream<List<Value>> values$ = (() async* {
      yield await _valueRepository.getAll();
      yield* _valueRepository.watchAll();
    })();

    void emitIfReady() {
      final values = _latestValues;
      if (values == null) return;

      final allocation = _latestAllocation;
      final needsFocusModeSetup = !(allocation?.hasSelectedFocusMode ?? false);
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

      emit(
        MyDayGateLoaded(
          needsFocusModeSetup: needsFocusModeSetup,
          needsValuesSetup: needsValuesSetup,
          ctaLabel: ctaLabel,
          ctaIcon: ctaIcon,
        ),
      );
    }

    _allocationSub = allocation$.listen(
      (AllocationConfig? allocation) {
        _latestAllocation = allocation;
        emitIfReady();
      },
      onError: (Object e) {
        emit(MyDayGateError('Failed to load My Day prerequisites: $e'));
      },
    );

    _valuesSub = values$.listen(
      (List<Value> values) {
        _latestValues = values;
        emitIfReady();
      },
      onError: (Object e) {
        emit(MyDayGateError('Failed to load My Day prerequisites: $e'));
      },
    );
  }
}
