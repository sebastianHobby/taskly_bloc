import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';

class ProjectForm extends StatelessWidget {
  const ProjectForm({
    required this.formKey,
    required this.initialData,
    required this.onSubmit,
    required this.submitTooltip,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final ProjectTableData? initialData;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> initialValues = {
      'name': initialData?.name.trim() ?? '',
      'description': initialData?.description?.trim() ?? '',
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
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Title is required',
                        ),
                        FormBuilderValidators.minLength(
                          1,
                          errorText: 'Title must not be empty',
                        ),
                        FormBuilderValidators.maxLength(
                          120,
                          errorText: 'Title must be 120 characters or fewer',
                        ),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderTextField(
                      name: 'description',
                      textInputAction: TextInputAction.next,
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
