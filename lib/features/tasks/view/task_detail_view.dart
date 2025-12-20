// drift types are provided by the generated database import below
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_form.dart';

class TaskDetailSheet extends StatefulWidget {
  const TaskDetailSheet({
    this.taskId,
    super.key,
  });

  final String? taskId;

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  // Create a global key that uniquely identifies the Form widget
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<TaskDetailBloc>();

    if (widget.taskId != null && widget.taskId!.isNotEmpty) {
      bloc.add(TaskDetailEvent.get(taskId: widget.taskId!));
    } else {
      bloc.add(const TaskDetailEvent.loadInitialData());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskDetailBloc, TaskDetailState>(
      listenWhen: (previous, current) =>
          current is TaskDetailOperationSuccess ||
          current is TaskDetailOperationFailure,
      listener: (context, state) {
        state.maybeWhen(
          operationSuccess: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
            Navigator.of(context).maybePop();
          },
          operationFailure: (errorDetails) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorDetails.message)),
            );
          },
          orElse: () {},
        );
      },
      buildWhen: (previous, current) =>
          current is TaskDetailInitial ||
          current is TaskDetailLoadInProgress ||
          current is TaskDetailInitialDataLoadSuccess ||
          current is TaskDetailLoadSuccess,
      builder: (context, state) {
        return state.when(
          initial: () => const Center(child: CircularProgressIndicator()),
          loadInProgress: () =>
              const Center(child: CircularProgressIndicator()),
          initialDataLoadSuccess:
              (availableProjects, availableValues, availableLabels) => TaskForm(
                formKey: _formKey,
                onSubmit: () {
                  final formState = _formKey.currentState;
                  if (formState == null) return;
                  if (!formState.saveAndValidate()) return;
                  final formValues = formState.value;
                  final name = formValues['name'] as String;
                  final description = formValues['description'] as String?;
                  final projectId = formValues['projectId'] as String?;
                  final valueIds =
                      (formValues['valueIds'] as List<dynamic>?)
                          ?.cast<String>() ??
                      <String>[];
                  final labelIds =
                      (formValues['labelIds'] as List<dynamic>?)
                          ?.cast<String>() ??
                      <String>[];

                  final selectedValues = availableValues
                      .where((v) => valueIds.contains(v.id))
                      .toList();
                  final selectedLabels = availableLabels
                      .where((l) => labelIds.contains(l.id))
                      .toList();

                  context.read<TaskDetailBloc>().add(
                    TaskDetailEvent.create(
                      name: name,
                      description: description,
                      projectId: projectId,
                      values: selectedValues,
                      labels: selectedLabels,
                    ),
                  );
                },
                submitTooltip: 'Create',
                availableProjects: availableProjects,
                availableValues: availableValues,
                availableLabels: availableLabels,
              ),
          loadSuccess:
              (availableProjects, availableValues, availableLabels, task) =>
                  TaskForm(
                    initialData: task,
                    formKey: _formKey,
                    onSubmit: () {
                      final formState = _formKey.currentState;
                      if (formState == null) return;
                      if (!formState.saveAndValidate()) return;
                      final formValues = formState.value;
                      final name = formValues['name'] as String;
                      final description = formValues['description'] as String?;
                      final projectId = formValues['projectId'] as String?;
                      final valueIds =
                          (formValues['valueIds'] as List<dynamic>?)
                              ?.cast<String>() ??
                          <String>[];
                      final labelIds =
                          (formValues['labelIds'] as List<dynamic>?)
                              ?.cast<String>() ??
                          <String>[];

                      final selectedValues = availableValues
                          .where((v) => valueIds.contains(v.id))
                          .toList();
                      final selectedLabels = availableLabels
                          .where((l) => labelIds.contains(l.id))
                          .toList();

                      context.read<TaskDetailBloc>().add(
                        TaskDetailEvent.update(
                          id: task.id,
                          name: name,
                          description: description,
                          completed: formValues['completed'] as bool? ?? false,
                          projectId: projectId,
                          values: selectedValues,
                          labels: selectedLabels,
                        ),
                      );
                    },
                    submitTooltip: 'Update',
                    availableProjects: availableProjects,
                    availableValues: availableValues,
                    availableLabels: availableLabels,
                  ),
          operationSuccess: (_) => const SizedBox.shrink(),
          operationFailure: (_) => const SizedBox.shrink(),
        );
      },
    );
  }
}
