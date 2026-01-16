/// Regression test for Scheduled screen rendering (blank screen).
///
/// This verifies that a screen with an agenda section can be loaded through
/// `UnifiedScreenPageFromSpec` without throwing during layout.
library;

import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data_interpreter.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_tile_capabilities.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/presentation/screens/view/unified_screen_spec_page.dart';

import '../../../../helpers/test_imports.dart';

class MockScreenSpecDataInterpreter extends Mock
    implements ScreenSpecDataInterpreter {}

class MockEntityActionService extends Mock implements EntityActionService {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('Scheduled screen (widget) regression', () {
    late MockScreenSpecDataInterpreter interpreter;
    late MockEntityActionService entityActionService;

    final spec = ScreenSpec(
      id: 'scheduled_test',
      screenKey: 'scheduled',
      name: 'Scheduled',
      template: const ScreenTemplateSpec.standardScaffoldV1(),
      // Keep chrome empty so the template doesn't build the AddTask FAB (DI).
      chrome: ScreenChrome.empty,
      modules: SlottedModules(
        primary: [
          ScreenModuleSpec.agendaV2(
            params: const AgendaSectionParamsV2(
              dateField: AgendaDateFieldV2.deadlineDate,
              layout: AgendaLayoutV2.dayCardsFeed,
            ),
          ),
        ],
      ),
    );

    setUp(() async {
      await getIt.reset();
      addTearDown(getIt.reset);

      interpreter = MockScreenSpecDataInterpreter();
      entityActionService = MockEntityActionService();

      registerFallbackValue(spec);

      getIt.registerSingleton<ScreenSpecDataInterpreter>(interpreter);
      getIt.registerSingleton<EntityActionService>(entityActionService);
    });

    testWidgetsSafe(
      'loads and lays out agenda section without throwing',
      (tester) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final task = TestData.task(
          id: 'task-1',
          name: 'Task with deadline',
          now: now,
          deadlineDate: today.add(const Duration(days: 1)),
        );

        final agendaData = AgendaData(
          focusDate: today,
          groups: [
            AgendaDateGroup(
              date: today,
              semanticLabel: 'Today',
              formattedHeader: 'Today',
              items: [
                AgendaItem(
                  entityType: EntityType.task,
                  entityId: task.id,
                  name: task.name,
                  tag: AgendaDateTag.due,
                  tileCapabilities: const EntityTileCapabilities(),
                  task: task,
                ),
              ],
            ),
          ],
        );

        final section = SectionVm.agendaV2(
          index: 0,
          params: const AgendaSectionParamsV2(
            dateField: AgendaDateFieldV2.deadlineDate,
            layout: AgendaLayoutV2.dayCardsFeed,
          ),
          data: SectionDataResult.agenda(agendaData: agendaData),
          entityStyle: const EntityStyleV1(),
        );

        final data = ScreenSpecData(
          spec: spec,
          template: spec.template,
          sections: SlottedSectionVms(primary: [section]),
        );

        when(() => interpreter.watchScreen(any())).thenAnswer(
          (_) => Stream.value(data),
        );

        await pumpLocalizedApp(
          tester,
          home: UnifiedScreenPageFromSpec(spec: spec),
        );

        // Give the BLoC a chance to transition off loading.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // If the scheduled agenda layout regresses, Flutter will report a
        // framework exception (often unbounded height/flex constraints).
        expect(tester.takeException(), isNull);

        // Day-cards feed header shows the current preset label.
        expect(find.text('This month'), findsOneWidget);

        // Opening the range picker sheet should show a "Range" title.
        await tester.tap(find.text('This month'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Range'), findsOneWidget);

        // Day card header must include an absolute date string.
        final absolute = DateFormat('EEE, MMM d').format(today);
        expect(find.text(absolute), findsWidgets);

        expect(find.text('Scheduled'), findsOneWidget);
      },
      timeout: const Duration(seconds: 10),
    );
  });
}
