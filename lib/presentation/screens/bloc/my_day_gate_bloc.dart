import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';

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

sealed class MyDayGateEvent {
  const MyDayGateEvent();
}

final class MyDayGateStarted extends MyDayGateEvent {
  const MyDayGateStarted();
}

final class MyDayGateRetryRequested extends MyDayGateEvent {
  const MyDayGateRetryRequested();
}

class MyDayGateBloc extends Bloc<MyDayGateEvent, MyDayGateState> {
  MyDayGateBloc({
    required ValueRepositoryContract valueRepository,
    required SessionSharedDataService sharedDataService,
  }) : _valueRepository = valueRepository,
       _sharedDataService = sharedDataService,
       super(const MyDayGateLoading()) {
    on<MyDayGateStarted>(_onStarted, transformer: restartable());
    on<MyDayGateRetryRequested>(_onRetryRequested, transformer: restartable());

    add(const MyDayGateStarted());
  }

  final ValueRepositoryContract _valueRepository;
  final SessionSharedDataService _sharedDataService;

  Future<void> _onStarted(
    MyDayGateStarted event,
    Emitter<MyDayGateState> emit,
  ) async {
    await _subscribe(emit);
  }

  Future<void> _onRetryRequested(
    MyDayGateRetryRequested event,
    Emitter<MyDayGateState> emit,
  ) async {
    emit(const MyDayGateLoading());
    await _subscribe(emit);
  }

  Future<void> _subscribe(Emitter<MyDayGateState> emit) async {
    // Use a real DB snapshot to avoid showing "Add Values" when values exist
    // but the watch stream is delayed or never emits.
    //
    // We intentionally seed locally (per consumer) instead of turning the
    // repository stream into a replaying subject, to keep lifecycle/memory
    // ownership in the presentation layer.
    final Stream<List<Value>> values$ = (() async* {
      yield await _valueRepository.getAll();
      yield* _sharedDataService.watchValues();
    })();

    await emit.forEach<List<Value>>(
      values$,
      onData: (values) {
        final needsValuesSetup = values.isEmpty;
        final ctaLabel = needsValuesSetup ? 'Add Values' : 'Continue';
        final ctaIcon = needsValuesSetup
            ? Icons.favorite_outline
            : Icons.arrow_forward;
        return MyDayGateLoaded(
          needsValuesSetup: needsValuesSetup,
          ctaLabel: ctaLabel,
          ctaIcon: ctaIcon,
        );
      },
      onError: (error, stackTrace) =>
          MyDayGateError('Failed to load My Day prerequisites: $error'),
    );
  }
}
