import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/tasks/view/task_overview_page.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_add_fab.dart';

import '../../../helpers/pump_app.dart';

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class MockLabelRepository extends Mock implements LabelRepositoryContract {}

void main() {
  testWidgets('TaskOverviewPage builds and shows app bar + fab', (
    tester,
  ) async {
    final taskRepository = MockTaskRepository();
    final projectRepository = MockProjectRepository();
    final labelRepository = MockLabelRepository();

    when(
      () => taskRepository.watchAll(withRelated: any(named: 'withRelated')),
    ).thenAnswer((_) => Stream.value(const <Task>[]));

    await pumpLocalizedApp(
      tester,
      home: TaskOverviewPage(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        labelRepository: labelRepository,
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TaskOverviewView));
    final l10n = context.l10n;

    expect(find.text(l10n.tasksTitle), findsOneWidget);
    expect(find.byType(AddTaskFab), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsOneWidget);

    verify(() => taskRepository.watchAll(withRelated: true)).called(1);
  });
}
