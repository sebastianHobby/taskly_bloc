import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';

class TaskForm extends StatelessWidget {
  const TaskForm({
    required this.formKey,
    required this.onSubmit,
    required this.submitTooltip,
    this.initialData,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final TaskTableData? initialData;
  final VoidCallback onSubmit;
  final String submitTooltip;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> initialValues = {
      'name': initialData?.name ?? '',
      'description': initialData?.description ?? '',
      'completed': initialData?.completed ?? false,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: FormBuilder(
              key: formKey,
              initialValue: initialValues,
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
                      initialValue:
                          initialValues['completed'] as bool? ?? false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton.filled(
                  icon: const Icon(Icons.check),
                  tooltip: submitTooltip,
                  onPressed: onSubmit,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
