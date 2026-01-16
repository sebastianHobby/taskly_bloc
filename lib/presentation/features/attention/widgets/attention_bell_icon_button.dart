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
            Colors.orange,
            Colors.orange.withValues(alpha: 0.28),
          ),
          AttentionBellSeverity.none => (
            theme.colorScheme.primary,
            Colors.transparent,
          ),
        };

        final countText = total > 99 ? '99+' : '$total';

        return IconButton(
          tooltip: 'Attention',
          onPressed: onPressed,
          icon: SizedBox(
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
                    ),
                  ),
              ],
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
  });

  final String text;
  final Color color;

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
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
