import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/features/screens/default_system_screen_provider.dart';
import 'package:taskly_bloc/data/features/screens/repositories/screen_definitions_repository.dart';
import 'package:taskly_bloc/data/features/screens/repositories/screen_definitions_repository_impl.dart';
import 'package:taskly_bloc/data/repositories/allocation_snapshot_repository.dart';
import 'package:taskly_bloc/data/repositories/attention_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/data/services/screen_seeder.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_orchestrator.dart';
import 'package:taskly_bloc/domain/services/attention/attention_evaluator.dart';
import 'package:taskly_bloc/domain/services/attention/attention_temporal_invalidation_service.dart';
import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/services/screens/agenda_section_data_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_service.dart';
import 'package:taskly_bloc/domain/services/screens/templates/allocation_alerts_section_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/allocation_section_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/check_in_summary_section_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_interpreter_registry.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_params_codec.dart';
import 'package:taskly_bloc/domain/services/screens/templates/static_section_interpreter.dart';
import 'package:taskly_bloc/domain/services/time/app_lifecycle_service.dart';
import 'package:taskly_bloc/domain/services/time/home_day_key_service.dart';
import 'package:taskly_bloc/domain/services/time/temporal_trigger_service.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';

import '../helpers/test_db.dart';
import '../helpers/integration_test_helpers.dart';
import '../mocks/fake_id_generator.dart';
import '../mocks/feature_mocks.dart';
import '../mocks/repository_mocks.dart';

void main() {
  group('My Day screen (integration)', () {
    testIntegration(
      'loads without hanging (combineLatest emits)',
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
            days: any(named: 'days'),
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

        final attentionRepository = AttentionRepository(db: db);
        final attentionEvaluator = AttentionEvaluator(
          attentionRepository: attentionRepository,
          allocationSnapshotRepository: allocationSnapshotRepository,
          taskRepository: taskRepository,
          projectRepository: projectRepository,
          settingsRepository: settingsRepository,
          dayKeyService: dayKeyService,
        );

        final lifecycleService = AppLifecycleService();
        final temporalTriggerService = TemporalTriggerService(
          dayKeyService: dayKeyService,
          lifecycleService: lifecycleService,
        );
        final attentionTemporalInvalidationService =
            AttentionTemporalInvalidationService(
              temporalTriggerService: temporalTriggerService,
            )..start();

        const systemScreenProvider = DefaultSystemScreenProvider();
        final screenRepository = ScreenDefinitionsRepository(
          databaseRepository: ScreenDefinitionsRepositoryImpl(
            db,
            idGenerator,
            systemScreenProvider,
          ),
        );

        final screenSeeder = ScreenSeeder(db: db, idGenerator: idGenerator);
        await screenSeeder.seedSystemScreens();

        final interpreterRegistry = SectionTemplateInterpreterRegistry([
          AllocationSectionInterpreter(sectionDataService: sectionDataService),
          AllocationAlertsSectionInterpreter(
            attentionEvaluator: attentionEvaluator,
          ),
          CheckInSummarySectionInterpreter(
            attentionEvaluator: attentionEvaluator,
            attentionTemporalInvalidationService:
                attentionTemporalInvalidationService,
          ),
          StaticSectionInterpreter(
            templateId: SectionTemplateId.myDayFocusModeRequired,
          ),
        ]);

        final interpreter = ScreenDataInterpreter(
          interpreterRegistry: interpreterRegistry,
          paramsCodec: SectionTemplateParamsCodec(),
          settingsRepository: settingsRepository,
        );

        final bloc = ScreenBloc(
          screenRepository: screenRepository,
          interpreter: interpreter,
        );

        try {
          bloc.add(const ScreenEvent.loadById(screenId: 'my_day'));

          final terminalState = await bloc.stream
              .firstWhere(
                (s) => s is ScreenLoadedState || s is ScreenErrorState,
              )
              .timeout(const Duration(seconds: 2));

          expect(terminalState, isA<ScreenLoadedState>());
        } finally {
          await bloc.close();
          await attentionTemporalInvalidationService.dispose();
          await temporalTriggerService.dispose();
          await lifecycleService.dispose();
          await closeTestDb(db);
        }
      },
      timeout: const Duration(seconds: 10),
      tags: 'integration',
    );
  });
}
