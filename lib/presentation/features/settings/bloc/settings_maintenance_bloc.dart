import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

enum SettingsMaintenanceAction {
  generateTemplateData,
  resetOnboardingAndLogout,
}

sealed class SettingsMaintenanceStatus {
  const SettingsMaintenanceStatus();
}

final class SettingsMaintenanceIdle extends SettingsMaintenanceStatus {
  const SettingsMaintenanceIdle();
}

final class SettingsMaintenanceRunning extends SettingsMaintenanceStatus {
  const SettingsMaintenanceRunning(this.action);

  final SettingsMaintenanceAction action;
}

final class SettingsMaintenanceSuccess extends SettingsMaintenanceStatus {
  const SettingsMaintenanceSuccess(this.action);

  final SettingsMaintenanceAction action;
}

final class SettingsMaintenanceFailure extends SettingsMaintenanceStatus {
  const SettingsMaintenanceFailure({
    required this.action,
    required this.message,
  });

  final SettingsMaintenanceAction action;
  final String message;
}

final class SettingsMaintenanceState {
  const SettingsMaintenanceState({required this.status});

  factory SettingsMaintenanceState.idle() =>
      const SettingsMaintenanceState(status: SettingsMaintenanceIdle());

  final SettingsMaintenanceStatus status;
}

sealed class SettingsMaintenanceEvent {
  const SettingsMaintenanceEvent();
}

final class SettingsMaintenanceGenerateTemplateDataRequested
    extends SettingsMaintenanceEvent {
  const SettingsMaintenanceGenerateTemplateDataRequested({
    required this.completer,
  });

  final Completer<void> completer;
}

final class SettingsMaintenanceResetOnboardingRequested
    extends SettingsMaintenanceEvent {
  const SettingsMaintenanceResetOnboardingRequested({
    required this.completer,
  });

  final Completer<void> completer;
}

class SettingsMaintenanceBloc
    extends Bloc<SettingsMaintenanceEvent, SettingsMaintenanceState> {
  SettingsMaintenanceBloc({
    required TemplateDataService templateDataService,
    required UserDataWipeService userDataWipeService,
    required AuthRepositoryContract authRepository,
  }) : _templateDataService = templateDataService,
       _userDataWipeService = userDataWipeService,
       _authRepository = authRepository,
       super(SettingsMaintenanceState.idle()) {
    on<SettingsMaintenanceGenerateTemplateDataRequested>(
      _onGenerateTemplateDataRequested,
    );
    on<SettingsMaintenanceResetOnboardingRequested>(
      _onResetOnboardingRequested,
    );
  }

  final TemplateDataService _templateDataService;
  final UserDataWipeService _userDataWipeService;
  final AuthRepositoryContract _authRepository;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  Future<void> generateTemplateData() {
    final completer = Completer<void>();
    add(SettingsMaintenanceGenerateTemplateDataRequested(completer: completer));
    return completer.future;
  }

  Future<void> resetOnboardingAndSignOut() {
    final completer = Completer<void>();
    add(SettingsMaintenanceResetOnboardingRequested(completer: completer));
    return completer.future;
  }

  Future<void> _onGenerateTemplateDataRequested(
    SettingsMaintenanceGenerateTemplateDataRequested event,
    Emitter<SettingsMaintenanceState> emit,
  ) async {
    emit(
      const SettingsMaintenanceState(
        status: SettingsMaintenanceRunning(
          SettingsMaintenanceAction.generateTemplateData,
        ),
      ),
    );

    try {
      final context = _newContext(
        intent: 'generate_template_data',
        operation: 'settings.template.seed',
      );
      await _templateDataService.resetAndSeed(context: context);

      if (emit.isDone) return;

      emit(
        const SettingsMaintenanceState(
          status: SettingsMaintenanceSuccess(
            SettingsMaintenanceAction.generateTemplateData,
          ),
        ),
      );

      if (emit.isDone) return;
      emit(SettingsMaintenanceState.idle());
    } catch (e) {
      if (emit.isDone) return;

      emit(
        SettingsMaintenanceState(
          status: SettingsMaintenanceFailure(
            action: SettingsMaintenanceAction.generateTemplateData,
            message: 'Failed to generate template data: $e',
          ),
        ),
      );

      if (emit.isDone) return;
      emit(SettingsMaintenanceState.idle());
    } finally {
      if (!event.completer.isCompleted) {
        event.completer.complete();
      }
    }
  }

  Future<void> _onResetOnboardingRequested(
    SettingsMaintenanceResetOnboardingRequested event,
    Emitter<SettingsMaintenanceState> emit,
  ) async {
    emit(
      const SettingsMaintenanceState(
        status: SettingsMaintenanceRunning(
          SettingsMaintenanceAction.resetOnboardingAndLogout,
        ),
      ),
    );

    try {
      await _userDataWipeService.wipeAllUserData();

      final signOutContext = _newContext(
        intent: 'settings_sign_out_requested',
        operation: 'auth.sign_out',
      );
      await _authRepository.signOut(context: signOutContext);

      if (emit.isDone) return;
      emit(
        const SettingsMaintenanceState(
          status: SettingsMaintenanceSuccess(
            SettingsMaintenanceAction.resetOnboardingAndLogout,
          ),
        ),
      );

      if (emit.isDone) return;
      emit(SettingsMaintenanceState.idle());
    } catch (e) {
      if (emit.isDone) return;
      emit(
        SettingsMaintenanceState(
          status: SettingsMaintenanceFailure(
            action: SettingsMaintenanceAction.resetOnboardingAndLogout,
            message: 'Failed to wipe account data: $e',
          ),
        ),
      );
      if (emit.isDone) return;
      emit(SettingsMaintenanceState.idle());
    } finally {
      if (!event.completer.isCompleted) {
        event.completer.complete();
      }
    }
  }

  OperationContext _newContext({
    required String intent,
    required String operation,
  }) {
    return _contextFactory.create(
      feature: 'settings',
      screen: 'developer_settings',
      intent: intent,
      operation: operation,
      entityType: 'settings',
    );
  }
}
