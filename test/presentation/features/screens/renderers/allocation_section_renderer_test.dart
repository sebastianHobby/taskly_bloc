import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/allocation_section_renderer.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';

void main() {
  group('AllocationSectionRenderer', () {
    // Note: Reflector mode behavior was merged into sustainable focus mode.
    // Value balance chart behavior may have changed with FocusMode migration
    testWidgets('renders tasks in allocation section', (
      tester,
    ) async {
      final data = AllocationSectionResult(
        allocatedTasks: [
          Task(
            id: '1',
            name: 'Test Task',
            completed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        totalAvailable: 1,
        activeFocusMode: FocusMode.sustainable,
        tasksByValue: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationSectionRenderer(data: data),
            ),
          ),
        ),
      );

      // Verify tasks are rendered in the allocation section
      expect(find.text('Test Task'), findsOneWidget);
    });

    testWidgets(
      'renders with different focus modes',
      (tester) async {
        final data = AllocationSectionResult(
          allocatedTasks: [
            Task(
              id: '1',
              name: 'Test Task',
              completed: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          totalAvailable: 1,
          activeFocusMode: FocusMode.intentional,
          tasksByValue: {},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AllocationSectionRenderer(data: data),
              ),
            ),
          ),
        );

        expect(find.text('Test Task'), findsOneWidget);
      },
    );

    testWidgets(
      'renders project-grouped list and shows effective values',
      (tester) async {
        final now = DateTime.utc(2026, 1, 1);

        const valueAId = 'value-a';
        const valueBId = 'value-b';

        final valueA = Value(
          id: valueAId,
          createdAt: now,
          updatedAt: now,
          name: 'Health',
          color: '#00FF00',
          priority: ValuePriority.medium,
        );
        final valueB = Value(
          id: valueBId,
          createdAt: now,
          updatedAt: now,
          name: 'Work',
          color: '#0000FF',
          priority: ValuePriority.medium,
        );

        final project = Project(
          id: 'project-1',
          createdAt: now,
          updatedAt: now,
          name: 'P1',
          completed: false,
          values: [valueA],
          primaryValueId: valueAId,
        );

        final data = AllocationSectionResult(
          allocatedTasks: [
            // Inherits project values.
            Task(
              id: '1',
              name: 'Alpha',
              completed: false,
              createdAt: now,
              updatedAt: now,
              projectId: project.id,
              project: project,
              values: const [],
            ),
            // Explicit override.
            Task(
              id: '2',
              name: 'Beta',
              completed: false,
              createdAt: now,
              updatedAt: now,
              projectId: project.id,
              project: project,
              values: [valueB],
              primaryValueId: valueBId,
            ),
            // No project group.
            Task(
              id: '3',
              name: 'Gamma',
              completed: false,
              createdAt: now,
              updatedAt: now,
              values: [valueB],
              primaryValueId: valueBId,
            ),
          ],
          totalAvailable: 3,
          activeFocusMode: FocusMode.sustainable,
          tasksByValue: {},
          displayMode: AllocationDisplayMode.groupedByProject,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AllocationSectionRenderer(data: data),
              ),
            ),
          ),
        );

        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Beta'), findsOneWidget);
        expect(find.text('Gamma'), findsOneWidget);

        // Group headers are uppercased.
        expect(find.text('P1'), findsWidgets);
        expect(find.text('NO PROJECT'), findsOneWidget);

        // Health should appear twice: project header + inherited task.
        expect(find.text('Health'), findsNWidgets(2));
        expect(find.text('Work'), findsNWidgets(2));
      },
    );
  });
}
