import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/features/attention/widgets/attention_bell_icon_button.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

/// Centralized app-bar action conventions for Taskly screens.
abstract final class TasklyAppBarActions {
  static const Set<String> _bellExcludedScreenKeys = {
    // Avoid navigating to the current screen.
    'review_inbox',
    // Avoid adding attention affordances inside Settings.
    'settings',
  };

  /// Returns [actions] plus the global Attention bell when appropriate.
  ///
  /// The bell is shown for 1-segment screen routes (e.g. `/journal`) and is
  /// hidden for excluded screens like Attention Inbox and Settings.
  static List<Widget> withAttentionBell(
    BuildContext context, {
    required List<Widget> actions,
  }) {
    if (!_shouldShowBellForCurrentLocation(context)) return actions;

    return <Widget>[
      ...actions,
      AttentionBellIconButton(
        onPressed: () => Routing.toScreenKey(context, 'review_inbox'),
      ),
    ];
  }

  static bool _shouldShowBellForCurrentLocation(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final segments = uri.pathSegments;

    if (segments.length != 1) return false;

    final screenKey = Routing.parseScreenKey(segments.single);
    return !_bellExcludedScreenKeys.contains(screenKey);
  }
}
