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

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final badges = <Widget>[];
    if (data.actionCount > 0) {
      badges.add(
        CountBadge(
          count: data.actionCount,
          color: scheme.primary,
          label: 'Action',
        ),
      );
    }
    if (data.reviewCount > 0) {
      badges.add(
        CountBadge(
          count: data.reviewCount,
          color: scheme.secondary,
          label: 'Review',
        ),
      );
    }
    if (data.criticalCount > 0) {
      badges.add(
        CountBadge(
          count: data.criticalCount,
          color: scheme.error,
          label: 'Critical',
        ),
      );
    }
    if (data.warningCount > 0) {
      badges.add(
        CountBadge(
          count: data.warningCount,
          color: Colors.orange,
          label: 'Warning',
        ),
      );
    }
    if (data.infoCount > 0) {
      badges.add(
        CountBadge(count: data.infoCount, color: scheme.primary, label: 'Info'),
      );
    }

    return SupportSectionCard(
      title: effectiveTitle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            total == 0 ? Icons.check_circle_outline : Icons.notifications_none,
            color: total == 0 ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: badges.isEmpty
                ? Text(
                    'All clear',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: badges,
                  ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: () =>
                Routing.toScreenKey(context, data.overflowScreenKey),
            icon: const Icon(Icons.inbox_outlined),
            label: const Text('Inbox'),
          ),
        ],
      ),
    );
  }
}
