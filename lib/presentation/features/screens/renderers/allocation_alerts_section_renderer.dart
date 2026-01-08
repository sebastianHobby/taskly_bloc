import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/features/screens/renderers/attention_support_section_widgets.dart';

class AllocationAlertsSectionRenderer extends StatelessWidget {
  const AllocationAlertsSectionRenderer({required this.data, super.key});

  final AllocationAlertsSectionResult data;

  @override
  Widget build(BuildContext context) {
    if (data.alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SupportSectionCard(
      title: 'Allocation Alerts',
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
                Routing.toScreenKey(context, 'focus_setup');
              },
              child: Text('View all ${data.alerts.length} alerts'),
            ),
        ],
      ),
    );
  }
}
