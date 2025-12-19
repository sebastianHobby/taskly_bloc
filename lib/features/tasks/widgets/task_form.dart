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
      'startDate': initialData?.startDate,
      'deadlineDate': initialData?.deadlineDate,
      'projectId': initialData?.projectId ?? '',
      'repeatIcalRrule': initialData?.repeatIcalRrule ?? '',
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
                      textCapitalization: TextCapitalization.words,
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
                        FormBuilderValidators.maxLength(
                          120,
                          errorText: 'Name must be 120 characters or fewer',
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
                      minLines: 2,
                      maxLines: 5,
                      validator: FormBuilderValidators.maxLength(
                        200,
                        errorText: 'Description is too long',
                        checkNullOrEmpty: false,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderDateTimePicker(
                      name: 'startDate',
                      decoration: const InputDecoration(
                        hintText: 'Start date/time (optional)',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.play_arrow_outlined),
                      ),
                      initialValue: initialValues['startDate'] as DateTime?,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderDateTimePicker(
                      name: 'deadlineDate',
                      decoration: const InputDecoration(
                        hintText: 'Deadline date/time (optional)',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      initialValue: initialValues['deadlineDate'] as DateTime?,
                      validator: (valueCandidate) {
                        final start =
                            formKey.currentState?.fields['startDate']?.value
                                as DateTime?;
                        if (valueCandidate != null && start != null) {
                          if (valueCandidate.isBefore(start)) {
                            return 'Deadline must be after start date/time';
                          }
                        }
                        return null;
                      },
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderTextField(
                      name: 'projectId',
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Project ID (optional)',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      validator: FormBuilderValidators.maxLength(
                        120,
                        errorText: 'Project ID is too long',
                        checkNullOrEmpty: false,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderTextField(
                      name: 'repeatIcalRrule',
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'Repeat rule (RRULE, optional)',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      validator: FormBuilderValidators.maxLength(
                        255,
                        errorText: 'Repeat rule is too long',
                        checkNullOrEmpty: false,
                      ),
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
