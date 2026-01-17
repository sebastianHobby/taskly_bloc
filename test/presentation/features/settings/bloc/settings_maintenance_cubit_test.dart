/// Unit tests for SettingsMaintenanceCubit.
library;

import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/settings_maintenance_cubit.dart';

import '../../../../helpers/test_imports.dart';

import 'package:taskly_domain/taskly_domain.dart';
class _MockTemplateDataService extends Mock implements TemplateDataService {}

class _MockLocalDataMaintenanceService extends Mock
    implements LocalDataMaintenanceService {}

class _MockAllocationSnapshotCoordinator extends Mock
    implements AllocationSnapshotCoordinator {}

void main() {
  setUpAll(setUpAllTestEnvironment);

  group('SettingsMaintenanceCubit', () {
    late _MockTemplateDataService templateDataService;
    late _MockLocalDataMaintenanceService localDataMaintenanceService;
    late _MockAllocationSnapshotCoordinator allocationSnapshotCoordinator;

    SettingsMaintenanceCubit buildCubit() {
      return SettingsMaintenanceCubit(
        templateDataService: templateDataService,
        localDataMaintenanceService: localDataMaintenanceService,
        allocationSnapshotCoordinator: allocationSnapshotCoordinator,
      );
    }

    setUp(() {
      templateDataService = _MockTemplateDataService();
      localDataMaintenanceService = _MockLocalDataMaintenanceService();
      allocationSnapshotCoordinator = _MockAllocationSnapshotCoordinator();

      when(() => templateDataService.resetAndSeed()).thenAnswer((_) async {});
      when(
        () => localDataMaintenanceService.clearLocalData(),
      ).thenAnswer((_) async {});
      when(
        () => allocationSnapshotCoordinator.requestRefreshNow(any()),
      ).thenReturn(null);
    });

    blocTest<SettingsMaintenanceCubit, SettingsMaintenanceState>(
      'generateTemplateData emits running -> success -> idle',
      build: buildCubit,
      act: (cubit) => cubit.generateTemplateData(),
      expect: () => [
        isA<SettingsMaintenanceState>().having(
          (s) => s.status,
          'status',
          isA<SettingsMaintenanceRunning>().having(
            (s) => s.action,
            'action',
            SettingsMaintenanceAction.generateTemplateData,
          ),
        ),
        isA<SettingsMaintenanceState>().having(
          (s) => s.status,
          'status',
          isA<SettingsMaintenanceSuccess>().having(
            (s) => s.action,
            'action',
            SettingsMaintenanceAction.generateTemplateData,
          ),
        ),
        isA<SettingsMaintenanceState>().having(
          (s) => s.status,
          'status',
          isA<SettingsMaintenanceIdle>(),
        ),
      ],
      verify: (_) {
        verify(() => templateDataService.resetAndSeed()).called(1);
        verify(
          () => allocationSnapshotCoordinator.requestRefreshNow(
            AllocationSnapshotRefreshReason.manual,
          ),
        ).called(1);
      },
    );

    blocTest<SettingsMaintenanceCubit, SettingsMaintenanceState>(
      'clearLocalData emits running -> success -> idle',
      build: buildCubit,
      act: (cubit) => cubit.clearLocalData(),
      expect: () => [
        isA<SettingsMaintenanceState>().having(
          (s) => s.status,
          'status',
          isA<SettingsMaintenanceRunning>().having(
            (s) => s.action,
            'action',
            SettingsMaintenanceAction.clearLocalData,
          ),
        ),
        isA<SettingsMaintenanceState>().having(
          (s) => s.status,
          'status',
          isA<SettingsMaintenanceSuccess>().having(
            (s) => s.action,
            'action',
            SettingsMaintenanceAction.clearLocalData,
          ),
        ),
        isA<SettingsMaintenanceState>().having(
          (s) => s.status,
          'status',
          isA<SettingsMaintenanceIdle>(),
        ),
      ],
      verify: (_) {
        verify(() => localDataMaintenanceService.clearLocalData()).called(1);
      },
    );

    blocTest<SettingsMaintenanceCubit, SettingsMaintenanceState>(
      'generateTemplateData emits failure -> idle on error',
      build: () {
        when(() => templateDataService.resetAndSeed()).thenThrow(
          Exception('boom'),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.generateTemplateData(),
      expect: () => [
        isA<SettingsMaintenanceState>().having(
          (s) => s.status,
          'status',
          isA<SettingsMaintenanceRunning>().having(
            (s) => s.action,
            'action',
            SettingsMaintenanceAction.generateTemplateData,
          ),
        ),
        isA<SettingsMaintenanceState>().having(
          (s) => s.status,
          'status',
          isA<SettingsMaintenanceFailure>().having(
            (s) => s.action,
            'action',
            SettingsMaintenanceAction.generateTemplateData,
          ),
        ),
        isA<SettingsMaintenanceState>().having(
          (s) => s.status,
          'status',
          isA<SettingsMaintenanceIdle>(),
        ),
      ],
      verify: (_) {
        verifyNever(
          () => allocationSnapshotCoordinator.requestRefreshNow(any()),
        );
      },
    );
  });
}
