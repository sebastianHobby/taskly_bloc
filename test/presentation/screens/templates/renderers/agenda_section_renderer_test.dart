import 'package:flutter/material.dart';

import '../../../../helpers/test_imports.dart';

import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/agenda_section_renderer.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('AgendaSectionRenderer', () {
    testWidgetsSafe('search bottom sheet filters items by name', (
      tester,
    ) async {
      final today = DateTime.utc(2026, 1, 1);

      final agendaData = AgendaData(
        focusDate: today,
        groups: [
          AgendaDateGroup(
            date: today,
            semanticLabel: 'Today',
            formattedHeader: 'Wed, Jan 1',
            items: [
              AgendaItem(
                entityType: 'task',
                entityId: 't1',
                name: 'Task Alpha',
                tag: AgendaDateTag.due,
                task: TestData.task(id: 't1', name: 'Task Alpha'),
              ),
              AgendaItem(
                entityType: 'task',
                entityId: 't2',
                name: 'Task Beta',
                tag: AgendaDateTag.starts,
                task: TestData.task(id: 't2', name: 'Task Beta'),
              ),
            ],
          ),
        ],
        loadedHorizonEnd: today.add(const Duration(days: 14)),
      );

      final result = SectionDataResult.agenda(agendaData: agendaData);
      final agendaResult = result as AgendaSectionResult;

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: AgendaSectionRenderer(
            params: const AgendaSectionParamsV2(
              dateField: AgendaDateFieldV2.deadlineDate,
            ),
            data: agendaResult,
            entityStyle: const EntityStyleV1(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Task Alpha'), findsOneWidget);
      expect(find.text('Task Beta'), findsOneWidget);

      await tester.tap(find.byTooltip('Search'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'alpha');
      await tester.pump();

      await tester.tap(find.text('Apply'));
      await tester.pump();

      expect(find.text('Task Alpha'), findsOneWidget);
      expect(find.text('Task Beta'), findsNothing);
    });

    testWidgetsSafe('filter sheet can hide projects', (tester) async {
      final today = DateTime.utc(2026, 1, 1);

      final agendaData = AgendaData(
        focusDate: today,
        groups: [
          AgendaDateGroup(
            date: today,
            semanticLabel: 'Today',
            formattedHeader: 'Wed, Jan 1',
            items: [
              AgendaItem(
                entityType: 'task',
                entityId: 't1',
                name: 'Task 1',
                tag: AgendaDateTag.due,
                task: TestData.task(id: 't1', name: 'Task 1'),
              ),
              AgendaItem(
                entityType: 'project',
                entityId: 'p1',
                name: 'Project 1',
                tag: AgendaDateTag.starts,
                project: TestData.project(id: 'p1', name: 'Project 1'),
              ),
            ],
          ),
        ],
        loadedHorizonEnd: today.add(const Duration(days: 14)),
      );

      final result = SectionDataResult.agenda(agendaData: agendaData);
      final agendaResult = result as AgendaSectionResult;

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: AgendaSectionRenderer(
            params: const AgendaSectionParamsV2(
              dateField: AgendaDateFieldV2.deadlineDate,
            ),
            data: agendaResult,
            entityStyle: const EntityStyleV1(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Project 1'), findsOneWidget);

      await tester.tap(find.byTooltip('Filter'));
      await tester.pump();

      // Select Tasks-only.
      await tester.tap(find.text('Tasks'));
      await tester.pump();

      await tester.tap(find.text('Apply'));
      await tester.pump();

      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Project 1'), findsNothing);
    });

    testWidgetsSafe('filter sheet can hide tag types', (tester) async {
      final today = DateTime.utc(2026, 1, 1);

      final agendaData = AgendaData(
        focusDate: today,
        groups: [
          AgendaDateGroup(
            date: today,
            semanticLabel: 'Today',
            formattedHeader: 'Wed, Jan 1',
            items: [
              AgendaItem(
                entityType: 'task',
                entityId: 't1',
                name: 'Due Task',
                tag: AgendaDateTag.due,
                task: TestData.task(id: 't1', name: 'Due Task'),
              ),
              AgendaItem(
                entityType: 'task',
                entityId: 't2',
                name: 'Start Task',
                tag: AgendaDateTag.starts,
                task: TestData.task(id: 't2', name: 'Start Task'),
              ),
            ],
          ),
        ],
        loadedHorizonEnd: today.add(const Duration(days: 14)),
      );

      final result = SectionDataResult.agenda(agendaData: agendaData);
      final agendaResult = result as AgendaSectionResult;

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: AgendaSectionRenderer(
            params: const AgendaSectionParamsV2(
              dateField: AgendaDateFieldV2.deadlineDate,
            ),
            data: agendaResult,
            entityStyle: const EntityStyleV1(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Due Task'), findsOneWidget);
      expect(find.text('Start Task'), findsOneWidget);

      await tester.tap(find.byTooltip('Filter'));
      await tester.pump();

      // Toggle Due off.
      await tester.tap(find.text('Due'));
      await tester.pump();

      await tester.tap(find.text('Apply'));
      await tester.pump();

      expect(find.text('Due Task'), findsNothing);
      expect(find.text('Start Task'), findsOneWidget);
    });
  });
}
