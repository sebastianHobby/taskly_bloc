import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/l10n/gen/app_localizations.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_form.dart';
import 'package:taskly_bloc/presentation/widgets/form_date_chip.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_fields.dart';
import 'package:taskly_bloc/presentation/widgets/form_recurrence_chip.dart';

import '../../../../fixtures/test_data.dart';
import '../../../../helpers/test_helpers.dart';

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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
      await tester.pumpAndSettleSafe();

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
      await tester.pumpAndSettleSafe();

      // Find and tap close button
      final closeButton = find.widgetWithIcon(IconButton, Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettleSafe();

      expect(closePressed, isTrue);
    });

    testWidgets('hides close button when onClose is not provided', (
      tester,
    ) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettleSafe();

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
      await tester.pumpAndSettleSafe();

      // Find and tap delete button
      final deleteButton = find.widgetWithIcon(
        IconButton,
        Icons.delete_outline_rounded,
      );
      expect(deleteButton, findsOneWidget);

      await tester.tap(deleteButton);
      await tester.pumpAndSettleSafe();

      expect(deletePressed, isTrue);
    });

    testWidgets('hides delete button when creating new task', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettleSafe();

      // Delete button should not be visible for new tasks
      final deleteButton = find.widgetWithIcon(
        IconButton,
        Icons.delete_outline_rounded,
      );
      expect(deleteButton, findsNothing);
    });

    testWidgets('displays name field', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettleSafe();

      expect(
        find.byWidgetPredicate(
          (w) => w is FormBuilderTextField && w.name == 'name',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays description field', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettleSafe();

      expect(find.byType(FormBuilderTextFieldModern), findsOneWidget);
    });

    testWidgets('displays completed checkbox when editing', (tester) async {
      final task = TestData.task(id: 'task-1');

      await tester.pumpWidget(
        buildTaskForm(initialData: task),
      );
      await tester.pumpAndSettleSafe();

      // Completed checkbox should be present
      expect(find.byType(Checkbox), findsOneWidget);
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
      await tester.pumpAndSettleSafe();

      // Verify name is pre-filled
      expect(find.text('Test Task'), findsOneWidget);

      // Verify description is pre-filled
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('can enter task name', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettleSafe();

      // Find name field and enter text
      final nameField = find.byWidgetPredicate(
        (w) => w is FormBuilderTextField && w.name == 'name',
      );
      await tester.enterText(nameField, 'New Task Name');
      await tester.pumpAndSettleSafe();

      // Verify text was entered
      expect(find.text('New Task Name'), findsOneWidget);
    });

    testWidgets('can enter task description', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettleSafe();

      // Find description field and enter text
      final descField = find.byType(FormBuilderTextFieldModern);
      await tester.enterText(
        find.descendant(
          of: descField,
          matching: find.byType(EditableText),
        ),
        'New Description',
      );
      await tester.pumpAndSettleSafe();

      // Verify text was entered
      expect(find.text('New Description'), findsOneWidget);
    });

    testWidgets('validates required fields', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettleSafe();

      // Try to validate with empty name
      formKey.currentState?.saveAndValidate();
      await tester.pumpAndSettleSafe();

      expect(formKey.currentState?.fields['name']?.hasError, isTrue);
      expect(formKey.currentState?.fields['name']?.errorText, isNotEmpty);
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
      await tester.pumpAndSettleSafe();

      // Project chip should be present
      expect(find.text('Add project'), findsOneWidget);
    });

    testWidgets('shows label selector when labels available', (tester) async {
      final labels = [
        TestData.label(id: 'l1', name: 'Label 1'),
        TestData.label(id: 'l2', name: 'Label 2'),
      ];

      await tester.pumpWidget(
        buildTaskForm(availableLabels: labels),
      );
      await tester.pumpAndSettleSafe();

      // Modern label picker should be present
      expect(find.byType(FormBuilderLabelPickerModern), findsOneWidget);
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
      await tester.pumpAndSettleSafe();

      // Verify default project is selected in form state
      expect(formKey.currentState?.fields['projectId']?.value, equals('p2'));
    });

    testWidgets('displays date chips for start and deadline', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettleSafe();

      // Should show date-related widgets
      expect(find.byType(FormDateChip), findsNWidgets(2)); // Start and deadline
    });

    testWidgets('displays recurrence chip', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettleSafe();

      // Should show recurrence chip
      expect(find.byType(FormRecurrenceChip), findsOneWidget);
    });

    testWidgets('form is scrollable', (tester) async {
      await tester.pumpWidget(buildTaskForm());
      await tester.pumpAndSettleSafe();

      // SingleChildScrollView should be present for scrolling
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
