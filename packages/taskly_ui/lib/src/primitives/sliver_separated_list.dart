import 'package:flutter/widgets.dart';

/// A sliver equivalent of `ListView.separated`.
///
/// Builds lazily using a [SliverList] while inserting separators between items.
/// Optionally inserts a [header] as the first child.
class SliverSeparatedList extends StatelessWidget {
  const SliverSeparatedList({
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    super.key,
    this.header,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0 && header == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final hasHeader = header != null;
    final listChildCount = itemCount <= 0 ? 0 : (itemCount * 2) - 1;
    final totalChildCount = (hasHeader ? 1 : 0) + listChildCount;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (hasHeader && index == 0) return header!;

          final offset = hasHeader ? index - 1 : index;
          if (offset.isOdd) {
            final separatorIndex = offset ~/ 2;
            return separatorBuilder(context, separatorIndex);
          }

          final itemIndex = offset ~/ 2;
          return itemBuilder(context, itemIndex);
        },
        childCount: totalChildCount,
      ),
    );
  }
}
