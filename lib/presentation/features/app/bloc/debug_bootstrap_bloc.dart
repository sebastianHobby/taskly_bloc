import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/preferences.dart';

enum DebugBootstrapAction {
  wipeAndSeed,
  wipeAccountAndReset,
}

sealed class DebugBootstrapStatus {
  const DebugBootstrapStatus();
}

final class DebugBootstrapIdle extends DebugBootstrapStatus {
  const DebugBootstrapIdle();
}

final class DebugBootstrapRunning extends DebugBootstrapStatus {
  const DebugBootstrapRunning(this.action);

  final DebugBootstrapAction action;
}

final class DebugBootstrapSuccess extends DebugBootstrapStatus {
  const DebugBootstrapSuccess(this.action);

  final DebugBootstrapAction action;
}

final class DebugBootstrapFailure extends DebugBootstrapStatus {
  const DebugBootstrapFailure({
    required this.action,
    required this.message,
  });

  final DebugBootstrapAction action;
  final String message;
}

final class DebugBootstrapState {
  const DebugBootstrapState({required this.status});

  factory DebugBootstrapState.idle() =>
      const DebugBootstrapState(status: DebugBootstrapIdle());

  final DebugBootstrapStatus status;
}

sealed class DebugBootstrapEvent {
  const DebugBootstrapEvent();
}

final class DebugBootstrapWipeAndSeedRequested extends DebugBootstrapEvent {
  const DebugBootstrapWipeAndSeedRequested({required this.completer});

  final Completer<void> completer;
}

final class DebugBootstrapWipeAccountRequested extends DebugBootstrapEvent {
  const DebugBootstrapWipeAccountRequested({required this.completer});

  final Completer<void> completer;
}

final class DebugBootstrapBloc
    extends Bloc<DebugBootstrapEvent, DebugBootstrapState> {
  DebugBootstrapBloc({
    required TemplateDataService templateDataService,
    required UserDataWipeService userDataWipeService,
    required AuthRepositoryContract authRepository,
    required SettingsRepositoryContract settingsRepository,
  }) : _templateDataService = templateDataService,
       _userDataWipeService = userDataWipeService,
       _authRepository = authRepository,
       _settingsRepository = settingsRepository,
       super(DebugBootstrapState.idle()) {
    on<DebugBootstrapWipeAndSeedRequested>(_onWipeAndSeedRequested);
    on<DebugBootstrapWipeAccountRequested>(_onWipeAccountRequested);
  }

  final TemplateDataService _templateDataService;
  final UserDataWipeService _userDataWipeService;
  final AuthRepositoryContract _authRepository;
  final SettingsRepositoryContract _settingsRepository;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  Future<void> wipeAndSeed() {
    final completer = Completer<void>();
    add(DebugBootstrapWipeAndSeedRequested(completer: completer));
    return completer.future;
  }

  Future<void> wipeAccountAndResetOnboarding() {
    final completer = Completer<void>();
    add(DebugBootstrapWipeAccountRequested(completer: completer));
    return completer.future;
  }

  Future<void> _onWipeAndSeedRequested(
    DebugBootstrapWipeAndSeedRequested event,
    Emitter<DebugBootstrapState> emit,
  ) async {
    emit(
      const DebugBootstrapState(
        status: DebugBootstrapRunning(DebugBootstrapAction.wipeAndSeed),
      ),
    );

    try {
      final context = _contextFactory.create(
        feature: 'debug_bootstrap',
        screen: 'debug_bootstrap',
        intent: 'seed_template_data',
        operation: 'debug.seed_template_data',
        entityType: 'settings',
      );

      await _templateDataService.resetAndSeed(context: context);

      if (emit.isDone) return;
      emit(
        const DebugBootstrapState(
          status: DebugBootstrapSuccess(DebugBootstrapAction.wipeAndSeed),
        ),
      );
    } catch (e) {
      if (emit.isDone) return;
      emit(
        DebugBootstrapState(
          status: DebugBootstrapFailure(
            action: DebugBootstrapAction.wipeAndSeed,
            message: 'Failed to wipe and seed: $e',
          ),
        ),
      );
    } finally {
      if (!event.completer.isCompleted) {
        event.completer.complete();
      }
    }
  }

  Future<void> _onWipeAccountRequested(
    DebugBootstrapWipeAccountRequested event,
    Emitter<DebugBootstrapState> emit,
  ) async {
    emit(
      const DebugBootstrapState(
        status: DebugBootstrapRunning(DebugBootstrapAction.wipeAccountAndReset),
      ),
    );

    try {
      await _userDataWipeService.wipeAllUserData();

      final settings = await _settingsRepository.load(SettingsKey.global);
      await _settingsRepository.save(
        SettingsKey.global,
        settings.copyWith(onboardingCompleted: false),
        context: _contextFactory.create(
          feature: 'debug_bootstrap',
          screen: 'debug_bootstrap',
          intent: 'onboarding.reset',
          operation: 'settings.onboarding.reset',
          entityType: 'settings',
        ),
      );

      final signOutContext = _contextFactory.create(
        feature: 'debug_bootstrap',
        screen: 'debug_bootstrap',
        intent: 'wipe_account_and_sign_out',
        operation: 'auth.sign_out',
        entityType: 'auth',
      );
      await _authRepository.signOut(context: signOutContext);

      if (emit.isDone) return;
      emit(
        const DebugBootstrapState(
          status: DebugBootstrapSuccess(
            DebugBootstrapAction.wipeAccountAndReset,
          ),
        ),
      );
    } catch (e) {
      if (emit.isDone) return;
      emit(
        DebugBootstrapState(
          status: DebugBootstrapFailure(
            action: DebugBootstrapAction.wipeAccountAndReset,
            message: 'Failed to wipe account: $e',
          ),
        ),
      );
    } finally {
      if (!event.completer.isCompleted) {
        event.completer.complete();
      }
    }
  }
}
