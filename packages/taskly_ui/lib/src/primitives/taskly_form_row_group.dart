import 'package:flutter/widgets.dart';

class TasklyFormRowGroup extends StatelessWidget {
  const TasklyFormRowGroup({
    required this.children,
    this.spacing = 8,
    this.runSpacing = 8,
    super.key,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }
}
