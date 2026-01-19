import 'package:flutter/material.dart';

import 'package:taskly_ui/src/catalog/taskly_catalog_types.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';
import 'package:taskly_ui/src/tiles/project_entity_tile.dart';
import 'package:taskly_ui/src/tiles/task_entity_tile.dart';

sealed class TasklyAgendaRowModel {
  const TasklyAgendaRowModel({required this.key, required this.depth});

  final String key;
  final int depth;
}

final class TasklyAgendaBucketHeaderRowModel extends TasklyAgendaRowModel {
  const TasklyAgendaBucketHeaderRowModel({
    required super.key,
    required super.depth,
    required this.bucketKey,
    required this.title,
    required this.isCollapsed,
    this.action,
    this.onTap,
  });

  final String bucketKey;
  final String title;
  final bool isCollapsed;

  final TasklyAgendaBucketHeaderAction? action;
  final VoidCallback? onTap;
}

final class TasklyAgendaBucketHeaderAction {
  const TasklyAgendaBucketHeaderAction({
    required this.label,
    this.icon,
    this.tooltip,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback? onPressed;
}

final class TasklyAgendaDateHeaderRowModel extends TasklyAgendaRowModel {
  const TasklyAgendaDateHeaderRowModel({
    required super.key,
    required super.depth,
    required this.day,
    required this.title,
    this.isTodayAnchor = false,
  });

  final DateTime day;
  final String title;
  final bool isTodayAnchor;
}

final class TasklyAgendaEmptyDayRowModel extends TasklyAgendaRowModel {
  const TasklyAgendaEmptyDayRowModel({
    required super.key,
    required super.depth,
    required this.day,
    required this.label,
  });

  final DateTime day;
  final String label;
}

final class TasklyAgendaTaskRowModel extends TasklyAgendaRowModel {
  const TasklyAgendaTaskRowModel({
    required super.key,
    required super.depth,
    required this.entityId,
    required this.model,
    this.badges = const [],
    this.trailing = TrailingSpec.none,
    this.onTap,
    this.onToggleCompletion,
    this.onOverflowRequestedAt,
  });

  final String entityId;
  final TaskTileModel model;

  final List<BadgeSpec> badges;
  final TrailingSpec trailing;

  final VoidCallback? onTap;
  final ValueChanged<bool?>? onToggleCompletion;
  final ValueChanged<Offset>? onOverflowRequestedAt;
}

final class TasklyAgendaProjectRowModel extends TasklyAgendaRowModel {
  const TasklyAgendaProjectRowModel({
    required super.key,
    required super.depth,
    required this.entityId,
    required this.model,
    this.badges = const [],
    this.trailing = TrailingSpec.none,
    this.onTap,
    this.onOverflowRequestedAt,
  });

  final String entityId;
  final ProjectTileModel model;

  final List<BadgeSpec> badges;
  final TrailingSpec trailing;

  final VoidCallback? onTap;
  final ValueChanged<Offset>? onOverflowRequestedAt;
}

class TasklyAgendaSection extends StatelessWidget {
  const TasklyAgendaSection({
    required this.rows,
    this.controller,
    this.todayAnchorKey,
    super.key,
  });

  final List<TasklyAgendaRowModel> rows;
  final ScrollController? controller;

  /// When provided, applied to the first date header row that has
  /// [TasklyAgendaDateHeaderRowModel.isTodayAnchor] set.
  final Key? todayAnchorKey;

  @override
  Widget build(BuildContext context) {
    return _StickyTasklyAgendaSection(
      rows: rows,
      controller: controller,
      todayAnchorKey: todayAnchorKey,
    );
  }
}

class _StickyTasklyAgendaSection extends StatefulWidget {
  const _StickyTasklyAgendaSection({
    required this.rows,
    required this.controller,
    required this.todayAnchorKey,
  });

  final List<TasklyAgendaRowModel> rows;
  final ScrollController? controller;
  final Key? todayAnchorKey;

  @override
  State<_StickyTasklyAgendaSection> createState() =>
      _StickyTasklyAgendaSectionState();
}

class _StickyTasklyAgendaSectionState
    extends State<_StickyTasklyAgendaSection> {
  late final ScrollController _internalController;
  late ScrollController _effectiveController;
  final GlobalKey _listKey = GlobalKey();

  final Map<String, GlobalKey> _bucketHeaderKeys = <String, GlobalKey>{};
  final Map<String, GlobalKey> _dateHeaderKeys = <String, GlobalKey>{};

  _StickyHeaderState _sticky = const _StickyHeaderState.hidden();

  @override
  void initState() {
    super.initState();
    _internalController = ScrollController();
    _effectiveController = widget.controller ?? _internalController;
    _effectiveController.addListener(_onScroll);
    _reconcileHeaderKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSticky());
  }

  @override
  void didUpdateWidget(covariant _StickyTasklyAgendaSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newController = widget.controller ?? _internalController;
    if (newController != _effectiveController) {
      _effectiveController.removeListener(_onScroll);
      _effectiveController = newController;
      _effectiveController.addListener(_onScroll);
    }

    if (!identical(widget.rows, oldWidget.rows)) {
      _reconcileHeaderKeys();
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateSticky());
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onScroll);
    _internalController.dispose();
    super.dispose();
  }

