import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_support_section_widgets.dart';

class CheckInSummarySectionRenderer extends StatelessWidget {
  const CheckInSummarySectionRenderer({
    required this.data,
    super.key,
    this.title,
  });

  final CheckInSummarySectionResult data;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (data.dueReviews.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveTitle = title ?? 'Reviews Due';
    final count = data.dueReviews.length;
    final shouldCollapse = count > 1;
    final countLabel = count == 1 ? '1 review due' : '$count reviews due';

    return SupportSectionCard(
      title: effectiveTitle,
      child: shouldCollapse
          ? Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                initiallyExpanded: false,
                title: Row(
                  children: [
                    Icon(
                      data.hasOverdue
                          ? Icons.warning_amber_rounded
                          : Icons.rate_review_outlined,
                      size: 18,
                      color: data.hasOverdue
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        countLabel,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                children: [
                  if (data.hasOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Some reviews are overdue',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ...data.dueReviews.map(
                    (review) => ReviewItemTile(item: review),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      Routing.toScreenKey(context, 'review_inbox');
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Open Review Inbox'),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.hasOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Some reviews are overdue',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ...data.dueReviews.map(
                  (review) => ReviewItemTile(item: review),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    Routing.toScreenKey(context, 'review_inbox');
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Open Review Inbox'),
                ),
              ],
            ),
    );
  }
}
