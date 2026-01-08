import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';

/// Thin bloc for screen rendering (DR-017).
///
/// This bloc is a simple state holder that delegates all logic to
/// [ScreenDataInterpreter]. It subscribes to the interpreter's stream
/// and emits state changes.
///
/// Entity actions (complete, delete, etc.) are NOT handled here.
/// Widgets call [EntityActionService] directly for mutations.
class ScreenBloc extends Bloc<ScreenEvent, ScreenState> {
  ScreenBloc({
    required ScreenDefinitionsRepositoryContract screenRepository,
    required ScreenDataInterpreter interpreter,
  }) : _screenRepository = screenRepository,
       _interpreter = interpreter,
       super(const ScreenState.initial()) {
    on<ScreenLoadEvent>(_onLoad, transformer: restartable());
    on<ScreenLoadByIdEvent>(_onLoadById, transformer: restartable());
  }

  final ScreenDefinitionsRepositoryContract _screenRepository;
  final ScreenDataInterpreter _interpreter;

  Future<void> _onLoad(
    ScreenLoadEvent event,
    Emitter<ScreenState> emit,
  ) async {
    talker.blocLog('ScreenBloc', 'load: ${event.definition.id}');

    final definition = event.definition;
    emit(ScreenState.loading(definition: definition));

    await _subscribeToData(definition, emit);
  }

  Future<void> _onLoadById(
    ScreenLoadByIdEvent event,
    Emitter<ScreenState> emit,
  ) async {
    talker.blocLog('ScreenBloc', 'loadById: ${event.screenId}');

    emit(const ScreenState.loading());

    try {
      final screenWithPrefs = await _screenRepository
          .watchScreen(event.screenId)
          .first;

      if (screenWithPrefs == null) {
        emit(
          ScreenState.error(
            message: 'Screen not found: ${event.screenId}',
          ),
        );
        return;
      }

      final screen = screenWithPrefs.screen;
      emit(ScreenState.loading(definition: screen));

      await _subscribeToData(screen, emit);
    } catch (e, st) {
      talker.handle(e, st, '[ScreenBloc] loadById failed');
      emit(
        ScreenState.error(
          message: 'Failed to load screen: $e',
          error: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<void> _subscribeToData(
    ScreenDefinition definition,
    Emitter<ScreenState> emit,
  ) async {
    // Subscribe to interpreter stream
    await emit.forEach(
      _interpreter.watchScreen(definition),
      onData: (data) {
        if (data.error != null) {
          return ScreenState.error(
            message: data.error!,
            definition: definition,
          );
        }
        return ScreenState.loaded(data: data);
      },
      onError: (error, stackTrace) {
        talker.handle(error, stackTrace, '[ScreenBloc] Stream error');
        return ScreenState.error(
          message: 'Stream error: $error',
          definition: definition,
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }
}
