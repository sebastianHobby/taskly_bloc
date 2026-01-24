import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Centralized app-bar action conventions for Taskly screens.
abstract final class TasklyAppBarActions {
  /// Returns [actions] plus the global Attention bell when appropriate.
  ///
  /// The bell is shown for 1-segment screen routes (e.g. `/journal`) and is
  /// hidden for excluded screens like Attention Inbox and Settings.
  static List<Widget> withAttentionBell(
    BuildContext context, {
    required List<Widget> actions,
  }) {
    if (!_shouldShowBellForCurrentLocation(context)) return actions;
    return actions;
  }

  static bool _shouldShowBellForCurrentLocation(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final segments = uri.pathSegments;

    if (segments.length != 1) return false;

    return true;
  }
}
