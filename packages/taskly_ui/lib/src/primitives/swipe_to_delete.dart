import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Direction for the swipe to delete gesture.
enum SwipeDirection {
  /// Swipe left to right (start to end).
  startToEnd,

  /// Swipe right to left (end to start).
  endToStart,

  /// Both directions.
  horizontal,
}

/// A wrapper widget that adds swipe-to-delete functionality to its child.
///
/// This widget wraps the child in a [Dismissible] widget with a modern
/// Material 3 styled background showing a delete action.
class SwipeToDelete extends StatelessWidget {
  const SwipeToDelete({
    required this.itemKey,
    required this.child,
    required this.onDismissed,
    required this.deleteLabel,
    super.key,
    this.confirmDismiss,
    this.direction = SwipeDirection.endToStart,
    this.dismissThresholds = const {DismissDirection.endToStart: 0.4},
    this.enabled = true,
    this.background,
  });

  /// A unique key for this dismissible item.
  final Key itemKey;

  /// The widget to wrap with swipe-to-delete.
  final Widget child;

  /// Called when the item is dismissed.
  final VoidCallback onDismissed;

  /// The label shown in the swipe background.
  ///
  /// Must be provided by the caller (no app l10n inside taskly_ui).
  final String deleteLabel;

  /// Called to confirm whether the item should be dismissed.
  ///
  /// If this returns `false`, the item will not be dismissed.
  final Future<bool> Function()? confirmDismiss;

  /// The direction(s) in which the item can be swiped.
  final SwipeDirection direction;

  /// The thresholds for dismissing the item.
  final Map<DismissDirection, double> dismissThresholds;

  /// Whether swipe-to-delete is enabled.
  final bool enabled;

  /// Optional custom background widget used for both swipe directions.
  ///
  /// If null, a default Material 3 delete background is used.
  final Widget? background;

  DismissDirection get _dismissDirection => switch (direction) {
    SwipeDirection.startToEnd => DismissDirection.startToEnd,
    SwipeDirection.endToStart => DismissDirection.endToStart,
    SwipeDirection.horizontal => DismissDirection.horizontal,
  };

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dismissible(
      key: itemKey,
      direction: _dismissDirection,
      dismissThresholds: dismissThresholds,
      confirmDismiss: confirmDismiss != null
          ? (_) async {
              await HapticFeedback.mediumImpact();
              return confirmDismiss!();
            }
          : null,
      onDismissed: (_) {
        unawaited(HapticFeedback.heavyImpact());
        onDismissed();
      },
      background:
          background ??
          _buildBackground(context, colorScheme, isStartToEnd: true),
      secondaryBackground:
          background ??
          _buildBackground(context, colorScheme, isStartToEnd: false),
      child: child,
    );
  }

  Widget _buildBackground(
    BuildContext context,
    ColorScheme colorScheme, {
    required bool isStartToEnd,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: isStartToEnd ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.only(
        left: isStartToEnd ? 24 : 0,
        right: isStartToEnd ? 0 : 24,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_outline_rounded,
            color: colorScheme.onErrorContainer,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            deleteLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
