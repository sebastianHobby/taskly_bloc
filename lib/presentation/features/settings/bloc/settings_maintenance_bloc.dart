import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_domain/services.dart';

enum SettingsMaintenanceAction {
  generateTemplateData,
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

class SettingsMaintenanceBloc
    extends Bloc<SettingsMaintenanceEvent, SettingsMaintenanceState> {
  SettingsMaintenanceBloc({
    required TemplateDataService templateDataService,
  }) : _templateDataService = templateDataService,
       super(SettingsMaintenanceState.idle()) {
    on<SettingsMaintenanceGenerateTemplateDataRequested>(
      _onGenerateTemplateDataRequested,
    );
  }

  final TemplateDataService _templateDataService;

  Future<void> generateTemplateData() {
    final completer = Completer<void>();
    add(SettingsMaintenanceGenerateTemplateDataRequested(completer: completer));
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
      await _templateDataService.resetAndSeed();

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
}
