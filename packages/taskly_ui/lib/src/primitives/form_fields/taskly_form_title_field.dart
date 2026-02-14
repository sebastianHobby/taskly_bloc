import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class TasklyFormTitleField extends StatelessWidget {
  const TasklyFormTitleField({
    required this.name,
    required this.hintText,
    this.validator,
    this.maxLength,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.sentences,
    this.focusNode,
    this.autofocus = false,
    this.onSubmitted,
    this.suffixIcon,
    super.key,
  });

  final String name;
  final String hintText;
  final String? Function(String?)? validator;
  final int? maxLength;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<String?>? onSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormBuilderTextField(
      name: name,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      focusNode: focusNode,
      autofocus: autofocus,
      onSubmitted: onSubmitted,
      maxLength: maxLength,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hintText,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}
