import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data_interpreter.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_state.dart';

sealed class ScreenSpecEvent {
  const ScreenSpecEvent();
}

final class ScreenSpecLoadEvent extends ScreenSpecEvent {
  const ScreenSpecLoadEvent({required this.spec});

  final ScreenSpec spec;
}

class ScreenSpecBloc extends Bloc<ScreenSpecEvent, ScreenSpecState> {
  ScreenSpecBloc({
    required ScreenSpecDataInterpreter interpreter,
  }) : _interpreter = interpreter,
       super(const ScreenSpecInitialState()) {
    on<ScreenSpecLoadEvent>(_onLoad, transformer: restartable());
  }

  final ScreenSpecDataInterpreter _interpreter;

  Future<void> _onLoad(
    ScreenSpecLoadEvent event,
    Emitter<ScreenSpecState> emit,
  ) async {
    talker.blocLog('ScreenSpecBloc', 'load: ${event.spec.id}');

    emit(ScreenSpecLoadingState(spec: event.spec));

    await emit.forEach(
      _interpreter.watchScreen(event.spec),
      onData: (data) {
        if (data.hasError) {
          return ScreenSpecErrorState(
            message: data.error ?? 'Unknown error',
            spec: event.spec,
          );
        }
        return ScreenSpecLoadedState(data: data);
      },
      onError: (error, _) {
        return ScreenSpecErrorState(
          message: error.toString(),
          spec: event.spec,
        );
      },
    );
  }
}
