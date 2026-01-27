import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

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
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    this.initialValue = false,
    this.validator,
    this.enabled = true,
    super.key,
  });

  final String name;

  /// Primary label shown next to the toggle.
  ///
  /// Shared UI must not hardcode user-facing strings; provide localized text
  /// from the app.
  final String title;

  /// Secondary label shown under [title].
  ///
  /// Shared UI must not hardcode user-facing strings; provide localized text
  /// from the app.
  final String subtitle;

  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;

  final bool initialValue;
  final String? Function(bool?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.sectionPaddingH,
        vertical: tokens.spaceSm,
      ),
      child: FormBuilderSwitch(
        name: name,
        initialValue: initialValue,
        validator: validator,
        enabled: enabled,
        title: Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: tokens.spaceMd),
              padding: EdgeInsets.all(tokens.spaceSm),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(tokens.radiusSm),
              ),
              child: Icon(
                icon,
                size: tokens.spaceLg3,
                color: iconColor,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall,
                  ),
                  SizedBox(height: tokens.spaceXxs),
                  Text(
                    subtitle,
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
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          contentPadding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLg,
            vertical: tokens.spaceMd,
          ),
        ),
        activeColor: colorScheme.primary,
        inactiveThumbColor: colorScheme.outline,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
