import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_tile_capabilities.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/agenda_section_renderer.dart';

import '../../../../helpers/test_imports.dart';

import 'package:taskly_domain/taskly_domain.dart';
void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('AgendaSectionRenderer (day-cards feed)', () {
    const params = AgendaSectionParamsV2(
      dateField: AgendaDateFieldV2.deadlineDate,
      layout: AgendaLayoutV2.dayCardsFeed,
    );

    AgendaDateGroup groupFor(DateTime date, AgendaItem item) {
      return AgendaDateGroup(
        date: date,
        semanticLabel: 'n/a',
        formattedHeader: 'n/a',
        items: [item],
      );
    }

    testWidgetsSafe('"This month" range end is end-exclusive', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final nextMonthStart = DateTime(today.year, today.month + 1, 1);
      final lastDayThisMonth = nextMonthStart.subtract(const Duration(days: 1));

      final inRangeTask = TestData.task(
        id: 'task-in-range',
        name: 'Task in this month',
        now: now,
        deadlineDate: lastDayThisMonth,
      );
      final outOfRangeTask = TestData.task(
        id: 'task-out-of-range',
        name: 'Task next month',
        now: now,
        deadlineDate: nextMonthStart,
      );

      final agendaData = AgendaData(
        focusDate: today,
        groups: [
          groupFor(
            lastDayThisMonth,
            AgendaItem(
              entityType: EntityType.task,
              entityId: inRangeTask.id,
              name: inRangeTask.name,
              tag: AgendaDateTag.due,
              tileCapabilities: const EntityTileCapabilities(),
              task: inRangeTask,
            ),
          ),
          groupFor(
            nextMonthStart,
            AgendaItem(
              entityType: EntityType.task,
              entityId: outOfRangeTask.id,
              name: outOfRangeTask.name,
              tag: AgendaDateTag.due,
              tileCapabilities: const EntityTileCapabilities(),
              task: outOfRangeTask,
            ),
          ),
        ],
      );

      final data =
          SectionDataResult.agenda(agendaData: agendaData)
              as AgendaSectionResult;

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: AgendaSectionRenderer(
            params: params,
            data: data,
            entityStyle: const EntityStyleV1(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);

      final inRangeHeader = DateFormat('EEE, MMM d').format(lastDayThisMonth);
      final outOfRangeHeader = DateFormat('EEE, MMM d').format(nextMonthStart);

      expect(find.text(inRangeHeader), findsWidgets);
      expect(find.text(outOfRangeHeader), findsNothing);
    });

    testWidgetsSafe(
      '"Next 7 days" includes today..today+7 and excludes today+8',
      (tester) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final day7 = today.add(const Duration(days: 7));
        final day8 = today.add(const Duration(days: 8));

        final todayTask = TestData.task(
          id: 'task-today',
          name: 'Task today',
          now: now,
          deadlineDate: today,
        );
        final day7Task = TestData.task(
          id: 'task-day7',
          name: 'Task day 7',
          now: now,
          deadlineDate: day7,
        );
        final day8Task = TestData.task(
          id: 'task-day8',
          name: 'Task day 8',
          now: now,
          deadlineDate: day8,
        );

        final agendaData = AgendaData(
          focusDate: today,
          groups: [
            groupFor(
              today,
              AgendaItem(
                entityType: EntityType.task,
                entityId: todayTask.id,
                name: todayTask.name,
                tag: AgendaDateTag.due,
                tileCapabilities: const EntityTileCapabilities(),
                task: todayTask,
              ),
            ),
            groupFor(
              day7,
              AgendaItem(
                entityType: EntityType.task,
                entityId: day7Task.id,
                name: day7Task.name,
                tag: AgendaDateTag.due,
                tileCapabilities: const EntityTileCapabilities(),
                task: day7Task,
              ),
            ),
            groupFor(
              day8,
              AgendaItem(
                entityType: EntityType.task,
                entityId: day8Task.id,
                name: day8Task.name,
                tag: AgendaDateTag.due,
                tileCapabilities: const EntityTileCapabilities(),
                task: day8Task,
              ),
            ),
          ],
        );

        final data =
            SectionDataResult.agenda(agendaData: agendaData)
                as AgendaSectionResult;

        await pumpLocalizedApp(
          tester,
          home: Scaffold(
            body: AgendaSectionRenderer(
              params: params,
              data: data,
              entityStyle: const EntityStyleV1(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Open Range sheet and switch to Next 7 days.
        await tester.tap(find.text('This month'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text('Range'), findsOneWidget);
        await tester.tap(find.text('Next 7 days'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text('Next 7 days'), findsOneWidget);
        expect(find.text('Today'), findsWidgets);

        final day7Header = DateFormat('EEE, MMM d').format(day7);
        final day8Header = DateFormat('EEE, MMM d').format(day8);

        expect(find.text(day7Header), findsWidgets);
        expect(find.text(day8Header), findsNothing);
      },
    );

    testWidgetsSafe(
      'in-progress section collapses and expands per day',
      (tester) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final task = TestData.task(
          id: 'task-in-progress',
          name: 'Task in progress',
          now: now,
          startDate: today.subtract(const Duration(days: 1)),
          deadlineDate: today.add(const Duration(days: 5)),
        );

        final agendaData = AgendaData(
          focusDate: today,
          groups: [
            groupFor(
              today,
              AgendaItem(
                entityType: EntityType.task,
                entityId: task.id,
                name: task.name,
                tag: AgendaDateTag.inProgress,
                tileCapabilities: const EntityTileCapabilities(),
                task: task,
              ),
            ),
          ],
        );

        final data =
            SectionDataResult.agenda(agendaData: agendaData)
                as AgendaSectionResult;

        await pumpLocalizedApp(
          tester,
          home: Scaffold(
            body: AgendaSectionRenderer(
              params: params,
              data: data,
              entityStyle: const EntityStyleV1(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Collapsed state shows the summary row.
        expect(find.text('In progress (1)'), findsOneWidget);
        expect(find.text('Task in progress'), findsNothing);

        // Expand reveals items.
        await tester.tap(find.text('In progress (1)'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Hide'), findsOneWidget);
        expect(find.text('Task in progress'), findsOneWidget);
      },
    );
  });
}
