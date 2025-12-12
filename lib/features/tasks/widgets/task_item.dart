import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/data/models/tasks/task_model.dart';
import 'package:taskly_bloc/features/tasks/bloc/tasks_bloc.dart';

class TaskItem extends StatelessWidget {
  const TaskItem({
    required this.task,
    super.key,
  });

  final TaskModel task;
  //  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    // final captionColor = theme.textTheme.bodySmall?.color;
    final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
    // Todo update with fields required for task and validations
    return FormBuilder(
      child: FormBuilder(
        key: formKey,
        child: Column(
          children: [
            FormBuilderTextField(
              name: 'email',
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            FormBuilderDropdown(
              name: 'gender',
              decoration: const InputDecoration(labelText: 'Gender'),
              items: ['Male', 'Female', 'Other']
                  .map(
                    (gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            FormBuilderDateTimePicker(
              name: 'birthdate',
              decoration: const InputDecoration(labelText: 'Birthdate'),
              inputType: InputType.date,
              initialDate: DateTime.now(),
              initialValue: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.saveAndValidate()) {
                  print(formKey.currentState!.value.entries.toList());
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
      //   trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    );
  }
}
