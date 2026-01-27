import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

/// A thin vertical bar marker rendered on the left gutter of list rows.
///
/// Used to indicate that an entity is pinned (UX-102 pinned gutter marker).
class PinnedGutterMarker extends StatelessWidget {
  const PinnedGutterMarker({
    required this.color,
    super.key,
    this.width = 3,
    this.height = 16,
  });

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
      ),
    );
  }
}
