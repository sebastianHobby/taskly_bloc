import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

/// A modern dropdown field for selecting projects with consistent styling.
///
/// Features:
/// - Modern Material 3 design
/// - Project icons and visual indicators
/// - Proper validation and state management
/// - Support for "no project" option
class FormBuilderProjectPickerModern extends StatelessWidget {
  const FormBuilderProjectPickerModern({
    required this.name,
    required this.availableProjects,
    this.label,
    this.hint,
    this.initialValue,
    this.validator,
    this.enabled = true,
    this.isRequired = false,
    this.allowNoProject = true,
    this.noProjectText,
    super.key,
  });

  final String name;
  final List<Project> availableProjects;
  final String? label;
  final String? hint;
  final String? initialValue;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool isRequired;
  final bool allowNoProject;
  final String? noProjectText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final effectiveNoProjectText = noProjectText ?? context.l10n.noProjectLabel;

    final options = <DropdownMenuItem<String>>[
      if (allowNoProject)
        DropdownMenuItem<String>(
          value: '',
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                margin: EdgeInsets.only(right: tokens.spaceMd),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(tokens.radiusSm),
                ),
                child: Icon(
                  Icons.folder_off_outlined,
                  size: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                effectiveNoProjectText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ...availableProjects.map(
        (project) => DropdownMenuItem<String>(
          value: project.id,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                margin: EdgeInsets.only(right: tokens.spaceMd),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(tokens.radiusSm),
                ),
                child: Icon(
                  Icons.folder,
                  size: 14,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              Expanded(
                child: Text(
                  project.name,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (project.completed)
                Container(
                  margin: EdgeInsets.only(left: tokens.spaceSm),
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceSm,
      ),
      child: FormBuilderDropdown<String>(
        name: name,
        initialValue: initialValue,
        validator: validator,
        enabled: enabled,
        items: options,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            size: 24,
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            borderSide: BorderSide(
              color: colorScheme.error,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            borderSide: BorderSide(
              color: colorScheme.error,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLg,
            vertical: tokens.spaceMd,
          ),
        ),
      ),
    );
  }
}
