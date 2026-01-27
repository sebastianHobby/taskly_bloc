import 'package:flutter/widgets.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class TasklyFormRowGroup extends StatelessWidget {
  const TasklyFormRowGroup({
    required this.children,
    this.spacing,
    this.runSpacing,
    super.key,
  });

  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Wrap(
      spacing: spacing ?? tokens.spaceSm,
      runSpacing: runSpacing ?? tokens.spaceSm,
      children: children,
    );
  }
}
