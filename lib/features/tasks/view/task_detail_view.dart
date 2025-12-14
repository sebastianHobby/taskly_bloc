import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/data/dtos/tasks/task_dto.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_action_request.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';

enum Priority {
  high(displayName: 'High Priority', color: Colors.red),
  medium(displayName: 'Medium Priority', color: Colors.orange),
  low(displayName: 'Low Priority', color: Colors.blue),
  none(displayName: 'No Priority');

  const Priority({
    required this.displayName,
    this.color,
  });

  final String displayName;
  final Color? color;
}

class TaskDetailPage extends StatelessWidget {
  TaskDetailPage({super.key, this.taskDto});
  final TaskRepository taskRepository = getIt<TaskRepository>();
  final TaskDto? taskDto;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskDetailBloc(taskRepository: taskRepository),
      child: TaskDetailView(
        taskDto: taskDto,
      ),
    );
  }
}

class TaskDetailView extends StatefulWidget {
  const TaskDetailView({super.key, this.taskDto});
  final TaskDto? taskDto;

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
  TaskDto? get _taskDto => widget.taskDto;

  // Controllers and local state for detecting changes
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _completed;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _taskDto?.name ?? '');
    _descriptionController = TextEditingController(
      text: _taskDto?.description ?? '',
    );
    _completed = _taskDto?.completed ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Returns true if the current form values differ from the initial values.
  bool _hasFormChanged() {
    final initialName = _taskDto?.name ?? '';
    final initialDescription = _taskDto?.description ?? '';
    final initialCompleted = _taskDto?.completed ?? false;

    if (_nameController.text.trim() != initialName.trim()) return true;
    if (_descriptionController.text != initialDescription) return true;
    if (_completed != initialCompleted) return true;
    return false;
  }

  String? requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    return null;
  }

  TaskDto? get taskDto => widget.taskDto;

  Future<void> onPopInvoked(bool didPop, Object? result) async {
    if (didPop) {
      // Already popped.
      return;
    }
    if (!_hasFormChanged()) {
      Navigator.pop(context);
      return;
    }

    // Show a confirmation dialog.
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
    final taskNameInput = TextFormField(
      controller: _nameController,
      autofocus: true,
      style: Theme.of(context).textTheme.titleLarge,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: const InputDecoration(
        hintText: 'Title',
        border: InputBorder.none,
      ),
      validator: requiredValidator,
    );

    final taskDescriptionInput = TextFormField(
      controller: _descriptionController,
      style: Theme.of(context).textTheme.bodyLarge,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: const InputDecoration(
        hintText: 'Description',
        border: InputBorder.none,
      ),
    );

    // Build a Form widget using the _formKey created above.
    final body = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: taskNameInput,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: taskDescriptionInput,
            ),
            // Example usage: show a small indicator if form changed (optional)
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //   child: Text(_hasFormChanged() ? 'Unsaved changes' : 'No changes'),
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  // Validate returns true if the form is valid, or false otherwise.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    // If taskDto exists then this is an update else create new task
                    if (_taskDto != null) {
                      final TaskActionRequestUpdate updateRequest =
                          TaskActionRequestUpdate(
                            taskToUpdate: _taskDto!,
                            name: _nameController.text,
                            description: _descriptionController.text,
                            completed: _taskDto!.completed,
                          );
                      context.read<TaskDetailBloc>().add(
                        TaskDetailEvent.updateTask(updateRequest: updateRequest),
                      );
                    } else {
                      final TaskActionRequestCreate createRequest =
                          TaskActionRequestCreate(
                            name: _nameController.text,
                            completed: false,
                            description: _descriptionController.text,
                          );
                      context.read<TaskDetailBloc>().add(
                        TaskDetailEvent.createTask(createRequest: createRequest),
                      );
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ),
          ],
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
            // bottomBarVisibility: const BottomBarVisibility.always(
            //   // Make the bottom bar visible when the keyboard is open.
            //   ignoreBottomInset: true,
            // ),
            body: body,
            // bottomBar: bottomBar,
          ),
        ),
      ),
    );
  }
}
