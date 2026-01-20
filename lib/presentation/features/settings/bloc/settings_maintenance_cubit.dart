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

class SettingsMaintenanceCubit extends Cubit<SettingsMaintenanceState> {
  SettingsMaintenanceCubit({
    required TemplateDataService templateDataService,
  }) : _templateDataService = templateDataService,
       super(SettingsMaintenanceState.idle());

  final TemplateDataService _templateDataService;

  void _safeEmit(SettingsMaintenanceState state) {
    if (isClosed) return;
    emit(state);
  }

  Future<void> generateTemplateData() async {
    _safeEmit(
      const SettingsMaintenanceState(
        status: SettingsMaintenanceRunning(
          SettingsMaintenanceAction.generateTemplateData,
        ),
      ),
    );

    try {
      await _templateDataService.resetAndSeed();

      if (isClosed) return;

      _safeEmit(
        const SettingsMaintenanceState(
          status: SettingsMaintenanceSuccess(
            SettingsMaintenanceAction.generateTemplateData,
          ),
        ),
      );

      _safeEmit(SettingsMaintenanceState.idle());
    } catch (e) {
      if (isClosed) return;

      _safeEmit(
        SettingsMaintenanceState(
          status: SettingsMaintenanceFailure(
            action: SettingsMaintenanceAction.generateTemplateData,
            message: 'Failed to generate template data: $e',
          ),
        ),
      );

      _safeEmit(SettingsMaintenanceState.idle());
    }
  }
}
