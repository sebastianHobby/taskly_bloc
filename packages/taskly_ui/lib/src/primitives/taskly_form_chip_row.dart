import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class TasklyFormChipRow extends StatelessWidget {
  const TasklyFormChipRow({
    required this.chips,
    super.key,
  });

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Wrap(
      spacing: tokens.spaceSm,
      runSpacing: tokens.spaceSm,
      children: chips,
    );
  }
}
