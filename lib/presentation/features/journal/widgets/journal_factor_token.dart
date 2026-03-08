import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/journal/ui/journal_motion_tokens.dart';
import 'package:taskly_bloc/presentation/features/journal/ui/tracker_value_formatter.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalFactorToken extends StatelessWidget {
  const JournalFactorToken({
    required this.icon,
    required this.text,
    required this.state,
    this.onTap,
    this.enabled = true,
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final String text;
  final JournalTrackerValueState state;
  final VoidCallback? onTap;
  final bool enabled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    final scheme = theme.colorScheme;
    final colors = _tokenColors(scheme);

    return AnimatedContainer(
      duration: kJournalMotionDuration,
      curve: kJournalMotionCurve,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceSm,
            vertical: tokens.spaceXs - 1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colors.foreground),
              SizedBox(width: tokens.spaceXxs),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({Color background, Color border, Color foreground}) _tokenColors(
    ColorScheme scheme,
  ) {
    if (!enabled) {
      return (
        background: scheme.surfaceContainerLow,
        border: scheme.outlineVariant.withValues(alpha: 0.32),
        foreground: scheme.onSurfaceVariant.withValues(alpha: 0.55),
      );
    }
    if (selected) {
      return (
        background: scheme.primary,
        border: scheme.primary,
        foreground: scheme.onPrimary,
      );
    }
    return switch (state) {
      JournalTrackerValueState.warn => (
        background: scheme.errorContainer.withValues(alpha: 0.22),
        border: scheme.error.withValues(alpha: 0.36),
        foreground: scheme.onSurface,
      ),
      JournalTrackerValueState.goalHit => (
        background: scheme.tertiaryContainer.withValues(alpha: 0.28),
        border: scheme.tertiary.withValues(alpha: 0.34),
        foreground: scheme.onSurface,
      ),
      JournalTrackerValueState.normal => (
        background: Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.03),
          scheme.surfaceContainerHigh,
        ),
        border: scheme.outlineVariant.withValues(alpha: 0.26),
        foreground: scheme.onSurfaceVariant,
      ),
    };
  }
}
