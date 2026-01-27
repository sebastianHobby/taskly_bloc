import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_icons.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

/// A FormBuilder field for selecting an icon from predefined categories.
///
/// Inline layout with search, category filters, and grid selection.
class FormBuilderIconPicker extends StatelessWidget {
  const FormBuilderIconPicker({
    required this.name,
    required this.searchHintText,
    required this.noIconsFoundLabel,
    this.validator,
    this.initialValue,
    this.gridHeight,
    super.key,
  });

  final String name;
  final String searchHintText;
  final String noIconsFoundLabel;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final double? gridHeight;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return FormBuilderField<String>(
      name: name,
      initialValue: initialValue,
      validator: validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TasklyFormIconSearchPicker(
              icons: tasklySymbolIcons,
              selectedIconName: field.value,
              searchHintText: searchHintText,
              noIconsFoundLabel: noIconsFoundLabel,
              gridHeight: gridHeight,
              tooltipBuilder: formatIconLabel,
              onSelected: (iconName) => field.didChange(iconName),
            ),
            if (field.errorText != null) ...[
              SizedBox(height: tokens.spaceSm),
              Text(
                field.errorText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
