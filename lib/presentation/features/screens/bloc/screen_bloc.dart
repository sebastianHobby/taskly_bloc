import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
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
    on<ScreenLoadEvent>(_onLoad);
    on<ScreenLoadByIdEvent>(_onLoadById);
    on<ScreenRefreshEvent>(_onRefresh);
    on<ScreenResetEvent>(_onReset);
  }

  final ScreenDefinitionsRepositoryContract _screenRepository;
  final ScreenDataInterpreter _interpreter;

  StreamSubscription<void>? _dataSubscription;
  ScreenDefinition? _currentDefinition;

  Future<void> _onLoad(
    ScreenLoadEvent event,
    Emitter<ScreenState> emit,
  ) async {
    talker.blocLog('ScreenBloc', 'load: ${event.definition.id}');

    _currentDefinition = event.definition;
    emit(ScreenState.loading(definition: event.definition));

    await _subscribeToData(event.definition, emit);
  }

  Future<void> _onLoadById(
    ScreenLoadByIdEvent event,
    Emitter<ScreenState> emit,
  ) async {
    talker.blocLog('ScreenBloc', 'loadById: ${event.screenId}');

    emit(const ScreenState.loading());

    try {
      final definition = await _screenRepository
          .watchScreen(event.screenId)
          .first;

      if (definition == null) {
        emit(
          ScreenState.error(
            message: 'Screen not found: ${event.screenId}',
          ),
        );
        return;
      }

      _currentDefinition = definition;
      emit(ScreenState.loading(definition: definition));

      await _subscribeToData(definition, emit);
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

  Future<void> _onRefresh(
    ScreenRefreshEvent event,
    Emitter<ScreenState> emit,
  ) async {
    talker.blocLog('ScreenBloc', 'refresh');

    final definition = _currentDefinition;
    if (definition == null) return;

    // Mark as refreshing
    final currentState = state;
    if (currentState is ScreenLoadedState) {
      emit(currentState.copyWith(isRefreshing: true));
    }

    // Re-subscribe to get fresh data
    await _subscribeToData(definition, emit);
  }

  Future<void> _onReset(
    ScreenResetEvent event,
    Emitter<ScreenState> emit,
  ) async {
    talker.blocLog('ScreenBloc', 'reset');

    await _dataSubscription?.cancel();
    _dataSubscription = null;
    _currentDefinition = null;

    emit(const ScreenState.initial());
  }

  Future<void> _subscribeToData(
    ScreenDefinition definition,
    Emitter<ScreenState> emit,
  ) async {
    // Cancel existing subscription
    await _dataSubscription?.cancel();

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

  @override
  Future<void> close() async {
    await _dataSubscription?.cancel();
    return super.close();
  }
}
