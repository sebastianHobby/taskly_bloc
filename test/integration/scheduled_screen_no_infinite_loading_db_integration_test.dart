import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/data/allocation/repositories/allocation_snapshot_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_specs.dart';
import 'package:taskly_bloc/domain/screens/runtime/agenda_section_data_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data_interpreter.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_service.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/agenda_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/services/time/home_day_key_service.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_state.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/data_list_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/attention_banner_section_interpreter_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/entity_header_section_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/hierarchy_value_project_task_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/interleaved_list_section_interpreter_v2.dart';

import '../helpers/integration_test_helpers.dart';
import '../helpers/test_db.dart';
import '../mocks/fake_id_generator.dart';
import '../mocks/repository_mocks.dart';

class _MockDataListSectionInterpreterV2 extends Mock
    implements DataListSectionInterpreterV2 {}

class _MockInterleavedListSectionInterpreterV2 extends Mock
    implements InterleavedListSectionInterpreterV2 {}

class _MockHierarchyValueProjectTaskSectionInterpreterV2 extends Mock
    implements HierarchyValueProjectTaskSectionInterpreterV2 {}

class _MockEntityHeaderSectionInterpreter extends Mock
    implements EntityHeaderSectionInterpreter {}

class _MockAttentionBannerSectionInterpreterV1 extends Mock
    implements AttentionBannerSectionInterpreterV1 {}

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

        final allocationSnapshotRepository = AllocationSnapshotRepository(
          db: db,
        );

        final agendaDataService = AgendaSectionDataService(
          taskRepository: taskRepository,
          projectRepository: projectRepository,
        );

        final sectionDataService = SectionDataService(
          taskRepository: taskRepository,
          projectRepository: projectRepository,
          valueRepository: valueRepository,
          allocationSnapshotRepository: allocationSnapshotRepository,
          agendaDataService: agendaDataService,
          dayKeyService: dayKeyService,
        );

        final specInterpreter = ScreenSpecDataInterpreter(
          settingsRepository: settingsRepository,
          valueRepository: valueRepository,
          taskListInterpreter: _MockDataListSectionInterpreterV2(),
          projectListInterpreter: _MockDataListSectionInterpreterV2(),
          valueListInterpreter: _MockDataListSectionInterpreterV2(),
          interleavedListInterpreter:
              _MockInterleavedListSectionInterpreterV2(),
          hierarchyValueProjectTaskInterpreter:
              _MockHierarchyValueProjectTaskSectionInterpreterV2(),
          agendaInterpreter: AgendaSectionInterpreterV2(
            sectionDataService: sectionDataService,
          ),
          attentionBannerInterpreter:
              _MockAttentionBannerSectionInterpreterV1(),
          entityHeaderInterpreter: _MockEntityHeaderSectionInterpreter(),
        );

        final bloc = ScreenSpecBloc(interpreter: specInterpreter);

        try {
          bloc.add(ScreenSpecLoadEvent(spec: SystemScreenSpecs.scheduled));

          final terminalState = await bloc.stream
              .firstWhere(
                (s) => s is ScreenSpecLoadedState || s is ScreenSpecErrorState,
              )
              .timeout(const Duration(seconds: 2));

          expect(
            terminalState,
            anyOf(isA<ScreenSpecLoadedState>(), isA<ScreenSpecErrorState>()),
          );
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
