import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class ProjectFormItem extends StatelessWidget {
  const ProjectFormItem({
    required this.initialValues,
    super.key,
  });

  final Map<String, dynamic> initialValues;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FormBuilderTextField(
            name: 'name',
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
            initialValue: initialValues['completed'] as bool? ?? false,
          ),
        ),
      ],
    );
  }
}
