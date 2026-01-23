import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_bell_cubit.dart';

enum AttentionBellSeverity { none, warning, critical }

class AttentionBellIconButton extends StatelessWidget {
  const AttentionBellIconButton({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AttentionBellCubit, AttentionBellState>(
      bloc: getIt<AttentionBellCubit>(),
      builder: (context, state) {
        final total = state.totalCount;

        final severity = switch ((
          state.criticalCount > 0,
          state.warningCount > 0,
        )) {
          (true, _) => AttentionBellSeverity.critical,
          (false, true) => AttentionBellSeverity.warning,
          _ => AttentionBellSeverity.none,
        };

        final showBadge = total > 0;
        final (badgeColor, haloColor) = switch (severity) {
          AttentionBellSeverity.critical => (
            theme.colorScheme.error,
            theme.colorScheme.error.withValues(alpha: 0.35),
          ),
          AttentionBellSeverity.warning => (
            theme.colorScheme.secondary,
            theme.colorScheme.secondary.withValues(alpha: 0.28),
          ),
          AttentionBellSeverity.none => (
            theme.colorScheme.primary,
            theme.colorScheme.surface.withValues(alpha: 0),
          ),
        };
        final badgeTextColor = switch (severity) {
          AttentionBellSeverity.critical => theme.colorScheme.onError,
          AttentionBellSeverity.warning => theme.colorScheme.onSecondary,
          AttentionBellSeverity.none => theme.colorScheme.onPrimary,
        };

        final countText = total > 99 ? '99+' : '$total';

        final semanticsValue = () {
          if (state.isLoading) return 'Loading attention status.';
          if (state.error != null) return 'Attention status unavailable.';
          if (total == 0) return 'No items need attention.';

          final severityText = switch (severity) {
            AttentionBellSeverity.critical => 'critical',
            AttentionBellSeverity.warning => 'warning',
            AttentionBellSeverity.none => 'none',
          };

          return '$total items need attention. Highest severity: $severityText.';
        }();

        return Semantics(
          button: true,
          label: 'Attention',
          value: semanticsValue,
          child: IconButton(
            tooltip: 'Attention',
            onPressed: onPressed,
            icon: ExcludeSemantics(
              child: SizedBox(
                width: 28,
                height: 28,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (showBadge && severity != AttentionBellSeverity.none)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: haloColor,
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Center(
                      child: Icon(Icons.notifications_outlined, size: 24),
                    ),
                    if (showBadge)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: _BellBadge(
                          text: countText,
                          color: badgeColor,
                          textColor: badgeTextColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BellBadge extends StatelessWidget {
  const _BellBadge({
    required this.text,
    required this.color,
    required this.textColor,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(minWidth: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 1,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
