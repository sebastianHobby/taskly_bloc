import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/features/screens/renderers/attention_support_section_widgets.dart';

class CheckInSummarySectionRenderer extends StatelessWidget {
  const CheckInSummarySectionRenderer({required this.data, super.key});

  final CheckInSummarySectionResult data;

  @override
  Widget build(BuildContext context) {
    if (data.dueReviews.isEmpty) {
      return const SizedBox.shrink();
    }

    return SupportSectionCard(
      title: 'Reviews Due',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.hasOverdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(
                  alpha: 0.1,
                ),
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
          ...data.dueReviews.map((review) => ReviewItemTile(item: review)),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              Routing.toScreenKey(context, 'check_in');
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Check-in'),
          ),
        ],
      ),
    );
  }
}
