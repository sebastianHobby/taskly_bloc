import 'package:flutter/material.dart';

import '../../../../helpers/test_imports.dart';

import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/agenda_section_renderer.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('AgendaSectionRenderer (smoke)', () {
    testWidgetsSafe('renders a non-empty agenda', (tester) async {
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
            ],
          ),
        ],
      );

      final result = SectionDataResult.agenda(agendaData: agendaData);
      final agendaResult = result as AgendaSectionResult;

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: AgendaSectionRenderer(data: agendaResult),
        ),
      );

      await tester.pump();

      expect(find.byType(AgendaSectionRenderer), findsOneWidget);
      expect(find.text('No scheduled items'), findsNothing);
    });

    testWidgetsSafe('renders empty state when no items', (tester) async {
      final today = DateTime.utc(2026, 1, 1);

      final agendaData = AgendaData(
        focusDate: today,
        groups: const [],
      );

      final result = SectionDataResult.agenda(agendaData: agendaData);
      final agendaResult = result as AgendaSectionResult;

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: AgendaSectionRenderer(data: agendaResult),
        ),
      );

      await tester.pump();

      expect(find.text('No scheduled items'), findsOneWidget);
    });
  });
}
