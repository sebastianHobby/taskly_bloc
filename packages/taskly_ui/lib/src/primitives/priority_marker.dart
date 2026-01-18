import 'package:flutter/material.dart';

/// A small priority marker used in dense meta lines.
///
/// This matches the legacy "priority flag" encoding: a small vertical rounded
/// rectangle. Intended to be shown only for P1/P2.
class PriorityMarker extends StatelessWidget {
  const PriorityMarker({
    required this.color,
    super.key,
    this.width = 6,
    this.height = 12,
    this.borderRadius = 2,
  });

  final Color color;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
