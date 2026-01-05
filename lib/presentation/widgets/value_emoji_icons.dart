import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/shared/utils/emoji_utils.dart';

/// Small emoji icon badges showing task's values
class ValueEmojiIcons extends StatelessWidget {
  const ValueEmojiIcons({
    required this.values,
    this.maxVisible = 3,
    super.key,
  });

  final List<Value> values;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    final visibleValues = values.take(maxVisible).toList();
    final hasMore = values.length > maxVisible;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visibleValues.map((value) {
          final emoji = value.iconName?.isNotEmpty ?? false
              ? value.iconName!
              : '⭐';

          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: value.name,
              child: Text(
                emoji,
                style: EmojiUtils.emojiTextStyle(fontSize: 14),
              ),
            ),
          );
        }),
        if (hasMore)
          Text(
            '+${values.length - maxVisible}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
