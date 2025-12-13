import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/data/dtos/tasks/task_dto.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/bloc/tasks_bloc.dart';
import 'package:taskly_bloc/features/tasks/models/task_models.dart';
import 'package:uuid/uuid.dart';

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

class TaskEditorPage extends StatelessWidget {
  TaskEditorPage({super.key});
  final TaskRepository taskRepository = getIt<TaskRepository>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TasksBloc(taskRepository: taskRepository),
      child: const TaskEditorView(),
    );
  }
}

class TaskEditorView extends StatefulWidget {
  const TaskEditorView({super.key});
  @override
  State<TaskEditorView> createState() => _TaskEditorViewState();
}

class _TaskEditorViewState extends State<TaskEditorView> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  String? requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    return null;
  }

  Future<void> onPopInvoked(bool didPop, Object? result) async {
    if (didPop) {
      // Already popped.
      return;
    }
    // } else if (!controller.canCompose.value) {
    //   // Dismiss immediately if there are no unsaved changes.
    //   Navigator.pop(context);
    //   return;
    // }

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
      autofocus: true,
      style: Theme.of(context).textTheme.titleLarge,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.always,
      decoration: const InputDecoration(
        hintText: 'Title',
        border: InputBorder.none,
      ),
      validator: requiredValidator,
      controller: TextEditingController(),
    );

    final taskDescriptionInput = TextFormField(
      style: Theme.of(context).textTheme.bodyLarge,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        hintText: 'Description',
        border: InputBorder.none,
      ),
      controller: TextEditingController(),
    );

    // Todo define new widgets as per old example - but get date etc working

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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  // Validate returns true if the form is valid, or false otherwise.
                  if (_formKey.currentState!.validate()) {
                    // If the form is valid, display a snackbar. In the real world,
                    // you'd often call a server or save the information in a database.
                    // TOdo complete this with fields
                    _formKey.currentState!.save();
                    final TaskCreateRequest createRequest = TaskCreateRequest(
                      name: taskNameInput.controller!.text,
                      completed: false,
                      description: taskDescriptionInput.controller?.text,
                    );

                    context.read<TasksBloc>().add(
                      TasksEvent.createTask(createRequest: createRequest),
                    );
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
