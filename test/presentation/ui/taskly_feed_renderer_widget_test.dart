@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import '../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('renders empty state with action', (tester) async {
    var tapped = false;
    final spec = TasklyFeedSpec.empty(
      empty: TasklyEmptyStateSpec(
        icon: Icons.inbox_outlined,
        title: 'Nothing here',
        description: 'Create your first task.',
        actionLabel: 'Create task',
        onAction: () => tapped = true,
      ),
    );

    await tester.pumpApp(TasklyFeedRenderer(spec: spec));

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Create your first task.'), findsOneWidget);

    await tester.tap(find.text('Create task'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgetsSafe('renders error state with retry action', (tester) async {
    var retried = false;
    final spec = TasklyFeedSpec.error(
      message: 'Load failed',
      retryLabel: 'Retry',
      onRetry: () => retried = true,
    );

    await tester.pumpApp(TasklyFeedRenderer(spec: spec));

    expect(find.text('Load failed'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgetsSafe('renders task rows in content feed', (tester) async {
    final row = TasklyRowSpec.task(
      key: 'task-1',
      data: TasklyTaskRowData(
        id: 'task-1',
        title: 'Write tests',
        completed: false,
        meta: const TasklyEntityMetaData(),
      ),
      actions: const TasklyTaskRowActions(),
    );

    final spec = TasklyFeedSpec.content(
      sections: [
        TasklySectionSpec.standardList(id: 'tasks', rows: [row]),
      ],
    );

    await tester.pumpApp(TasklyFeedRenderer(spec: spec));

    expect(find.text('Write tests'), findsOneWidget);
  });
}
