import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_support_section_widgets.dart';

class AllocationAlertsSectionRenderer extends StatelessWidget {
  const AllocationAlertsSectionRenderer({
    required this.data,
    super.key,
    this.title,
  });

  final AllocationAlertsSectionResult data;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (data.alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveTitle = title ?? 'Allocation Alerts';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SupportSectionCard(
      title: effectiveTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${data.totalExcluded} '
            '${data.totalExcluded == 1 ? 'alert' : 'alerts'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...data.alerts.take(2).map((alert) => AttentionItemTile(item: alert)),
          if (data.alerts.length > 2)
            TextButton(
              onPressed: () {
                Routing.toScreenKey(context, 'review_inbox');
              },
              child: Text('Open review inbox (${data.alerts.length})'),
            ),
        ],
      ),
    );
  }
}
