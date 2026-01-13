import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/core/performance/performance_logger.dart';
import 'package:taskly_bloc/core/performance/screen_performance_trace.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data_interpreter.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_state.dart';

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
    required PerformanceLogger performanceLogger,
  }) : _screenRepository = screenRepository,
       _interpreter = interpreter,
       _performanceLogger = performanceLogger,
       super(const ScreenState.initial()) {
    on<ScreenLoadEvent>(_onLoad, transformer: restartable());
    on<ScreenLoadByIdEvent>(_onLoadById, transformer: restartable());
  }

  final ScreenDefinitionsRepositoryContract _screenRepository;
  final ScreenDataInterpreter _interpreter;
  final PerformanceLogger _performanceLogger;

  bool _hasAnyEnabledSection(ScreenDefinition definition) {
    return definition.sections.any((s) => s.overrides?.enabled ?? true);
  }

  void _failFastOrEmitError({
    required Emitter<ScreenState> emit,
    required String message,
    ScreenDefinition? definition,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kReleaseMode) {
      throw FlutterError(
        '$message\n'
        'screenId=${definition?.id}, screenKey=${definition?.screenKey}, '
        'name=${definition?.name}, '
        'sectionTemplateIds=${definition?.sections.map((s) => s.templateId).toList()}',
      );
    }

    emit(
      ScreenState.error(
        message: message,
        definition: definition,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  Future<void> _onLoad(
    ScreenLoadEvent event,
    Emitter<ScreenState> emit,
  ) async {
    talker.blocLog('ScreenBloc', 'load: ${event.definition.id}');

    final definition = event.definition;

    final trace = _performanceLogger.startScreenTrace(
      screenName: definition.name,
      screenId: definition.id,
    );

    if (!_hasAnyEnabledSection(definition)) {
      trace.endError('Screen has no enabled sections configured.');
      _failFastOrEmitError(
        emit: emit,
        definition: definition,
        message: 'Screen has no enabled sections configured.',
      );
      return;
    }

    emit(ScreenState.loading(definition: definition));

    trace.markLoadingEmitted();

    await _subscribeToData(definition, emit, trace);
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
          .cast<ScreenWithPreferences?>()
          .firstWhere((_) => true, orElse: () => null);

      if (screenWithPrefs == null) {
        emit(
          ScreenState.error(
            message: 'Screen not found: ${event.screenId}',
          ),
        );
        return;
      }

      final screen = screenWithPrefs.screen;

      final trace = _performanceLogger.startScreenTrace(
        screenName: screen.name,
        screenId: screen.id,
      );

      if (!_hasAnyEnabledSection(screen)) {
        trace.endError('Screen has no enabled sections configured.');
        _failFastOrEmitError(
          emit: emit,
          definition: screen,
          message: 'Screen has no enabled sections configured.',
        );
        return;
      }

      emit(ScreenState.loading(definition: screen));
      trace.markLoadingEmitted();

      await _subscribeToData(screen, emit, trace);
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
    ScreenPerformanceTrace trace,
  ) async {
    var firstDataReceived = false;
    // Subscribe to interpreter stream
    await emit.forEach(
      _interpreter.watchScreen(definition),
      onData: (data) {
        if (!firstDataReceived) {
          firstDataReceived = true;
          trace.markFirstData();
        }

        if (data.error != null) {
          trace.endError(data.error!);
          return ScreenState.error(
            message: data.error!,
            definition: definition,
          );
        }
        return ScreenState.loaded(data: data);
      },
      onError: (error, stackTrace) {
        trace.endError(
          'Stream error: $error',
          error: error,
          stackTrace: stackTrace,
        );
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
