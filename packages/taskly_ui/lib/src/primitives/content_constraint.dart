import 'package:flutter/material.dart';

/// A widget that constrains its child to a maximum width and centers it.
///
/// Useful for keeping content readable on wide screens while allowing
/// full-width on narrow screens.
///
/// By default, only applies constraints on screens wider than [Breakpoints.medium]
/// (840dp) to avoid unnecessary constraints on mobile/tablet.
///
/// Example:
/// ```dart
/// ContentConstraint(
///   child: ListView(...),
/// )
/// ```
class ContentConstraint extends StatelessWidget {
  const ContentConstraint({
    required this.child,
    required this.applyConstraints,
    this.maxWidth = 800,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  /// The child widget to constrain.
  final Widget child;

  /// Whether constraints should be applied.
  ///
  /// The app should decide this using its own responsive logic.
  final bool applyConstraints;

  /// Maximum width for the content. Defaults to 800dp.
  final double maxWidth;

  /// Padding applied to the constrained content.
  final EdgeInsetsGeometry padding;

  /// Alignment when content is narrower than available space.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    if (!applyConstraints) {
      return Padding(padding: padding, child: child);
    }

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// A sliver version of [ContentConstraint] for use in CustomScrollView.
///
/// Example:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverContentConstraint(
///       sliver: SliverList(...),
///     ),
///   ],
/// )
/// ```
class SliverContentConstraint extends StatelessWidget {
  const SliverContentConstraint({
    required this.sliver,
    this.maxWidth = 800,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// The sliver to constrain.
  final Widget sliver;

  /// Maximum width for the content. Defaults to 800dp.
  final double maxWidth;

  /// Padding applied to the constrained content.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.crossAxisExtent;
        final effectiveMaxWidth = availableWidth > maxWidth
            ? maxWidth
            : availableWidth;
        final horizontalPadding = (availableWidth - effectiveMaxWidth) / 2;

        return SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
          ).add(padding),
          sliver: sliver,
        );
      },
    );
  }
}

/// Wraps a Scaffold body with content constraints for wide screens.
///
/// Provides consistent padding and max-width handling across all list views.
/// On mobile/tablet, applies standard edge padding.
/// On desktop, constrains content width and centers it.
///
/// Example:
/// ```dart
/// Scaffold(
///   body: ResponsiveBody(
///     child: ListView(...),
///   ),
/// )
/// ```
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    required this.child,
    required this.isExpandedLayout,
    this.maxWidth = 800,
    this.horizontalPadding = 0,
    super.key,
  });

  /// The content to display.
  final Widget child;

  /// Whether the layout should be treated as expanded (desktop / wide).
  ///
  /// The app should decide this using its own responsive logic.
  final bool isExpandedLayout;

  /// Maximum width for content on wide screens.
  final double maxWidth;

  /// Horizontal padding applied on all screen sizes.
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (!isExpandedLayout) {
      // Mobile/Tablet: Just apply horizontal padding if specified
      if (horizontalPadding > 0) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        );
      }
      return child;
    }

    // Desktop: Constrain width and center
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
