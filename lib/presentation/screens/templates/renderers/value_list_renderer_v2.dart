import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/presentation/screens/tiles/screen_item_tile_registry.dart';
import 'package:taskly_bloc/presentation/widgets/sliver_separated_list.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

class ValueListRendererV2 extends StatelessWidget {
  const ValueListRendererV2({
    required this.data,
    required this.params,
    super.key,
    this.title,
  });

  final DataV2SectionResult data;
  final ListSectionParamsV2 params;
  final String? title;

  @override
  Widget build(BuildContext context) {
    const registry = ScreenItemTileRegistry();
    final values = data.items.whereType<ScreenItemValue>().toList(
      growable: false,
    );

    if (values.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverSeparatedList(
      header: title == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TasklyHeader(title: title!),
            ),
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = values[index];
        final stats = data.enrichment?.valueStatsByValueId[item.value.id];
        return registry.build(
          context,
          item: item,
          valueStats: stats,
        );
      },
    );
  }
}
