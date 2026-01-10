import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/theme/app_colors.dart';

/// A small priority indicator using a flag icon.
class PriorityFlag extends StatelessWidget {
  const PriorityFlag({required this.priority, super.key});

  /// Priority level (1-4). If null, the flag is not shown.
  final int? priority;

  @override
  Widget build(BuildContext context) {
    final p = priority;
    if (p == null) return const SizedBox.shrink();

    final color = _priorityColor(Theme.of(context).colorScheme, p);

    return Semantics(
      label: 'Priority',
      value: 'P$p',
      child: Icon(
        Icons.flag_rounded,
        size: 18,
        color: color,
      ),
    );
  }

  Color _priorityColor(ColorScheme scheme, int priority) {
    return switch (priority) {
      1 => AppColors.rambutan80,
      2 => AppColors.cempedak80,
      3 => AppColors.blueberry80,
      4 => scheme.onSurfaceVariant,
      _ => scheme.onSurfaceVariant,
    };
  }
}
