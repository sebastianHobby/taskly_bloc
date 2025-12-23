import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// A modern dropdown for selecting label types with visual indicators.
///
/// Features:
/// - Modern Material 3 design
/// - Visual icons for each label type
/// - Clear descriptions
/// - Consistent styling
class FormBuilderLabelTypePickerModern extends StatelessWidget {
  const FormBuilderLabelTypePickerModern({
    required this.name,
    this.label,
    this.hint,
    this.initialValue = LabelType.label,
    this.validator,
    this.enabled = true,
    this.isRequired = false,
    this.compact = false,
    super.key,
  });

  final String name;
  final String? label;
  final String? hint;
  final LabelType initialValue;
  final String? Function(LabelType?)? validator;
  final bool enabled;
  final bool isRequired;

  /// If true, uses reduced padding for more compact layouts.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FormBuilderDropdown<LabelType>(
        name: name,
        initialValue: initialValue,
        validator: validator,
        enabled: enabled,
        items: LabelType.values
            .map(
              (type) => DropdownMenuItem<LabelType>(
                value: type,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: _getTypeColor(type, colorScheme),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getTypeIcon(type),
                        size: 14,
                        color: _getTypeIconColor(type, colorScheme),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getTypeName(type),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _getTypeDescription(type),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.category,
              size: 20,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            size: 24,
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.outline.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.outline.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.error,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.error,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(LabelType type) {
    return switch (type) {
      LabelType.label => Icons.label,
      LabelType.value => Icons.bookmark,
    };
  }

  Color _getTypeColor(LabelType type, ColorScheme colorScheme) {
    return switch (type) {
      LabelType.label => colorScheme.primaryContainer,
      LabelType.value => colorScheme.secondaryContainer,
    };
  }

  Color _getTypeIconColor(LabelType type, ColorScheme colorScheme) {
    return switch (type) {
      LabelType.label => colorScheme.onPrimaryContainer,
      LabelType.value => colorScheme.onSecondaryContainer,
    };
  }

  String _getTypeName(LabelType type) {
    return switch (type) {
      LabelType.label => 'Label',
      LabelType.value => 'Value',
    };
  }

  String _getTypeDescription(LabelType type) {
    return switch (type) {
      LabelType.label => 'For categorization and organization',
      LabelType.value => 'For metadata and properties',
    };
  }
}
