import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/screens/language/models/enrichment_result.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/language/models/value_stats.dart' as domain;
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/screens/tiles/screen_item_tile_registry.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

class ValueListRenderer extends StatelessWidget {
  const ValueListRenderer({
    required this.data,
    super.key,
    this.title,
  });

  final DataSectionResult data;
  final String? title;

  @override
  Widget build(BuildContext context) {
    const registry = ScreenItemTileRegistry();
    final values = data.items.whereType<ScreenItemValue>().toList();
    if (values.isEmpty) return const SizedBox.shrink();

    final statsById = switch (data.enrichment) {
      ValueStatsEnrichmentResult(:final statsByValueId) => statsByValueId,
      _ => const <String, domain.ValueStats>{},
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TasklyHeader(title: title!),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: values.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = values[index];
            return registry.build(
              context,
              item: item,
              valueStats: statsById[item.value.id],
            );
          },
        ),
      ],
    );
  }
}
