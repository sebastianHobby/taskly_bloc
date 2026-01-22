import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';

sealed class MyDayGateState {
  const MyDayGateState();
}

final class MyDayGateLoading extends MyDayGateState {
  const MyDayGateLoading();
}

final class MyDayGateLoaded extends MyDayGateState {
  const MyDayGateLoaded({
    required this.needsValuesSetup,
    required this.ctaLabel,
    required this.ctaIcon,
  });

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
    required ValueRepositoryContract valueRepository,
  }) : _valueRepository = valueRepository,
       super(const MyDayGateLoading()) {
    _subscribe();
  }

  final ValueRepositoryContract _valueRepository;

  StreamSubscription<List<Value>>? _valuesSub;

  List<Value>? _latestValues;

  @override
  Future<void> close() async {
    await _valuesSub?.cancel();
    _valuesSub = null;
    return super.close();
  }

  void _subscribe() {
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
      final needsValuesSetup = values.isEmpty;

      final ctaLabel = needsValuesSetup ? 'Add Values' : 'Continue';

      final ctaIcon = needsValuesSetup
          ? Icons.favorite_outline
          : Icons.arrow_forward;

      emit(
        MyDayGateLoaded(
          needsValuesSetup: needsValuesSetup,
          ctaLabel: ctaLabel,
          ctaIcon: ctaIcon,
        ),
      );
    }

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
