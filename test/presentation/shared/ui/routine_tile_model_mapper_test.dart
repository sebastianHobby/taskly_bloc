@Tags(['widget'])
library;

import 'package:flutter/material.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/ui/routine_tile_model_mapper.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

class _RoutineTileHarness extends StatelessWidget {
  const _RoutineTileHarness({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final labels = buildRoutineExecutionLabels(
      context,
      completed: completed,
    );

    final data = TasklyRoutineRowData(
      id: 'routine-1',
      title: 'Morning Flow',
      completed: completed,
      labels: labels,
    );

    final row = TasklyRowSpec.routine(
      key: 'routine-row',
      data: data,
      actions: TasklyRoutineRowActions(
        onPrimaryAction: () {},
      ),
    );

    return TasklyFeedRenderer.buildRow(
      row,
      context: context,
    );
  }
}

void main() {
  testWidgetsSafe(
    'routine tile shows unlog label when completed',
    (tester) async {
      await pumpLocalizedApp(
        tester,
        home: const _RoutineTileHarness(completed: true),
      );
      await tester.pumpForStream();

      final l10n = tester.element(find.byType(_RoutineTileHarness)).l10n;
      expect(find.text(l10n.routineUnlogLabel), findsOneWidget);
    },
  );
}
