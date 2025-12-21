import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/domain/domain.dart';

class ProjectForm extends StatelessWidget {
  const ProjectForm({
    required this.formKey,
    required this.initialData,
    required this.onSubmit,
    required this.submitTooltip,
    this.availableValues = const <ValueModel>[],
    this.availableLabels = const <Label>[],
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final Project? initialData;
  final List<ValueModel> availableValues;
  final List<Label> availableLabels;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> initialValues = {
      'name': initialData?.name.trim() ?? '',
      'completed': initialData?.completed ?? false,
      'valueIds': (initialData?.values ?? <ValueModel>[])
          .map((ValueModel e) => e.id)
          .toList(growable: false),
      'labelIds': (initialData?.labels ?? <Label>[])
          .map((Label e) => e.id)
          .toList(growable: false),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: FormBuilderFilterChips<String>(
                      name: 'valueIds',
                      initialValue: initialValues['valueIds'] as List<String>?,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Values',
                      ),
                      options: availableValues
                          .map(
                            (v) => FormBuilderChipOption(
                              value: v.id,
                              child: Text(v.name),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: FormBuilderFilterChips<String>(
                      name: 'labelIds',
                      initialValue: initialValues['labelIds'] as List<String>?,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Labels',
                      ),
                      options: availableLabels
                          .map(
                            (l) => FormBuilderChipOption(
                              value: l.id,
                              child: Text(l.name),
                            ),
                          )
                          .toList(growable: false),
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
                child: IconButton(
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
