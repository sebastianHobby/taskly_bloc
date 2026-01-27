import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/icons/taskly_symbol_icon.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

/// Inline icon picker with search-only UX.
///
/// Pure UI: data in / events out.
class TasklyFormIconSearchPicker extends StatefulWidget {
  const TasklyFormIconSearchPicker({
    required this.icons,
    required this.searchHintText,
    required this.noIconsFoundLabel,
    required this.onSelected,
    this.selectedIconName,
    this.gridHeight,
    this.crossAxisCount,
    this.tooltipBuilder,
    super.key,
  });

  final List<TasklySymbolIcon> icons;
  final String searchHintText;
  final String noIconsFoundLabel;
  final String? selectedIconName;
  final ValueChanged<String> onSelected;
  final double? gridHeight;
  final int? crossAxisCount;
  final String Function(String name)? tooltipBuilder;

  @override
  State<TasklyFormIconSearchPicker> createState() =>
      _TasklyFormIconSearchPickerState();
}

class _TasklyFormIconSearchPickerState
    extends State<TasklyFormIconSearchPicker> {
  late final TextEditingController _controller;
  String _query = '';

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

  List<TasklySymbolIcon> get _filteredIcons {
    if (_query.trim().isEmpty) return widget.icons;
    final q = _query.toLowerCase();
    return widget.icons
        .where(
          (icon) => icon.searchText.contains(q) || icon.name.toLowerCase() == q,
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final width = MediaQuery.sizeOf(context).width;

    final crossAxisCount = widget.crossAxisCount ?? (width < 480 ? 6 : 8);
    final gridHeight = widget.gridHeight ?? (width < 480 ? 220.0 : 260.0);
    final filteredIcons = _filteredIcons;

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
                        final selected = icon.name == widget.selectedIconName;
                        final tooltip = widget.tooltipBuilder?.call(icon.name);
                        final iconTile = Material(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
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
                        );

                        if (tooltip == null || tooltip.isEmpty) {
                          return iconTile;
                        }

                        return Tooltip(message: tooltip, child: iconTile);
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
