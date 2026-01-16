import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/value_needs_attention_badge.dart';
import 'package:taskly_bloc/presentation/screens/tiles/screen_item_tile_builder.dart';
import 'package:taskly_bloc/presentation/widgets/sliver_separated_list.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

class ValueListRendererV2 extends StatelessWidget {
  const ValueListRendererV2({
    required this.data,
    required this.params,
    required this.entityStyle,
    super.key,
    this.title,
    this.persistenceKey,
    this.enableSegmentedTabs = false,
  });

  final DataV2SectionResult data;
  final ListSectionParamsV2 params;
  final EntityStyleV1 entityStyle;
  final String? title;

  /// Stable key for persisting presentation-only state (PageStorage).
  final String? persistenceKey;

  /// When true, shows the My Values segmented tabs (renderer-local state).
  ///
  /// This should only be enabled for the system Values screen.
  final bool enableSegmentedTabs;

  @override
  Widget build(BuildContext context) {
    if (!enableSegmentedTabs) {
      return _PlainValueList(
        data: data,
        title: title,
        entityStyle: entityStyle,
      );
    }

    return _SegmentedValueList(
      data: data,
      title: title,
      entityStyle: entityStyle,
      persistenceKey: persistenceKey,
    );
  }
}

class _PlainValueList extends StatelessWidget {
  const _PlainValueList({
    required this.data,
    required this.title,
    required this.entityStyle,
  });

  final DataV2SectionResult data;
  final String? title;
  final EntityStyleV1 entityStyle;

  @override
  Widget build(BuildContext context) {
    const tileBuilder = ScreenItemTileBuilder();
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
        return tileBuilder.build(
          context,
          item: item,
          entityStyle: entityStyle,
          valueStats: stats,
          titlePrefix: stats?.needsAttention ?? false
              ? ValueNeedsAttentionBadge(value: item.value, stats: stats!)
              : null,
        );
      },
    );
  }
}

enum _MyValuesTab {
  allValues,
  mostUsed,
  primaryFocus,
}

class _SegmentedValueList extends StatefulWidget {
  const _SegmentedValueList({
    required this.data,
    required this.title,
    required this.entityStyle,
    required this.persistenceKey,
  });

  final DataV2SectionResult data;
  final String? title;
  final EntityStyleV1 entityStyle;
  final String? persistenceKey;

  @override
  State<_SegmentedValueList> createState() => _SegmentedValueListState();
}

class _SegmentedValueListState extends State<_SegmentedValueList> {
  static const _storageSuffix = 'valuesTab';

  late _MyValuesTab _tab;
  bool _restored = false;

  String? get _storageKey {
    final base = widget.persistenceKey;
    if (base == null || base.trim().isEmpty) return null;
    return '$base:$_storageSuffix';
  }

  @override
  void initState() {
    super.initState();
    _tab = _MyValuesTab.allValues;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;
    final storageKey = _storageKey;
    if (storageKey == null) {
      _restored = true;
      return;
    }

    final bucket = PageStorage.of(context);
    final stored = bucket.readState(context, identifier: storageKey);
    if (stored is String) {
      _tab = switch (stored) {
        'all' => _MyValuesTab.allValues,
        'most_used' => _MyValuesTab.mostUsed,
        'primary_focus' => _MyValuesTab.primaryFocus,
        _ => _MyValuesTab.allValues,
      };
    }
    _restored = true;
  }

  void _persistTab() {
    final storageKey = _storageKey;
    if (storageKey == null) return;
    final stored = switch (_tab) {
      _MyValuesTab.allValues => 'all',
      _MyValuesTab.mostUsed => 'most_used',
      _MyValuesTab.primaryFocus => 'primary_focus',
    };

    PageStorage.of(context).writeState(
      context,
      stored,
      identifier: storageKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    const tileBuilder = ScreenItemTileBuilder();
    final values = widget.data.items.whereType<ScreenItemValue>().toList();

    if (values.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    values.sort((a, b) {
      final aStats = widget.data.enrichment?.valueStatsByValueId[a.value.id];
      final bStats = widget.data.enrichment?.valueStatsByValueId[b.value.id];

      return switch (_tab) {
        _MyValuesTab.allValues => a.value.name.toLowerCase().compareTo(
          b.value.name.toLowerCase(),
        ),
        _MyValuesTab.mostUsed => () {
          final c = (bStats?.recentCompletionCount ?? 0).compareTo(
            aStats?.recentCompletionCount ?? 0,
          );
          if (c != 0) return c;
          return a.value.name.toLowerCase().compareTo(
            b.value.name.toLowerCase(),
          );
        }(),
        _MyValuesTab.primaryFocus => () {
          final c = b.value.priority.weight.compareTo(a.value.priority.weight);
          if (c != 0) return c;
          return a.value.name.toLowerCase().compareTo(
            b.value.name.toLowerCase(),
          );
        }(),
      };
    });

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TasklyHeader(title: widget.title!),
                ),
              _MyValuesTabs(
                tab: _tab,
                onChanged: (tab) {
                  setState(() {
                    _tab = tab;
                    _persistTab();
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        SliverSeparatedList(
          itemCount: values.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = values[index];
            final stats =
                widget.data.enrichment?.valueStatsByValueId[item.value.id];
            return tileBuilder.build(
              context,
              item: item,
              valueStats: stats,
              entityStyle: widget.entityStyle,
              titlePrefix: stats?.needsAttention ?? false
                  ? ValueNeedsAttentionBadge(value: item.value, stats: stats!)
                  : null,
            );
          },
        ),
      ],
    );
  }
}

class _MyValuesTabs extends StatelessWidget {
  const _MyValuesTabs({
    required this.tab,
    required this.onChanged,
  });

  final _MyValuesTab tab;
  final ValueChanged<_MyValuesTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SegmentedButton<_MyValuesTab>(
      showSelectedIcon: false,
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(
          theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      segments: const [
        ButtonSegment(
          value: _MyValuesTab.allValues,
          label: Text('All Values'),
        ),
        ButtonSegment(
          value: _MyValuesTab.mostUsed,
          label: Text('Most Used'),
        ),
        ButtonSegment(
          value: _MyValuesTab.primaryFocus,
          label: Text('Primary Focus'),
        ),
      ],
      selected: <_MyValuesTab>{tab},
      onSelectionChanged: (set) {
        final next = set.isEmpty ? null : set.first;
        if (next == null) return;
        onChanged(next);
      },
    );
  }
}
