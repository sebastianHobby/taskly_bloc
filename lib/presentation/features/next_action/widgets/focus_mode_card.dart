import 'package:flutter/material.dart';
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
    final colorScheme = theme.colorScheme;
    final unselectedColor = colorScheme.onSurface;

    return TasklyCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      backgroundColor: isSelected ? colorScheme.primary.withOpacity(0.1) : null,
      borderColor: isSelected ? colorScheme.primary : null,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconForFocusMode(focusMode),
                      color: isSelected ? colorScheme.primary : unselectedColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        focusMode.displayName.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? colorScheme.primary
                              : unselectedColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  focusMode.description,
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isRecommended)
            Positioned(
              top: 8,
              right: 8,
              child: TasklyBadge(
                label: 'RECOMMENDED',
                color: colorScheme.tertiary,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForFocusMode(FocusMode focusMode) {
    return switch (focusMode) {
      FocusMode.responsive => Icons.local_fire_department,
      FocusMode.sustainable => Icons.balance,
      FocusMode.intentional => Icons.lightbulb_outline,
      FocusMode.personalized => Icons.tune,
    };
  }
}
