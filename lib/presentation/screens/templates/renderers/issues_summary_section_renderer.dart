import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_support_section_widgets.dart';

class IssuesSummarySectionRenderer extends StatelessWidget {
  const IssuesSummarySectionRenderer({required this.data, super.key});

  final IssuesSummarySectionResult data;

  @override
  Widget build(BuildContext context) {
    if (data.items.isEmpty) {
      return SupportSectionCard(
        title: 'Issues',
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('All clear! No issues to address.'),
          ],
        ),
      );
    }

    final infoCount =
        data.items.length - data.criticalCount - data.warningCount;

    return SupportSectionCard(
      title: 'Issues',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (data.criticalCount > 0) ...[
                CountBadge(
                  count: data.criticalCount,
                  color: Theme.of(context).colorScheme.error,
                  label: 'Critical',
                ),
                const SizedBox(width: 8),
              ],
              if (data.warningCount > 0) ...[
                CountBadge(
                  count: data.warningCount,
                  color: Colors.orange,
                  label: 'Warning',
                ),
                const SizedBox(width: 8),
              ],
              if (infoCount > 0)
                CountBadge(
                  count: infoCount,
                  color: Theme.of(context).colorScheme.primary,
                  label: 'Info',
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...data.items.take(3).map((item) => AttentionItemTile(item: item)),
          if (data.items.length > 3)
            TextButton(
              onPressed: () {
                Routing.toScreenKey(context, 'orphan_tasks');
              },
              child: Text('View all ${data.items.length} issues'),
            ),
        ],
      ),
    );
  }
}
