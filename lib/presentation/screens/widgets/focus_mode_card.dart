import 'package:flutter/material.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/taskly_card.dart';

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
      borderRadius: 12,
      backgroundColor: isSelected
          ? colorScheme.primary.withOpacity(0.05)
          : null,
      borderColor: isSelected ? colorScheme.primary : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
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
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        focusMode.wizardTagline,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
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
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Radio<bool>(
                    value: true,
                    groupValue: isSelected,
                    onChanged: (_) => onTap(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          if (isRecommended)
            Positioned(
              top: -10,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.recommendedLabel.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForFocusMode(FocusMode focusMode) {
    return switch (focusMode) {
      FocusMode.intentional => Icons.gps_fixed,
      FocusMode.sustainable => Icons.tune,
      FocusMode.responsive => Icons.bolt,
      FocusMode.personalized => Icons.tune,
    };
  }
}
