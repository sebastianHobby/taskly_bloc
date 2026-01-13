import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/performance/performance_logger.dart';
import 'package:taskly_bloc/data/allocation/repositories/allocation_snapshot_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/data/screens/maintenance/screen_seeder.dart';
import 'package:taskly_bloc/data/screens/repositories/screen_definitions_repository.dart';
import 'package:taskly_bloc/data/screens/repositories/screen_definitions_repository_impl.dart';
import 'package:taskly_bloc/domain/allocation/engine/allocation_orchestrator.dart';
import 'package:taskly_bloc/domain/screens/runtime/agenda_section_data_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data_interpreter.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_service.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/agenda_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter_registry.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_params_codec.dart';
import 'package:taskly_bloc/domain/services/time/home_day_key_service.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_state.dart';

import '../helpers/integration_test_helpers.dart';
import '../helpers/test_db.dart';
import '../mocks/fake_id_generator.dart';
import '../mocks/feature_mocks.dart';
import '../mocks/repository_mocks.dart';

void main() {
  group('Scheduled screen (integration)', () {
    testIntegration(
      'loads without hanging (agenda streams emit)',
      () async {
        final db = createTestDb();
        final idGenerator = FakeIdGenerator();

        final occurrenceExpander = MockOccurrenceStreamExpanderContract();
        final occurrenceWriteHelper = MockOccurrenceWriteHelperContract();

        final valueRepository = ValueRepository(
          driftDb: db,
          idGenerator: idGenerator,
        );
        final projectRepository = ProjectRepository(
          driftDb: db,
          occurrenceExpander: occurrenceExpander,
          occurrenceWriteHelper: occurrenceWriteHelper,
          idGenerator: idGenerator,
        );
        final taskRepository = TaskRepository(
          driftDb: db,
          occurrenceExpander: occurrenceExpander,
          occurrenceWriteHelper: occurrenceWriteHelper,
          idGenerator: idGenerator,
        );

        final settingsRepository = SettingsRepository(driftDb: db);

        final dayKeyService = HomeDayKeyService(
          settingsRepository: settingsRepository,
        );
        await dayKeyService.ensureInitialized();
        dayKeyService.start();

        final analyticsService = MockAnalyticsService();
        when(
          () => analyticsService.getRecentCompletionsByValue(
            days: any<int>(named: 'days'),
          ),
        ).thenAnswer((_) async => <String, int>{});

        final allocationSnapshotRepository = AllocationSnapshotRepository(
          db: db,
        );
        final allocationOrchestrator = AllocationOrchestrator(
          taskRepository: taskRepository,
          valueRepository: valueRepository,
          settingsRepository: settingsRepository,
          analyticsService: analyticsService,
          projectRepository: projectRepository,
          dayKeyService: dayKeyService,
          allocationSnapshotRepository: allocationSnapshotRepository,
        );

        final agendaDataService = AgendaSectionDataService(
          taskRepository: taskRepository,
          projectRepository: projectRepository,
        );

        final sectionDataService = SectionDataService(
          taskRepository: taskRepository,
          projectRepository: projectRepository,
          valueRepository: valueRepository,
          allocationOrchestrator: allocationOrchestrator,
          allocationSnapshotRepository: allocationSnapshotRepository,
          agendaDataService: agendaDataService,
          settingsRepository: settingsRepository,
          dayKeyService: dayKeyService,
        );

        final screenRepository = ScreenDefinitionsRepository(
          databaseRepository: ScreenDefinitionsRepositoryImpl(db),
        );

        final screenSeeder = ScreenSeeder(db: db, idGenerator: idGenerator);
        await screenSeeder.seedSystemScreens();

        final interpreterRegistry = SectionTemplateInterpreterRegistry([
          AgendaSectionInterpreterV2(sectionDataService: sectionDataService),
        ]);

        final interpreter = ScreenDataInterpreter(
          interpreterRegistry: interpreterRegistry,
          paramsCodec: SectionTemplateParamsCodec(),
          settingsRepository: settingsRepository,
        );

        final bloc = ScreenBloc(
          screenRepository: screenRepository,
          interpreter: interpreter,
          performanceLogger: PerformanceLogger(),
        );

        try {
          bloc.add(const ScreenEvent.loadById(screenId: 'scheduled'));

          final terminalState = await bloc.stream
              .firstWhere(
                (s) => s is ScreenLoadedState || s is ScreenErrorState,
              )
              .timeout(const Duration(seconds: 2));

          expect(terminalState, isA<ScreenLoadedState>());
        } finally {
          await bloc.close();
          await closeTestDb(db);
        }
      },
      timeout: const Duration(seconds: 10),
      tags: 'integration',
    );
  });
}
