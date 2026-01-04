import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// A generic radio card group for FormBuilder.
///
/// Displays options as selectable cards with icons, titles, and descriptions.
/// Useful for persona selection, mode selection, etc.
///
/// Type parameter [T] is the value type for each option.
class FormBuilderRadioCardGroup<T> extends StatelessWidget {
  const FormBuilderRadioCardGroup({
    required this.name,
    required this.options,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.recommendedValue,
    super.key,
  });

  /// Form field name.
  final String name;

  /// List of selectable options.
  final List<RadioCardOption<T>> options;

  /// Initial selected value.
  final T? initialValue;

  /// Validator function.
  final String? Function(T?)? validator;

  /// Called when selection changes.
  final void Function(T?)? onChanged;

  /// Whether the field is enabled.
  final bool enabled;

  /// Value to show as "Recommended".
  final T? recommendedValue;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<T>(
      name: name,
      initialValue: initialValue,
      validator: validator,
      enabled: enabled,
      builder: (field) {
        return Column(
          children: options.map((option) {
            final isSelected = field.value == option.value;
            final isRecommended = option.value == recommendedValue;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RadioCard<T>(
                option: option,
                isSelected: isSelected,
                isRecommended: isRecommended,
                enabled: enabled,
                onTap: () {
                  field.didChange(option.value);
                  onChanged?.call(option.value);
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// An option for [FormBuilderRadioCardGroup].
class RadioCardOption<T> {
  const RadioCardOption({
    required this.value,
    required this.title,
    required this.icon,
    this.emoji,
    this.description,
    this.expandedContent,
    this.warningText,
  });

  /// The value this option represents.
  final T value;

  /// Display title.
  final String title;

  /// Icon to display.
  final IconData icon;

  /// Optional emoji to display instead of icon.
  final String? emoji;

  /// Optional description text.
  final String? description;

  /// Optional expanded content (widget).
  final Widget? expandedContent;

  /// Warning text shown when selected.
  final String? warningText;
}

class _RadioCard<T> extends StatelessWidget {
  const _RadioCard({
    required this.option,
    required this.isSelected,
    required this.isRecommended,
    required this.enabled,
    required this.onTap,
  });

  final RadioCardOption<T> option;
  final bool isSelected;
  final bool isRecommended;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (option.emoji != null)
                    Text(
                      option.emoji!,
                      style: const TextStyle(fontSize: 24),
                    )
                  else
                    Icon(
                      option.icon,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isRecommended)
                    Chip(
                      label: Text(
                        'Recommended',
                        style: theme.textTheme.labelSmall,
                      ),
                      backgroundColor: colorScheme.primaryContainer,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.check_circle,
                        color: colorScheme.primary,
                      ),
                    ),
                ],
              ),
              if (option.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  option.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (option.warningText != null && isSelected) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option.warningText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (option.expandedContent != null && isSelected) ...[
                const SizedBox(height: 12),
                option.expandedContent!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
