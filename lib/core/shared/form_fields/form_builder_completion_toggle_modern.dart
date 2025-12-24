import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// A modern toggle field for completion status with visual state indicators.
///
/// Features:
/// - Modern switch design
/// - Clear visual state indicators
/// - Smooth animations
/// - Consistent styling with other form fields
class FormBuilderCompletionToggleModern extends StatelessWidget {
  const FormBuilderCompletionToggleModern({
    required this.name,
    this.label,
    this.initialValue = false,
    this.validator,
    this.enabled = true,
    this.entityType = CompletionEntityType.task,
    super.key,
  });

  final String name;
  final String? label;
  final bool initialValue;
  final String? Function(bool?)? validator;
  final bool enabled;
  final CompletionEntityType entityType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: FormBuilderSwitch(
        name: name,
        initialValue: initialValue,
        validator: validator,
        enabled: enabled,
        title: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(colorScheme),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconData(),
                size: 20,
                color: _getIconColor(colorScheme),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label ?? _getDefaultLabel(),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getSubtitle(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        activeColor: colorScheme.primary,
        inactiveThumbColor: colorScheme.outline,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }

  IconData _getIconData() {
    return switch (entityType) {
      CompletionEntityType.task => Icons.task_alt,
      CompletionEntityType.project => Icons.folder_special,
    };
  }

  Color _getIconBackgroundColor(ColorScheme colorScheme) {
    return switch (entityType) {
      CompletionEntityType.task => colorScheme.primaryContainer,
      CompletionEntityType.project => colorScheme.secondaryContainer,
    };
  }

  Color _getIconColor(ColorScheme colorScheme) {
    return switch (entityType) {
      CompletionEntityType.task => colorScheme.onPrimaryContainer,
      CompletionEntityType.project => colorScheme.onSecondaryContainer,
    };
  }

  String _getDefaultLabel() {
    return switch (entityType) {
      CompletionEntityType.task => 'Mark as completed',
      CompletionEntityType.project => 'Mark project as completed',
    };
  }

  String _getSubtitle() {
    return switch (entityType) {
      CompletionEntityType.task => 'Toggle when the task is finished',
      CompletionEntityType.project => 'Toggle when the project is finished',
    };
  }
}

/// Different entity types for completion toggles.
enum CompletionEntityType {
  task,
  project,
}
