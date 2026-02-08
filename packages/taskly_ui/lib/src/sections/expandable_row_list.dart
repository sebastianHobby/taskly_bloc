import 'package:flutter/material.dart';
import 'package:taskly_ui/src/feed/taskly_feed_renderer.dart';
import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class ExpandableRowListDefaults {
  static const int compactMaxVisible = 4;
}

class ExpandableRowList extends StatefulWidget {
  const ExpandableRowList({
    required this.rows,
    required this.rowKeyPrefix,
    required this.showMoreLabelBuilder,
    this.showFewerLabel,
    this.entityRowPadding,
    this.maxVisible = ExpandableRowListDefaults.compactMaxVisible,
    this.enabled = true,
    this.allowCollapse = true,
    super.key,
  });

  final List<TasklyRowSpec> rows;
  final String rowKeyPrefix;
  final int maxVisible;
  final bool enabled;
  final bool allowCollapse;
  final String Function(int remaining, int total) showMoreLabelBuilder;
  final String? showFewerLabel;
  final EdgeInsetsGeometry? entityRowPadding;

  @override
  State<ExpandableRowList> createState() => _ExpandableRowListState();
}

class _ExpandableRowListState extends State<ExpandableRowList> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant ExpandableRowList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_shouldLimitRows()) {
      if (_expanded) {
        _expanded = false;
      }
      return;
    }

    if (_expanded && widget.rows.length <= widget.maxVisible) {
      _expanded = false;
    }
  }

  bool _shouldLimitRows() {
    return widget.enabled && widget.rows.length > widget.maxVisible;
  }

  List<TasklyRowSpec> _buildRows() {
    if (!_shouldLimitRows()) return widget.rows;

    final total = widget.rows.length;
    final remaining = total - widget.maxVisible;
    if (!_expanded) {
      return [
        ...widget.rows.take(widget.maxVisible),
        TasklyRowSpec.inlineAction(
          key: '${widget.rowKeyPrefix}-show-more',
          label: widget.showMoreLabelBuilder(remaining, total),
          onTap: () => setState(() => _expanded = true),
        ),
      ];
    }

    if (!widget.allowCollapse) {
      return widget.rows;
    }

    return [
      ...widget.rows,
      TasklyRowSpec.inlineAction(
        key: '${widget.rowKeyPrefix}-show-fewer',
        label: widget.showFewerLabel!,
        onTap: () => setState(() => _expanded = false),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    assert(
      !widget.allowCollapse || widget.showFewerLabel != null,
      'showFewerLabel is required when allowCollapse is true.',
    );

    return AnimatedRowList(
      rows: _buildRows(),
      entityRowPadding: widget.entityRowPadding,
    );
  }
}

class AnimatedRowList extends StatefulWidget {
  const AnimatedRowList({
    required this.rows,
    this.entityRowPadding,
    super.key,
  });

  final List<TasklyRowSpec> rows;
  final EdgeInsetsGeometry? entityRowPadding;

  @override
  State<AnimatedRowList> createState() => _AnimatedRowListState();
}

class _AnimatedRowListState extends State<AnimatedRowList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<TasklyRowSpec> _rows;

  @override
  void initState() {
    super.initState();
    _rows = List<TasklyRowSpec>.from(widget.rows);
  }

  @override
  void didUpdateWidget(covariant AnimatedRowList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRows(widget.rows);
  }

  void _syncRows(List<TasklyRowSpec> nextRows) {
    final oldKeys = _rows.map(_rowKey).toList(growable: false);
    final newKeys = nextRows.map(_rowKey).toList(growable: false);

    for (var i = oldKeys.length - 1; i >= 0; i -= 1) {
      if (newKeys.contains(oldKeys[i])) continue;
      final removed = _rows.removeAt(i);
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => _buildAnimatedRow(
          context,
          removed,
          animation,
        ),
        duration: const Duration(milliseconds: 200),
      );
    }

    for (var i = 0; i < newKeys.length; i += 1) {
      if (oldKeys.contains(newKeys[i])) continue;
      _rows.insert(i, nextRows[i]);
      _listKey.currentState?.insertItem(
        i,
        duration: const Duration(milliseconds: 200),
      );
    }

    _rows = List<TasklyRowSpec>.from(nextRows);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: _rows.length,
      itemBuilder: (context, index, animation) => _buildAnimatedRow(
        context,
        _rows[index],
        animation,
      ),
    );
  }

  Widget _buildAnimatedRow(
    BuildContext context,
    TasklyRowSpec row,
    Animation<double> animation,
  ) {
    final tokens = TasklyTokens.of(context);
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    final size = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

    final child = TasklyFeedRenderer.buildRow(
      row,
      context: context,
      entityRowPadding: widget.entityRowPadding,
    );
    final isLast = _rows.isNotEmpty && identical(row, _rows.last);
    final padded = Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : tokens.feedEntityRowSpacing,
      ),
      child: child,
    );

    return SizeTransition(
      sizeFactor: size,
      child: FadeTransition(
        opacity: fade,
        child: padded,
      ),
    );
  }

  String _rowKey(TasklyRowSpec row) {
    return switch (row) {
      TasklyHeaderRowSpec(:final key) => key,
      TasklySubheaderRowSpec(:final key) => key,
      TasklyDividerRowSpec(:final key) => key,
      TasklyInlineActionRowSpec(:final key) => key,
      TasklyTaskRowSpec(:final key) => key,
      TasklyProjectRowSpec(:final key) => key,
      TasklyValueRowSpec(:final key) => key,
      TasklyRoutineRowSpec(:final key) => key,
    };
  }
}
