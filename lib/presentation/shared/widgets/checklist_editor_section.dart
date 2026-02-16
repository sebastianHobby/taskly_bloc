import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class ChecklistEditorSection extends StatefulWidget {
  const ChecklistEditorSection({
    required this.titles,
    required this.onChanged,
    required this.title,
    required this.addItemFieldLabel,
    required this.addItemButtonLabel,
    required this.deleteItemTooltip,
    this.maxItems = 20,
    super.key,
  });

  final List<String> titles;
  final ValueChanged<List<String>> onChanged;
  final String title;
  final String addItemFieldLabel;
  final String addItemButtonLabel;
  final String deleteItemTooltip;
  final int maxItems;

  @override
  State<ChecklistEditorSection> createState() => _ChecklistEditorSectionState();
}

class _ChecklistEditorSectionState extends State<ChecklistEditorSection> {
  final TextEditingController _addController = TextEditingController();
  final FocusNode _addFocusNode = FocusNode();
  final List<_ChecklistDraftItem> _items = <_ChecklistDraftItem>[];
  int _nextDraftId = 0;

  @override
  void initState() {
    super.initState();
    _setItemsFromTitles(widget.titles);
  }

  @override
  void didUpdateWidget(covariant ChecklistEditorSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameTitles(_currentTitles(), widget.titles)) return;
    _setItemsFromTitles(widget.titles);
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  void _setItemsFromTitles(List<String> titles) {
    for (final item in _items) {
      item.dispose();
    }
    _items
      ..clear()
      ..addAll(
        titles.take(widget.maxItems).map((title) {
          final draft = _ChecklistDraftItem(
            id: 'draft-${_nextDraftId++}',
            initialTitle: title,
          );
          draft.controller.addListener(_emitFromDrafts);
          return draft;
        }),
      );
  }

  List<String> _currentTitles() => _items
      .map((item) => item.controller.text.trim())
      .where((title) => title.isNotEmpty)
      .take(widget.maxItems)
      .toList(growable: false);

  bool _sameTitles(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _emit(List<String> next) {
    widget.onChanged(next);
  }

  void _emitFromDrafts() {
    final next = _currentTitles();
    if (_sameTitles(next, widget.titles)) return;
    _emit(next);
  }

  void _addItem() {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    if (_items.length >= widget.maxItems) return;
    _addController.clear();
    setState(() {
      final draft = _ChecklistDraftItem(
        id: 'draft-${_nextDraftId++}',
        initialTitle: text,
      );
      draft.controller.addListener(_emitFromDrafts);
      _items.add(draft);
    });
    _emitFromDrafts();
    _addFocusNode.requestFocus();
  }

  bool _isPlainEnter(KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;
    final isEnter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter) return false;
    if (keyboard.isShiftPressed || keyboard.isControlPressed) return false;
    if (keyboard.isAltPressed || keyboard.isMetaPressed) return false;
    return true;
  }

  void _deleteAt(int index) {
    if (index < 0 || index >= _items.length) return;
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
    _emitFromDrafts();
  }

  void _reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _items.length) return;
    var adjustedNewIndex = newIndex;
    if (adjustedNewIndex > oldIndex) {
      adjustedNewIndex -= 1;
    }
    if (adjustedNewIndex < 0 || adjustedNewIndex > _items.length) return;
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(adjustedNewIndex, item);
    });
    _emitFromDrafts();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final canAddMore = _items.length < widget.maxItems;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${_items.length}/${widget.maxItems}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            SizedBox(height: tokens.spaceSm),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _items.length,
              onReorder: _reorder,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  key: ValueKey(item.id),
                  contentPadding: EdgeInsets.zero,
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_indicator),
                  ),
                  title: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent && _isPlainEnter(event)) {
                        FocusScope.of(context).nextFocus();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextFormField(
                      controller: item.controller,
                      focusNode: item.focusNode,
                      minLines: 1,
                      maxLines: null,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).nextFocus();
                      },
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      onEditingComplete: () {},
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: widget.deleteItemTooltip,
                    onPressed: () => _deleteAt(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
                );
              },
            ),
            SizedBox(height: tokens.spaceSm),
            Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent && _isPlainEnter(event)) {
                  if (canAddMore) {
                    _addItem();
                  }
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addController,
                      focusNode: _addFocusNode,
                      maxLines: 1,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: widget.addItemFieldLabel,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  SizedBox(width: tokens.spaceXs),
                  FilledButton(
                    onPressed: canAddMore ? _addItem : null,
                    child: Text(widget.addItemButtonLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ChecklistDraftItem {
  _ChecklistDraftItem({
    required this.id,
    required String initialTitle,
  }) : controller = TextEditingController(text: initialTitle),
       focusNode = FocusNode();

  final String id;
  final TextEditingController controller;
  final FocusNode focusNode;

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}
