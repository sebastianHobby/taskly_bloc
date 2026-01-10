import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/models/settings/focus_mode.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

/// Card widget for displaying a focus mode option.
class FocusModeCard extends StatelessWidget {
  const FocusModeCard({
    required this.focusMode,
    required this.isSelected,
    required this.onTap,
    super.key,
    this.isRecommended = false,
  });

  final FocusMode focusMode;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final colorScheme = theme.colorScheme;

    final titleColor = theme.colorScheme.onSurface;
    final iconBackgroundColor = isSelected
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final iconForegroundColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return TasklyCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      backgroundColor: isSelected
          ? colorScheme.primary.withOpacity(0.08)
          : null,
      borderColor: isSelected ? colorScheme.primary : null,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _getIconForFocusMode(focusMode),
                    color: iconForegroundColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        focusMode.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        focusMode.wizardTagline.toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          letterSpacing: 0.6,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        focusMode.wizardDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                ),
              ],
            ),
          ),
          if (isRecommended)
            Positioned(
              top: 8,
              right: 8,
              child: TasklyBadge(
                label: l10n.recommendedLabel.toUpperCase(),
                color: colorScheme.tertiary,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForFocusMode(FocusMode focusMode) {
    return switch (focusMode) {
      FocusMode.intentional => Icons.center_focus_strong,
      FocusMode.sustainable => Icons.eco,
      FocusMode.responsive => Icons.bolt,
      FocusMode.personalized => Icons.tune,
    };
  }
}
