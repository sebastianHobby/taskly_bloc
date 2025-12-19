// drift types are provided by the generated database import below
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_form.dart';

class TaskDetailSheetPage extends StatelessWidget {
  const TaskDetailSheetPage({
    this.taskId,
    this.onSuccess,
    this.onError,
    super.key,
  });

  final String? taskId;
  final void Function(String message)? onSuccess;
  final void Function(String message)? onError;

  @override
  Widget build(BuildContext context) {
    final taskRepository = getIt<TaskRepository>();
    return Scaffold(
      body: BlocProvider(
        create: (context) {
          final bloc = TaskDetailBloc(taskRepository: taskRepository);
          if (taskId != null) bloc.add(TaskDetailEvent.get(taskId: taskId!));
          return bloc;
        },
        lazy: false,
        child: TaskDetailSheetView(
          taskId: taskId,
          onSuccess: onSuccess,
          onError: onError,
        ),
      ),
    );
  }
}

class TaskDetailSheetView extends StatefulWidget {
  const TaskDetailSheetView({
    this.taskId,
    this.onSuccess,
    this.onError,
    super.key,
  });

  final String? taskId;
  final void Function(String message)? onSuccess;
  final void Function(String message)? onError;

  @override
  State<TaskDetailSheetView> createState() => _TaskDetailSheetViewState();
}

class _TaskDetailSheetViewState extends State<TaskDetailSheetView> {
  // Create a global key that uniquely identifies the Form widget
  final _formKey = GlobalKey<FormBuilderState>();

  void _onSubmit(String? id) {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (formState.saveAndValidate()) {
      final formValues = formState.value;
      if (id == null) {
        // Create new data
        context.read<TaskDetailBloc>().add(
          TaskDetailEvent.create(
            name: formState.value['name'] as String,
            description: formState.value['description'] as String,
          ),
        );
      } else {
        // Update existing data
        context.read<TaskDetailBloc>().add(
          TaskDetailEvent.update(
            id: id,
            name: formValues['name'] as String,
            description: formValues['description'] as String,
            completed: formValues['completed'] as bool,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskDetailBloc, TaskDetailState>(
      listenWhen: (previous, current) {
        return current is TaskDetailOperationSuccess ||
            current is TaskDetailOperationFailure;
      },
      listener: (context, state) {
        switch (state) {
          case TaskDetailOperationSuccess(:final message):
            widget.onSuccess?.call(message);
          case TaskDetailOperationFailure(:final errorDetails):
            widget.onError?.call(errorDetails.message);
          default:
            return;
        }
      },
      buildWhen: (previous, current) {
        return current is TaskDetailInitial ||
            current is TaskDetailLoadInProgress ||
            current is TaskDetailLoadSuccess;
      },
      builder: (context, state) {
        switch (state) {
          case TaskDetailInitial():
            return TaskForm(
              formKey: _formKey,
              onSubmit: () => _onSubmit(widget.taskId),
              submitTooltip: 'Create',
            );
          case TaskDetailLoadInProgress():
            return const Center(child: CircularProgressIndicator());
          case TaskDetailLoadSuccess(:final task):
            return TaskForm(
              initialData: task,
              formKey: _formKey,
              onSubmit: () => _onSubmit(task.id),
              submitTooltip: 'Update',
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
