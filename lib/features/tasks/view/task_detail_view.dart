import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';

class TaskDetailPage extends StatelessWidget {
  TaskDetailPage({required this.taskCompanion, super.key});
  final TaskRepository taskRepository = getIt<TaskRepository>();
  final TaskTableCompanion taskCompanion;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskDetailBloc(taskRepository: taskRepository),
      child: TaskDetailView(
        taskCompanion: taskCompanion,
      ),
    );
  }
}

class TaskDetailView extends StatefulWidget {
  const TaskDetailView({required this.taskCompanion, super.key});
  final TaskTableCompanion taskCompanion;

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  final _formKey = GlobalKey<FormBuilderState>();

  TaskTableCompanion get _taskCompanion => widget.taskCompanion;

  late final Map<String, dynamic> _initialValues;

  Map<String, dynamic> _companionToInitialFormValues(
    TaskTableCompanion companion,
  ) {
    return <String, dynamic>{
      'name': companion.name.present ? companion.name.value : '',
      'description': companion.description.present
          ? companion.description.value
          : '',
      'completed': companion.completed.present && companion.completed.value,
    };
  }

  TaskTableCompanion get initialCompanionValue => widget.taskCompanion;

  @override
  void initState() {
    super.initState();
    _initialValues = _companionToInitialFormValues(widget.taskCompanion);
  }

  Future<void> onPopInvoked(bool didPop, Object? result) async {
    if (didPop) return;
    final formState = _formKey.currentState;
    if (formState == null || !formState.isDirty) {
      Navigator.pop(context);
      return;
    }

    final shouldPop = await showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if ((shouldPop ?? false) && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: FormBuilder(
        key: _formKey,
        initialValue: _initialValues,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FormBuilderTextField(
                name: 'name',
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Task Name',
                  border: InputBorder.none,
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: 'Name is required',
                  ),
                  FormBuilderValidators.minLength(
                    1,
                    errorText: 'Name must not be empty',
                  ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FormBuilderTextField(
                name: 'description',
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Description',
                  border: InputBorder.none,
                ),
                maxLines: null,
                validator: FormBuilderValidators.maxLength(
                  150,
                  errorText: 'Description is too long',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FormBuilderCheckbox(
                name: 'completed',
                title: const Text('Completed'),
                initialValue: _initialValues['completed'] as bool? ?? false,
              ),
            ),
          ],
        ),
      ),
    );

    void onSubmit() {
      final formState = _formKey.currentState;
      if (formState == null) return;
      if (formState.isDirty && formState.saveAndValidate()) {
        final name = (formState.value['name'] as String?)?.trim() ?? '';
        final description = (formState.value['description'] as String?)?.trim();
        final completed = formState.value['completed'] as bool? ?? false;

        if (initialCompanionValue.id.present) {
          final updateCompanion = TaskTableCompanion(
            id: initialCompanionValue.id,
            name: Value(name),
            description: Value(description),
            completed: Value(completed),
            updatedAt: Value(DateTime.now()),
          );
          context.read<TaskDetailBloc>().add(
            TaskDetailEvent.updateTask(updateRequest: updateCompanion),
          );
        } else {
          final createCompanion = TaskTableCompanion(
            name: Value(name),
            description: Value(description),
            completed: Value(completed),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          );
          context.read<TaskDetailBloc>().add(
            TaskDetailEvent.createTask(createRequest: createCompanion),
          );
        }

        Navigator.pop(context);
      }
    }

    final bottomBar = Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: SafeArea(
        top: false,
        child: SizedBox.fromSize(
          size: const Size.fromHeight(kToolbarHeight),
          child: Row(
            children: [
              IconButton.filled(
                icon: const Icon(Icons.arrow_upward),
                tooltip: 'Submit',
                onPressed: onSubmit,
              ),
            ],
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: onPopInvoked,
      child: SheetKeyboardDismissible(
        dismissBehavior: const SheetKeyboardDismissBehavior.onDragDown(
          isContentScrollAware: true,
        ),
        child: Sheet(
          scrollConfiguration: const SheetScrollConfiguration(),
          decoration: MaterialSheetDecoration(
            size: SheetSize.stretch,
            color: Theme.of(context).colorScheme.secondaryContainer,
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          child: SheetContentScaffold(
            body: body,
            bottomBar: bottomBar,
          ),
        ),
      ),
    );
  }
}
