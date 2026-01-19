import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';

/// A FormBuilder field for selecting an icon from a predefined list.
///
/// Displays a compact preview that opens a dialog for icon selection.
/// Returns the icon name as a String for database storage.
class FormBuilderIconPicker extends FormBuilderFieldDecoration<String> {
  FormBuilderIconPicker({
    required super.name,
    super.key,
    super.validator,
    super.initialValue,
    super.onChanged,
    super.enabled = true,
    super.decoration = const InputDecoration(),
    this.iconSize = 32.0,
    this.hintText = 'Tap to select an icon',
  }) : super(
         builder: (FormFieldState<String> field) {
           final state =
               field
                   as FormBuilderFieldDecorationState<
                     FormBuilderIconPicker,
                     String
                   >;
           final widget = state.widget;

           return InputDecorator(
             decoration: state.decoration,
             child: _IconPickerButton(
               selected: state.value,
               enabled: state.enabled,
               onSelected: state.didChange,
               iconSize: widget.iconSize,
               hintText: widget.hintText,
             ),
           );
         },
       );

  /// Size of the icon in the preview.
  final double iconSize;

  /// Hint text shown when no icon is selected.
  final String hintText;

  @override
  FormBuilderFieldDecorationState<FormBuilderIconPicker, String>
  createState() => FormBuilderFieldDecorationState();

  /// Get an IconData from a stored icon name.
  static IconData? getIconData(String? iconName) {
    return getIconDataFromName(iconName);
  }
}

class _IconPickerButton extends StatelessWidget {
  const _IconPickerButton({
    required this.selected,
    required this.enabled,
    required this.onSelected,
    required this.iconSize,
    required this.hintText,
  });

  final String? selected;
  final bool enabled;
  final ValueChanged<String?> onSelected;
  final double iconSize;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconData = selected != null ? getIconDataFromName(selected) : null;

    return InkWell(
      onTap: enabled
          ? () async {
              final result = await IconPickerDialog.show(
                context,
                selectedIcon: selected,
                categories: defaultIconCategories,
                title: 'Select Icon',
                searchHintText: 'Search icons...',
                allCategoryLabel: 'All',
                noIconsFoundLabel: 'No icons found',
              );
              if (result != null) {
                onSelected(result);
              }
            }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: iconSize + 16,
              height: iconSize + 16,
              decoration: BoxDecoration(
                color: iconData != null
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: iconData != null
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
              ),
              child: iconData != null
                  ? Icon(
                      iconData,
                      size: iconSize,
                      color: colorScheme.onPrimaryContainer,
                    )
                  : Icon(
                      Icons.add,
                      size: iconSize * 0.75,
                      color: colorScheme.onSurfaceVariant,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                iconData != null ? _getIconLabel(selected!) : hintText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: iconData != null
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  String _getIconLabel(String iconName) {
    for (final category in defaultIconCategories) {
      for (final icon in category.icons) {
        if (icon.name == iconName) {
          return icon.label;
        }
      }
    }
    // Fallback: format the name nicely
    return iconName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}
