@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/hierarchy_value_project_task_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/my_day_ranked_tasks_v1_module_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/params/hierarchy_value_project_task_section_params_v2.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_mvp_bloc.dart';

import '../../../fixtures/test_data.dart';
import '../../../helpers/bloc_test_patterns.dart';
import '../../../helpers/test_environment.dart';
import '../../../helpers/test_imports.dart';

class MockHierarchyValueProjectTaskSectionInterpreterV2 extends Mock
    implements HierarchyValueProjectTaskSectionInterpreterV2 {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();

    // Needed for mocktail `any()` since `watch()` takes a non-nullable param.
    registerFallbackValue(
      const HierarchyValueProjectTaskSectionParamsV2(
        sources: <DataConfig>[DataConfig.allocationSnapshotTasksToday()],
      ),
    );
  });

  setUp(setUpTestEnvironment);

  group('MyDayMvpBloc', () {
    late MockHierarchyValueProjectTaskSectionInterpreterV2 mockInterpreter;
    late TestStreamController<SectionDataResult> controller;

    setUp(() {
      mockInterpreter = MockHierarchyValueProjectTaskSectionInterpreterV2();
      controller = TestStreamController<SectionDataResult>();

      when(
        () => mockInterpreter.watch(any()),
      ).thenAnswer((_) => controller.stream);
    });

    tearDown(() async {
      await controller.close();
    });

    MyDayMvpBloc buildBloc() {
      final interpreter = MyDayRankedTasksV1ModuleInterpreter(
        hierarchyValueProjectTaskInterpreter: mockInterpreter,
      );

      return MyDayMvpBloc(interpreter: interpreter);
    }

    blocTestSafe<MyDayMvpBloc, MyDayMvpState>(
      'emits MyDayMvpLoaded with correct progress counts',
      build: buildBloc,
      act: (bloc) {
        final a = TestData.task(completed: true);
        final b = TestData.task(completed: false);

        controller.emit(
          SectionDataResult.hierarchyValueProjectTaskV2(
            items: <ScreenItem>[ScreenItem.task(a), ScreenItem.task(b)],
          ),
        );
      },
      expect: () => <dynamic>[
        isA<MyDayMvpLoaded>()
            .having((s) => s.hero.doneCount, 'doneCount', 1)
            .having((s) => s.hero.totalCount, 'totalCount', 2)
            .having(
              (s) => s.rankedTasks.items.length,
              'items.length',
              2,
            ),
      ],
    );

    blocTestSafe<MyDayMvpBloc, MyDayMvpState>(
      'emits MyDayMvpError when interpreter returns unexpected result type',
      build: buildBloc,
      act: (bloc) {
        controller.emit(const SectionDataResult.dataV2(items: <ScreenItem>[]));
      },
      expect: () => <dynamic>[
        isA<MyDayMvpError>().having(
          (s) => s.message,
          'message',
          contains('Unexpected My Day result type'),
        ),
      ],
    );

    blocTestSafe<MyDayMvpBloc, MyDayMvpState>(
      'emits MyDayMvpError when interpreter stream errors',
      build: buildBloc,
      act: (bloc) {
        controller.emitError(StateError('boom'));
      },
      expect: () => <dynamic>[
        isA<MyDayMvpError>().having(
          (s) => s.message,
          'message',
          contains('Failed to load My Day data'),
        ),
      ],
    );
  });
}