  void _onScroll() => _updateSticky();

  void _reconcileHeaderKeys() {
    for (final row in widget.rows) {
      switch (row) {
        case TasklyAgendaBucketHeaderRowModel():
          _bucketHeaderKeys.putIfAbsent(row.key, GlobalKey.new);
        case TasklyAgendaDateHeaderRowModel():
          _dateHeaderKeys.putIfAbsent(row.key, GlobalKey.new);
        default:
          continue;
      }
    }
  }

  RenderBox? _renderBoxFor(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox) return null;
    if (!renderObject.hasSize) return null;
    return renderObject;
  }

  double? _yInList(GlobalKey childKey) {
    final listBox = _renderBoxFor(_listKey);
    final childBox = _renderBoxFor(childKey);
    if (listBox == null || childBox == null) return null;

    final childTopLeft = childBox.localToGlobal(Offset.zero, ancestor: listBox);
    return childTopLeft.dy;
  }

  void _updateSticky() {
    if (!mounted) return;

    final rows = widget.rows;
    if (rows.isEmpty) return;

    // The header should represent the most recent bucket/date header that has
    // scrolled past the top edge.
    String? activeBucketTitle;
    String? activeDateTitle;
    int activeHeaderIndex = -1;

    final headerIndices = <int>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      if (r is TasklyAgendaBucketHeaderRowModel ||
          r is TasklyAgendaDateHeaderRowModel) {
        headerIndices.add(i);
      }
    }

    for (final i in headerIndices) {
      final row = rows[i];
      final GlobalKey? key = switch (row) {
        TasklyAgendaBucketHeaderRowModel() => _bucketHeaderKeys[row.key],
        TasklyAgendaDateHeaderRowModel() => _dateHeaderKeys[row.key],
        _ => null,
      };
      if (key == null) continue;

      final y = _yInList(key);
      if (y == null) continue;

      // Consider a header active when it has reached the top.
      if (y <= 0) {
        activeHeaderIndex = i;
        if (row is TasklyAgendaBucketHeaderRowModel) {
          activeBucketTitle = row.title;
          activeDateTitle = null;
        } else if (row is TasklyAgendaDateHeaderRowModel) {
          activeDateTitle = row.title;

          // Depth 0 date headers are not nested under a bucket; clear the
          // active bucket so we don't keep showing the previous section.
          if (row.depth == 0) {
            activeBucketTitle = null;
          }
        }
      }
    }

    // If we haven't scrolled past any header yet, don't render a sticky header.
    if (activeHeaderIndex < 0 ||
        (activeBucketTitle == null && activeDateTitle == null)) {
      const next = _StickyHeaderState.hidden();
      if (next != _sticky) setState(() => _sticky = next);
      return;
    }

    // Push-off effect: slide the sticky header up when the next header is
    // about to overlap it.
    const headerPadding = EdgeInsets.fromLTRB(16, 12, 16, 10);
    final theme = Theme.of(context);
    final bucketStyle = theme.textTheme.titleMedium;
    final dateStyle = theme.textTheme.labelLarge;
    final lineHeight =
        (bucketStyle?.fontSize ?? 18) * (bucketStyle?.height ?? 1.2);
    final dateLineHeight =
        (dateStyle?.fontSize ?? 14) * (dateStyle?.height ?? 1.2);
    final headerHeight =
        headerPadding.vertical +
        (activeBucketTitle == null ? 0 : lineHeight) +
        (activeDateTitle == null
            ? 0
            : ((activeBucketTitle == null ? 0 : 4) + dateLineHeight));

    double yOffset = 0;
    int? nextHeaderIndex;
    if (activeHeaderIndex >= 0) {
      for (final i in headerIndices) {
        if (i <= activeHeaderIndex) continue;
        nextHeaderIndex = i;
        break;
      }
    }

    if (nextHeaderIndex != null) {
      final nextRow = rows[nextHeaderIndex];
      final GlobalKey? key = switch (nextRow) {
        TasklyAgendaBucketHeaderRowModel() => _bucketHeaderKeys[nextRow.key],
        TasklyAgendaDateHeaderRowModel() => _dateHeaderKeys[nextRow.key],
        _ => null,
      };
      if (key != null) {
        final nextY = _yInList(key);
        if (nextY != null) {
          yOffset = (nextY - headerHeight).clamp(-headerHeight, 0);
        }
      }
    }

    final next = _StickyHeaderState(
      bucketTitle: activeBucketTitle,
      dateTitle: activeDateTitle,
      yOffset: yOffset,
    );

    if (next != _sticky) {
      setState(() => _sticky = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;

    return Stack(
      children: [
        ListView.builder(
          key: _listKey,
          controller: _effectiveController,
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            final leftIndent = 12.0 * row.depth;

            Widget child = switch (row) {
              TasklyAgendaBucketHeaderRowModel() => KeyedSubtree(
                key: _bucketHeaderKeys[row.key],
                child: _BucketHeaderRow(row: row),
              ),
              TasklyAgendaDateHeaderRowModel() => KeyedSubtree(
                key: _dateHeaderKeys[row.key],
                child: _DateHeaderRow(row: row),
              ),
              TasklyAgendaEmptyDayRowModel() => _EmptyDayRow(row: row),
              TasklyAgendaTaskRowModel() => TaskEntityTile(
                model: row.model,
                badges: row.badges,
                trailing: row.trailing,
                onTap: row.onTap,
                onToggleCompletion: row.onToggleCompletion,
                onOverflowRequestedAt: row.onOverflowRequestedAt,
              ),
              TasklyAgendaProjectRowModel() => ProjectEntityTile(
                model: row.model,
                badges: row.badges,
                trailing: row.trailing,
                onTap: row.onTap,
                onOverflowRequestedAt: row.onOverflowRequestedAt,
              ),
            };

            if (leftIndent > 0) {
              child = Padding(
                padding: EdgeInsets.only(left: leftIndent),
                child: child,
              );
            }

            if (widget.todayAnchorKey == null) {
              return KeyedSubtree(key: ValueKey(row.key), child: child);
            }

            if (row is TasklyAgendaDateHeaderRowModel && row.isTodayAnchor) {
              return KeyedSubtree(
                key: ValueKey(row.key),
                child: KeyedSubtree(
                  key: widget.todayAnchorKey,
                  child: child,
                ),
              );
            }

            return KeyedSubtree(key: ValueKey(row.key), child: child);
          },
        ),
        if (!_sticky.hidden)
          Positioned(
            left: 0,
            right: 0,
            top: _sticky.yOffset,
            child: _StickyAgendaHeader(
              bucketTitle: _sticky.bucketTitle,
              dateTitle: _sticky.dateTitle,
            ),
          ),
      ],
    );
  }
}

