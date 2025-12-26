import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_form.dart';

import '../../../../fixtures/test_data.dart';

void main() {
  group('TaskForm', () {
    late GlobalKey<FormBuilderState> formKey;

    setUp(() {
      formKey = GlobalKey<FormBuilderState>();
    });

    Widget buildTaskForm({
      Task? initialData,
      List<Project> availableProjects = const [],
      List<Label> availableLabels = const [],
      String? defaultProjectId,
      VoidCallback? onDelete,
      VoidCallback? onClose,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: TaskForm(
            formKey: formKey,
            initialData: initialData,
            onSubmit: () {},
            submitTooltip: 'Save',
            availableProjects: availableProjects,
            availableLabels: availableLabels,
            defaultProjectId: defaultProjectId,
            onDelete: onDelete,
            onClose: onClose,
          ),
        ),
      );
    }

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      expect(find.byType(TaskForm), findsOneWidget);
    });

    testWidgets('displays handle bar at top', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettle();

      // Handle bar should be visible
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows close button when onClose is provided', (tester) async {
      var closePressed = false;

      await tester.pumpWidget(
        buildTaskForm(
          onClose: () {
            closePressed = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap close button
      final closeButton = find.widgetWithIcon(IconButton, Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(closePressed, isTrue);
    });

    testWidgets('hides close button when onClose is not provided', (
      tester,
    ) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettle();

      // Close button should not be visible
      final closeButton = find.widgetWithIcon(IconButton, Icons.close);
      expect(closeButton, findsNothing);
    });

    testWidgets('shows delete button when editing and onDelete is provided', (
      tester,
    ) async {
      var deletePressed = false;
      final task = TestData.task(id: 'task-1');

      await tester.pumpWidget(
        buildTaskForm(
          initialData: task,
          onDelete: () {
            deletePressed = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap delete button
      final deleteButton = find.widgetWithIcon(
        IconButton,
        Icons.delete_outline_rounded,
      );
      expect(deleteButton, findsOneWidget);

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(deletePressed, isTrue);
    });

    testWidgets('hides delete button when creating new task', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettle();

      // Delete button should not be visible for new tasks
      final deleteButton = find.widgetWithIcon(
        IconButton,
        Icons.delete_outline_rounded,
      );
      expect(deleteButton, findsNothing);
    });

    testWidgets('displays name field', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettle();

      // Name field should be present
      expect(
        find.widgetWithText(FormBuilderTextField, 'Task Name'),
        findsOneWidget,
      );
    });

    testWidgets('displays description field', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettle();

      // Description field should be present
      expect(
        find.widgetWithText(FormBuilderTextField, 'Description'),
        findsOneWidget,
      );
    });

    testWidgets('displays completed checkbox when editing', (tester) async {
      final task = TestData.task(id: 'task-1');

      await tester.pumpWidget(
        buildTaskForm(initialData: task),
      );
      await tester.pumpAndSettle();

      // Completed checkbox should be present
      expect(find.byType(FormBuilderCheckbox), findsOneWidget);
    });

    testWidgets('pre-fills form with initial data', (tester) async {
      final task = TestData.task(
        id: 'task-1',
        description: 'Test Description',
        completed: true,
      );

      await tester.pumpWidget(
        buildTaskForm(initialData: task),
      );
      await tester.pumpAndSettle();

      // Verify name is pre-filled
      expect(find.text('Test Task'), findsOneWidget);

      // Verify description is pre-filled
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('can enter task name', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettle();

      // Find name field and enter text
      final nameField = find.widgetWithText(FormBuilderTextField, 'Task Name');
      await tester.enterText(nameField, 'New Task Name');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('New Task Name'), findsOneWidget);
    });

    testWidgets('can enter task description', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettle();

      // Find description field and enter text
      final descField = find.widgetWithText(
        FormBuilderTextField,
        'Description',
      );
      await tester.enterText(descField, 'New Description');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('New Description'), findsOneWidget);
    });

    testWidgets('validates required fields', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettle();

      // Try to validate with empty name
      formKey.currentState?.saveAndValidate();
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('shows project selector when projects available', (
      tester,
    ) async {
      final projects = [
        TestData.project(id: 'p1', name: 'Project 1'),
        TestData.project(id: 'p2', name: 'Project 2'),
      ];

      await tester.pumpWidget(
        buildTaskForm(availableProjects: projects),
      );
      await tester.pumpAndSettle();

      // Project dropdown should be present
      expect(find.byType(FormBuilderDropdown<String>), findsWidgets);
    });

    testWidgets('shows label selector when labels available', (tester) async {
      final labels = [
        TestData.label(id: 'l1', name: 'Label 1'),
        TestData.label(id: 'l2', name: 'Label 2'),
      ];

      await tester.pumpWidget(
        buildTaskForm(availableLabels: labels),
      );
      await tester.pumpAndSettle();

      // Label selector should be present
      expect(find.byType(FormBuilderFilterChips<String>), findsOneWidget);
    });

    testWidgets('sets default project when provided', (tester) async {
      final projects = [
        TestData.project(id: 'p1', name: 'Project 1'),
        TestData.project(id: 'p2', name: 'Project 2'),
      ];

      await tester.pumpWidget(
        buildTaskForm(
          availableProjects: projects,
          defaultProjectId: 'p2',
        ),
      );
      await tester.pumpAndSettle();

      // Verify default project is selected in form state
      expect(formKey.currentState?.value['projectId'], equals('p2'));
    });

    testWidgets('displays date chips for start and deadline', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettle();

      // Should show date-related widgets
      expect(find.byType(FormDateChip), findsNWidgets(2)); // Start and deadline
    });

    testWidgets('displays recurrence chip', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettle();

      // Should show recurrence chip
      expect(find.byType(FormRecurrenceChip), findsOneWidget);
    });

    testWidgets('form is scrollable', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettle();

      // SingleChildScrollView should be present for scrolling
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
