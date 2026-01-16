import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data_interpreter.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_banner_session_cubit.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_bell_cubit.dart';
import 'package:taskly_bloc/presentation/features/attention/model/attention_session_banner_vm.dart';
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
    required AttentionBellCubit attentionBellCubit,
    required AttentionBannerSessionCubit attentionBannerSessionCubit,
  }) : _interpreter = interpreter,
       _attentionBellCubit = attentionBellCubit,
       _attentionBannerSessionCubit = attentionBannerSessionCubit,
       super(const ScreenSpecInitialState()) {
    on<ScreenSpecLoadEvent>(_onLoad, transformer: restartable());
  }

  final ScreenSpecDataInterpreter _interpreter;
  final AttentionBellCubit _attentionBellCubit;
  final AttentionBannerSessionCubit _attentionBannerSessionCubit;

  Future<void> _onLoad(
    ScreenSpecLoadEvent event,
    Emitter<ScreenSpecState> emit,
  ) async {
    talker.blocLog('ScreenSpecBloc', 'load: ${event.spec.id}');

    emit(ScreenSpecLoadingState(spec: event.spec));

    final combined = Rx.combineLatest3(
      _interpreter.watchScreen(event.spec),
      _attentionBellCubit.stream.startWith(_attentionBellCubit.state),
      _attentionBannerSessionCubit.stream.startWith(
        _attentionBannerSessionCubit.state,
      ),
      (data, bell, session) => (data, bell, session),
    );

    await emit.forEach(
      combined,
      onData: (value) {
        final (data, bell, session) = value;

        if (data.hasError) {
          return ScreenSpecErrorState(
            message: data.error ?? 'Unknown error',
            spec: event.spec,
          );
        }

        final attentionSessionBanner = _buildAttentionSessionBanner(
          spec: event.spec,
          bell: bell,
          session: session,
        );

        return ScreenSpecLoadedState(
          data: data,
          attentionSessionBanner: attentionSessionBanner,
        );
      },
      onError: (error, _) {
        return ScreenSpecErrorState(
          message: error.toString(),
          spec: event.spec,
        );
      },
    );
  }

  AttentionSessionBannerVm? _buildAttentionSessionBanner({
    required ScreenSpec spec,
    required AttentionBellState bell,
    required AttentionBannerSessionState session,
  }) {
    if (bell.isLoading) return null;
    if (bell.error != null) return null;

    final screenKey = spec.screenKey;
    if (session.isDismissed(screenKey)) return null;

    return switch (screenKey) {
      'my_day' when bell.criticalCount > 0 => const AttentionSessionBannerVm(
        severity: AttentionSessionBannerSeverity.critical,
      ),
      'someday' when bell.criticalCount > 0 || bell.warningCount > 0 =>
        AttentionSessionBannerVm(
          severity: bell.criticalCount > 0
              ? AttentionSessionBannerSeverity.critical
              : AttentionSessionBannerSeverity.warning,
        ),
      _ => null,
    };
  }
}
