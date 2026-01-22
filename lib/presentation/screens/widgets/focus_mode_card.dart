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

    final behaviorBullets = _behaviorBullets(focusMode);

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
                        maxLines: 1,
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
                      const SizedBox(height: 12),
                      _PreviewStrip(focusMode: focusMode),
                      const SizedBox(height: 12),
                      for (final bullet in behaviorBullets)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  bullet,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
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
      FocusMode.sustainable => Icons.gps_fixed,
      FocusMode.responsive => Icons.schedule,
      FocusMode.personalized => Icons.gps_fixed,
    };
  }

  List<String> _behaviorBullets(FocusMode focusMode) {
    return switch (focusMode) {
      FocusMode.responsive => const [
        'You start with due/starting tasks to prevent slips.',
        'Then Suggested picks fill the rest (value-aligned).',
        'Good for weeks with a lot of time pressure.',
      ],
      _ => const [
        'Suggested picks are chosen from your values (calm, explainable).',
        'Due/starting tasks still show up as guardrails.',
        'Optionally keep your values in balance.',
      ],
    };
  }
}

class _PreviewStrip extends StatelessWidget {
  const _PreviewStrip({required this.focusMode});

  final FocusMode focusMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final scheduledEmphasis = focusMode == FocusMode.responsive;
    final scheduledBg = scheduledEmphasis
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final scheduledFg = scheduledEmphasis
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    final suggestedEmphasis = !scheduledEmphasis;
    final suggestedBg = suggestedEmphasis
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final suggestedFg = suggestedEmphasis
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    Widget pill({
      required String text,
      required Color bg,
      required Color fg,
      required IconData icon,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        pill(
          text: 'Scheduled first',
          bg: scheduledBg,
          fg: scheduledFg,
          icon: Icons.schedule,
        ),
        pill(
          text: 'Suggested next',
          bg: suggestedBg,
          fg: suggestedFg,
          icon: Icons.auto_awesome,
        ),
      ],
    );
  }
}
