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
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    if (isCompact) {
      return Wrap(
        spacing: tokens.spaceSm,
        runSpacing: tokens.spaceSm,
        children: chips,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < chips.length; index++) ...[
            if (index > 0) SizedBox(width: tokens.spaceSm),
            chips[index],
          ],
        ],
      ),
    );
  }
}
