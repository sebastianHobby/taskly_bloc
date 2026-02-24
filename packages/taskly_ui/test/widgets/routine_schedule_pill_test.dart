@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgetsSafe(
    'scheduled routine pills keep weekday letters for all states and render no status icons',
    (tester) async {
      final spec = TasklyFeedSpec.content(
        sections: [
          TasklySectionSpec.standardList(
            id: 'section',
            rows: [
              TasklyRowSpec.routine(
                key: 'routine',
                data: const TasklyRoutineRowData(
                  id: 'routine-1',
                  title: 'Morning routine',
                  scheduleRow: TasklyRoutineScheduleRowData(
                    days: [
                      TasklyRoutineScheduleDay(
                        label: 'M',
                        isToday: false,
                        state: TasklyRoutineScheduleDayState.loggedScheduled,
                      ),
                      TasklyRoutineScheduleDay(
                        label: 'T',
                        isToday: false,
                        state: TasklyRoutineScheduleDayState.missedScheduled,
                      ),
                      TasklyRoutineScheduleDay(
                        label: 'W',
                        isToday: true,
                        state: TasklyRoutineScheduleDayState.skippedScheduled,
                      ),
                      TasklyRoutineScheduleDay(
                        label: 'F',
                        isToday: false,
                        state: TasklyRoutineScheduleDayState.scheduled,
                      ),
                    ],
                  ),
                ),
                actions: TasklyRoutineRowActions(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TasklyFeedRenderer(spec: spec),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byIcon(Icons.skip_next_rounded), findsNothing);
      expect(find.byIcon(Icons.remove_rounded), findsNothing);
    },
  );
}
