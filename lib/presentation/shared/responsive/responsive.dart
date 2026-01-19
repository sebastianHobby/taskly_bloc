import 'package:flutter/material.dart';

/// Centralized breakpoints for responsive design.
///
/// Based on Material Design 3 guidelines:
/// - Compact: 0-599dp (phones)
/// - Medium: 600-839dp (tablets, foldables)
/// - Expanded: 840dp+ (large tablets, desktop)
///
/// Usage:
/// ```dart
/// final size = MediaQuery.sizeOf(context);
/// if (Breakpoints.isCompact(size.width)) {
///   // Mobile layout
/// }
/// ```
abstract final class Breakpoints {
  /// Compact breakpoint (mobile phones).
  static const double compact = 600;

  /// Medium breakpoint (tablets, foldables).
  static const double medium = 840;

  /// Expanded breakpoint (large tablets, desktops).
  static const double expanded = 1200;

  /// Returns true if width is in compact range (< 600dp).
  static bool isCompact(double width) => width < compact;

  /// Returns true if width is in medium range (600-839dp).
  static bool isMedium(double width) => width >= compact && width < medium;

  /// Returns true if width is in expanded range (840dp+).
  static bool isExpanded(double width) => width >= medium;

  /// Returns true if width is large expanded (1200dp+).
  static bool isLargeExpanded(double width) => width >= expanded;
}

/// Window size class based on Material Design 3.
enum WindowSizeClass {
  /// Phones in portrait (< 600dp)
  compact,

  /// Tablets, foldables, phones in landscape (600-839dp)
  medium,

  /// Large tablets, desktops (840dp+)
  expanded;

  /// Creates a WindowSizeClass from the given width.
  factory WindowSizeClass.fromWidth(double width) {
    if (Breakpoints.isCompact(width)) return WindowSizeClass.compact;
    if (Breakpoints.isMedium(width)) return WindowSizeClass.medium;
    return WindowSizeClass.expanded;
  }

  /// Creates a WindowSizeClass from BuildContext.
  factory WindowSizeClass.of(BuildContext context) {
    return WindowSizeClass.fromWidth(MediaQuery.sizeOf(context).width);
  }

  /// Returns true if this is compact size.
  bool get isCompact => this == WindowSizeClass.compact;

  /// Returns true if this is medium size.
  bool get isMedium => this == WindowSizeClass.medium;

  /// Returns true if this is expanded size.
  bool get isExpanded => this == WindowSizeClass.expanded;

  /// Returns true if this is at least medium size.
  bool get isAtLeastMedium => this != WindowSizeClass.compact;
}

/// Extension to easily get WindowSizeClass from BuildContext.
extension ResponsiveContext on BuildContext {
  /// Returns the current WindowSizeClass.
  WindowSizeClass get windowSizeClass => WindowSizeClass.of(this);

  /// Returns true if the screen is compact (mobile).
  bool get isCompactScreen => windowSizeClass.isCompact;

  /// Returns true if the screen is at least medium (tablet+).
  bool get isAtLeastMediumScreen => windowSizeClass.isAtLeastMedium;

  /// Returns true if the screen is expanded (desktop).
  bool get isExpandedScreen => windowSizeClass.isExpanded;
}

/// Wraps a Scaffold body with simple content constraints for wide screens.
///
/// On compact/medium layouts, this returns [child] (optionally with horizontal
/// padding). On expanded layouts, this centers and constrains the max width.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    required this.child,
    required this.isExpandedLayout,
    this.maxWidth = 800,
    this.horizontalPadding = 0,
    super.key,
  });

  final Widget child;
  final bool isExpandedLayout;
  final double maxWidth;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (!isExpandedLayout) {
      if (horizontalPadding > 0) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        );
      }
      return child;
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
