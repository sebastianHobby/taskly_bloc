import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_support_section_widgets.dart';

class AttentionBannerSectionRendererV1 extends StatelessWidget {
  const AttentionBannerSectionRendererV1({
    required this.data,
    super.key,
    this.title,
  });

  final AttentionBannerV1SectionResult data;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title ?? 'Attention';

    final total = data.actionCount + data.reviewCount;
    if (total == 0) {
      return SupportSectionCard(
        title: effectiveTitle,
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('All clear! Nothing needs attention.'),
          ],
        ),
      );
    }

    return SupportSectionCard(
      title: effectiveTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (data.actionCount > 0)
                CountBadge(
                  count: data.actionCount,
                  color: Theme.of(context).colorScheme.primary,
                  label: 'Action',
                ),
              if (data.reviewCount > 0)
                CountBadge(
                  count: data.reviewCount,
                  color: Theme.of(context).colorScheme.secondary,
                  label: 'Review',
                ),
              if (data.criticalCount > 0)
                CountBadge(
                  count: data.criticalCount,
                  color: Theme.of(context).colorScheme.error,
                  label: 'Critical',
                ),
              if (data.warningCount > 0)
                CountBadge(
                  count: data.warningCount,
                  color: Colors.orange,
                  label: 'Warning',
                ),
              if (data.infoCount > 0)
                CountBadge(
                  count: data.infoCount,
                  color: Theme.of(context).colorScheme.primary,
                  label: 'Info',
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  Routing.toScreenKey(context, data.overflowScreenKey),
              icon: const Icon(Icons.inbox_outlined),
              label: const Text('Open Attention Inbox'),
            ),
          ),
          if (data.previewItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...data.previewItems.map((i) => AttentionItemTile(item: i)),
          ],
        ],
      ),
    );
  }
}
