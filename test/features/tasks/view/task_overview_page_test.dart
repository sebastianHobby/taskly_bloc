import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/data/adapters/page_sort_adapter.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/features/tasks/view/task_overview_page.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_add_fab.dart';

import '../../../helpers/pump_app.dart';
import '../../../mocks/repository_mocks.dart';

class _FakeTaskQuery extends Fake implements TaskQuery {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTaskQuery());
  });

  testWidgets('TaskOverviewPage builds and shows app bar + fab', (
    tester,
  ) async {
    final taskRepository = MockTaskRepository();
    final projectRepository = MockProjectRepository();
    final labelRepository = MockLabelRepository();
    final settingsRepository = MockSettingsRepository();

    when(() => settingsRepository.loadPageSort(any())).thenAnswer(
      (_) async => null,
    );

    final sortAdapter = PageSortAdapter(
      settingsRepository: settingsRepository,
      pageKey: 'tasks',
    );

    when(
      () => taskRepository.watchAll(any()),
    ).thenAnswer((_) => Stream.value(const <Task>[]));

    await pumpLocalizedApp(
      tester,
      home: TaskOverviewPage(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        labelRepository: labelRepository,
        sortAdapter: sortAdapter,
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TaskOverviewView));
    final l10n = context.l10n;

    expect(find.text(l10n.tasksTitle), findsOneWidget);
    expect(find.byType(AddTaskFab), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsOneWidget);

    verify(() => taskRepository.watchAll(any())).called(1);
  });
}
