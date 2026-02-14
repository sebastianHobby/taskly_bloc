import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class ChecklistEditorSection extends StatefulWidget {
  const ChecklistEditorSection({
    required this.titles,
    required this.onChanged,
    this.title = 'Checklist',
    this.maxItems = 20,
    super.key,
  });

  final List<String> titles;
  final ValueChanged<List<String>> onChanged;
  final String title;
  final int maxItems;

  @override
  State<ChecklistEditorSection> createState() => _ChecklistEditorSectionState();
}

class _ChecklistEditorSectionState extends State<ChecklistEditorSection> {
  final TextEditingController _addController = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _emit(List<String> next) {
    widget.onChanged(
      next
          .map((title) => title.trim())
          .where((title) => title.isNotEmpty)
          .take(widget.maxItems)
          .toList(growable: false),
    );
  }

  void _addItem() {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    if (widget.titles.length >= widget.maxItems) return;
    _addController.clear();
    _emit([...widget.titles, text]);
  }

  void _deleteAt(int index) {
    if (index < 0 || index >= widget.titles.length) return;
    final next = [...widget.titles]..removeAt(index);
    _emit(next);
  }

  void _updateAt(int index, String value) {
    if (index < 0 || index >= widget.titles.length) return;
    final next = [...widget.titles];
    next[index] = value;
    _emit(next);
  }

  void _reorder(int oldIndex, int newIndex) {
    final next = [...widget.titles];
    if (oldIndex < 0 || oldIndex >= next.length) return;
    var adjustedNewIndex = newIndex;
    if (adjustedNewIndex > oldIndex) {
      adjustedNewIndex -= 1;
    }
    if (adjustedNewIndex < 0 || adjustedNewIndex > next.length) return;
    final item = next.removeAt(oldIndex);
    next.insert(adjustedNewIndex, item);
    _emit(next);
  }

  String _previewText() {
    if (widget.titles.isEmpty) return '0 items';
    if (widget.titles.length == 1) return widget.titles.first;
    if (widget.titles.length == 2) {
      return '${widget.titles[0]}, ${widget.titles[1]}';
    }
    return '${widget.titles[0]}, ${widget.titles[1]} +${widget.titles.length - 2} more';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final canAddMore = widget.titles.length < widget.maxItems;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '${widget.titles.length}/${widget.maxItems}',
                    style: theme.textTheme.bodySmall,
                  ),
                  SizedBox(width: tokens.spaceXs),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            if (!_expanded) ...[
              SizedBox(height: tokens.spaceXs),
              Text(
                _previewText(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (_expanded) ...[
              SizedBox(height: tokens.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addController,
                      maxLines: null,
                      minLines: 1,
                      decoration: const InputDecoration(
                        labelText: 'Add item',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  SizedBox(width: tokens.spaceXs),
                  FilledButton(
                    onPressed: canAddMore ? _addItem : null,
                    child: const Text('Add'),
                  ),
                ],
              ),
              SizedBox(height: tokens.spaceSm),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: widget.titles.length,
                onReorder: _reorder,
                itemBuilder: (context, index) {
                  final item = widget.titles[index];
                  return ListTile(
                    key: ValueKey('check-item-$index-$item'),
                    contentPadding: EdgeInsets.zero,
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_indicator),
                    ),
                    title: TextFormField(
                      key: ValueKey('check-item-input-$index-$item'),
                      initialValue: item,
                      minLines: 1,
                      maxLines: null,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _updateAt(index, value),
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete item',
                      onPressed: () => _deleteAt(index),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
