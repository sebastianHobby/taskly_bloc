import 'package:bloc/bloc.dart';
import 'package:taskly_domain/allocation.dart';
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
    required AllocationSnapshotCoordinator allocationSnapshotCoordinator,
  }) : _templateDataService = templateDataService,
       _allocationSnapshotCoordinator = allocationSnapshotCoordinator,
       super(SettingsMaintenanceState.idle());

  final TemplateDataService _templateDataService;
  final AllocationSnapshotCoordinator _allocationSnapshotCoordinator;

  Future<void> generateTemplateData() async {
    emit(
      const SettingsMaintenanceState(
        status: SettingsMaintenanceRunning(
          SettingsMaintenanceAction.generateTemplateData,
        ),
      ),
    );

    try {
      await _templateDataService.resetAndSeed();
      _allocationSnapshotCoordinator.requestRefreshNow(
        AllocationSnapshotRefreshReason.manual,
      );

      emit(
        const SettingsMaintenanceState(
          status: SettingsMaintenanceSuccess(
            SettingsMaintenanceAction.generateTemplateData,
          ),
        ),
      );

      emit(SettingsMaintenanceState.idle());
    } catch (e) {
      emit(
        SettingsMaintenanceState(
          status: SettingsMaintenanceFailure(
            action: SettingsMaintenanceAction.generateTemplateData,
            message: 'Failed to generate template data: $e',
          ),
        ),
      );

      emit(SettingsMaintenanceState.idle());
    }
  }
}
