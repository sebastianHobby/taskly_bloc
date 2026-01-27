import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/sections/icon_picker_dialog.dart';

/// Inline icon picker with search and category filtering.
///
/// Pure UI: data in / events out.
class TasklyFormIconGridPicker extends StatefulWidget {
  const TasklyFormIconGridPicker({
    required this.categories,
    required this.searchHintText,
    required this.allCategoryLabel,
    required this.noIconsFoundLabel,
    required this.onSelected,
    this.selectedIcon,
    this.gridHeight,
    this.crossAxisCount,
    super.key,
  });

  final List<IconCategory> categories;
  final String searchHintText;
  final String allCategoryLabel;
  final String noIconsFoundLabel;
  final String? selectedIcon;
  final ValueChanged<String> onSelected;
  final double? gridHeight;
  final int? crossAxisCount;

  @override
  State<TasklyFormIconGridPicker> createState() =>
      _TasklyFormIconGridPickerState();
}

class _TasklyFormIconGridPickerState extends State<TasklyFormIconGridPicker> {
  late final TextEditingController _controller;
  String _query = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<IconItem> _iconsForCategory(String? category) {
    final icons = <IconItem>[];
    for (final cat in widget.categories) {
      if (category == null || cat.name == category) {
        icons.addAll(cat.icons);
      }
    }
    return icons;
  }

  List<IconItem> get _filteredIcons {
    final icons = _iconsForCategory(_selectedCategory);
    if (_query.trim().isEmpty) return icons;
    final q = _query.toLowerCase();
    return icons
        .where(
          (i) =>
              i.name.toLowerCase().contains(q) ||
              i.label.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final filteredIcons = _filteredIcons;
    final width = MediaQuery.sizeOf(context).width;

    final crossAxisCount = widget.crossAxisCount ?? (width < 480 ? 6 : 8);
    final gridHeight = widget.gridHeight ?? (width < 480 ? 200.0 : 240.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.searchHintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
            filled: true,
            fillColor: cs.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              borderSide: BorderSide(color: cs.primary, width: 1.2),
            ),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        SizedBox(height: tokens.spaceSm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceXs2),
          child: Row(
            children: [
              FilterChip(
                label: Text(widget.allCategoryLabel),
                selected: _selectedCategory == null,
                onSelected: (_) => setState(() => _selectedCategory = null),
              ),
              SizedBox(width: tokens.spaceSm),
              ...widget.categories.map(
                (cat) => Padding(
                  padding: EdgeInsets.only(right: tokens.spaceSm),
                  child: FilterChip(
                    label: Text(cat.label),
                    selected: _selectedCategory == cat.name,
                    onSelected: (_) => setState(
                      () => _selectedCategory = _selectedCategory == cat.name
                          ? null
                          : cat.name,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceSm),
            child: SizedBox(
              height: gridHeight,
              child: filteredIcons.isEmpty
                  ? Center(
                      child: Text(
                        widget.noIconsFoundLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: tokens.spaceSm2,
                        crossAxisSpacing: tokens.spaceSm2,
                      ),
                      itemCount: filteredIcons.length,
                      itemBuilder: (context, index) {
                        final icon = filteredIcons[index];
                        final selected = icon.name == widget.selectedIcon;
                        return Tooltip(
                          message: icon.label,
                          child: Material(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(
                              tokens.radiusMd,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                tokens.radiusMd,
                              ),
                              onTap: () => widget.onSelected(icon.name),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    tokens.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: selected
                                        ? cs.primary
                                        : cs.outlineVariant,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Icon(
                                  icon.icon,
                                  size: 22,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
