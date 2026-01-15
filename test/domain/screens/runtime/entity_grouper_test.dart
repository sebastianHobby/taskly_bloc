import '../../../helpers/test_imports.dart';

import 'package:taskly_bloc/domain/screens/language/models/display_config.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_grouper.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('EntityGrouper', () {
    final grouper = EntityGrouper();

    testSafe('groupTasks none returns All', () async {
      final tasks = [TestData.task(id: 't1'), TestData.task(id: 't2')];

      final grouped = grouper.groupTasks(tasks, GroupByField.none);

      expect(grouped.keys, ['All']);
      expect(grouped['All'], tasks);
    });

    testSafe(
      'groupTasks project groups by project name and sorts keys',
      () async {
        final tasks = [
          TestData.task(
            id: 't1',
            project: TestData.project(id: 'p1', name: 'B Project'),
          ),
          TestData.task(
            id: 't2',
            project: TestData.project(id: 'p2', name: 'A Project'),
          ),
          TestData.task(id: 't3', project: null),
        ];

        final grouped = grouper.groupTasks(tasks, GroupByField.project);

        expect(grouped.keys, ['A Project', 'B Project', 'No Project']);
        expect(grouped['A Project']!.single.id, 't2');
        expect(grouped['B Project']!.single.id, 't1');
        expect(grouped['No Project']!.single.id, 't3');
      },
    );

    testSafe(
      'groupTasks value groups into No Values + value name buckets',
      () async {
        final v1 = TestData.value(id: 'v1', name: 'Health');
        final v2 = TestData.value(id: 'v2', name: 'Work');

        final tasks = [
          TestData.task(id: 't1', values: [v2]),
          TestData.task(id: 't2', values: [v1, v2]),
          TestData.task(id: 't3', values: const []),
        ];

        final grouped = grouper.groupTasks(tasks, GroupByField.value);

        expect(grouped.keys, ['Health', 'No Values', 'Work']);
        expect(grouped['No Values']!.single.id, 't3');
        expect(grouped['Health']!.single.id, 't2');
        expect(grouped['Work']!.map((t) => t.id), containsAll(['t1', 't2']));
      },
    );

    testSafe(
      'groupTasks date buckets include overdue/today/tomorrow',
      () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final yesterday = today.subtract(const Duration(days: 1));

        final tasks = [
          TestData.task(id: 'overdue', deadlineDate: yesterday),
          TestData.task(id: 'today', deadlineDate: today),
          TestData.task(id: 'tomorrow', deadlineDate: tomorrow),
          TestData.task(id: 'none', deadlineDate: null),
        ];

        final grouped = grouper.groupTasks(tasks, GroupByField.date);

        expect(grouped['Overdue']!.single.id, 'overdue');
        expect(grouped['Today']!.single.id, 'today');
        expect(grouped['Tomorrow']!.single.id, 'tomorrow');
        expect(grouped['No Deadline']!.single.id, 'none');
      },
    );

    testSafe(
      'groupTasks priority uses P1..P4 and No Priority ordering',
      () async {
        final tasks = [
          TestData.task(id: 'p2', priority: 2),
          TestData.task(id: 'none', priority: null),
          TestData.task(id: 'p1', priority: 1),
        ];

        final grouped = grouper.groupTasks(tasks, GroupByField.priority);

        expect(grouped.keys, ['P1', 'P2', 'No Priority']);
        expect(grouped['P1']!.single.id, 'p1');
        expect(grouped['P2']!.single.id, 'p2');
        expect(grouped['No Priority']!.single.id, 'none');
      },
    );

    testSafe('groupProjects value and priority groupings work', () async {
      final v1 = TestData.value(id: 'v1', name: 'Health');
      final projects = [
        TestData.project(id: 'p1', values: [v1], priority: 1),
        TestData.project(id: 'p2', values: const [], priority: null),
      ];

      final byValue = grouper.groupProjects(projects, GroupByField.value);
      expect(byValue.keys, ['Health', 'No Values']);

      final byPriority = grouper.groupProjects(projects, GroupByField.priority);
      expect(byPriority.keys, ['P1', 'No Priority']);
    });
  });
}