class _StickyHeaderState {
  const _StickyHeaderState({
    required this.bucketTitle,
    required this.dateTitle,
    required this.yOffset,
  });

  const _StickyHeaderState.hidden()
    : bucketTitle = null,
      dateTitle = null,
      yOffset = 0;

  final String? bucketTitle;
  final String? dateTitle;
  final double yOffset;

  bool get hidden => bucketTitle == null && dateTitle == null;

  @override
  bool operator ==(Object other) {
    return other is _StickyHeaderState &&
        other.bucketTitle == bucketTitle &&
        other.dateTitle == dateTitle &&
        (other.yOffset - yOffset).abs() < 0.5;
  }

  @override
  int get hashCode => Object.hash(bucketTitle, dateTitle, yOffset.round());
}

class _StickyAgendaHeader extends StatelessWidget {
  const _StickyAgendaHeader({
    required this.bucketTitle,
    required this.dateTitle,
  });

  final String? bucketTitle;
  final String? dateTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bucketTitle != null)
              Text(bucketTitle!, style: theme.textTheme.titleMedium),
            if (dateTitle != null) ...[
              if (bucketTitle != null) const SizedBox(height: 4),
              Text(
                dateTitle!,
                style:
                    (bucketTitle == null
                            ? theme.textTheme.titleMedium
                            : theme.textTheme.labelLarge)
                        ?.copyWith(
                          color: bucketTitle == null
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BucketHeaderRow extends StatelessWidget {
  const _BucketHeaderRow({required this.row});

  final TasklyAgendaBucketHeaderRowModel row;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: row.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                row.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (row.action != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: row.action!.onPressed,
                icon: row.action!.icon != null
                    ? Icon(row.action!.icon, size: 18)
                    : const SizedBox.shrink(),
                label: Text(row.action!.label),
              ),
            ],
            Icon(
              row.isCollapsed ? Icons.chevron_right : Icons.expand_more,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateHeaderRow extends StatelessWidget {
  const _DateHeaderRow({required this.row});

  final TasklyAgendaDateHeaderRowModel row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        row.title,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _EmptyDayRow extends StatelessWidget {
  const _EmptyDayRow({required this.row});

  final TasklyAgendaEmptyDayRowModel row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        row.label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
