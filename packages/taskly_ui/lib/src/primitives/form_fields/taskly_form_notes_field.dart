import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:taskly_ui/src/forms/taskly_form_preset.dart';
import 'package:taskly_ui/src/primitives/taskly_form_notes_container.dart';

class TasklyFormNotesField extends StatelessWidget {
  const TasklyFormNotesField({
    required this.name,
    required this.hintText,
    required this.contentPadding,
    this.validator,
    this.minLines,
    this.maxLines,
    this.textInputAction = TextInputAction.newline,
    this.focusNode,
    this.onSubmitted,
    this.preset,
    super.key,
  });

  final String name;
  final String hintText;
  final EdgeInsets contentPadding;
  final String? Function(String?)? validator;
  final int? minLines;
  final int? maxLines;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String?>? onSubmitted;
  final TasklyFormPreset? preset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TasklyFormNotesContainer(
      child: FormBuilderTextField(
        name: name,
        textInputAction: textInputAction,
        focusNode: focusNode,
        onSubmitted: onSubmitted,
        minLines: minLines,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          contentPadding: contentPadding,
        ),
        validator: validator,
      ),
    );
  }
}
