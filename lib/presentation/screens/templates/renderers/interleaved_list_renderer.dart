import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/screens/tiles/screen_item_tile_registry.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

class InterleavedListRenderer extends StatelessWidget {
  const InterleavedListRenderer({
    required this.data,
    super.key,
    this.title,
    this.compactTiles = false,
    this.onTaskToggle,
  });

  final DataSectionResult data;
  final String? title;
  final bool compactTiles;
  final void Function(String, bool?)? onTaskToggle;

  @override
  Widget build(BuildContext context) {
    const registry = ScreenItemTileRegistry();

    if (data.items.isEmpty) {
      return const SizedBox.shrink();
    }

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
          itemCount: data.items.length,
          separatorBuilder: (context, index) {
            final current = data.items[index];
            final next = data.items[index + 1];
            final isTaskToTask =
                current is ScreenItemTask && next is ScreenItemTask;
            return isTaskToTask
                ? const Divider(height: 1)
                : const SizedBox(height: 8);
          },
          itemBuilder: (context, index) {
            final item = data.items[index];
            return registry.build(
              context,
              item: item,
              onTaskToggle: onTaskToggle,
              compactTiles: compactTiles,
            );
          },
        ),
      ],
    );
  }
}
