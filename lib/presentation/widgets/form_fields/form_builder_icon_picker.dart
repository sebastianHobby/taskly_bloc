import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

final class _RecentIconNames {
  _RecentIconNames._();

  static const _max = 12;
  static final List<String> _items = <String>[];

  static List<String> get items => List.unmodifiable(_items);

  static void remember(String iconName) {
    _items.remove(iconName);
    _items.insert(0, iconName);
    if (_items.length > _max) {
      _items.removeRange(_max, _items.length);
    }
  }
}

/// A FormBuilder field for selecting an icon from a predefined list.
///
/// Displays a compact preview that opens a dialog for icon selection.
/// Returns the icon name as a String for database storage.
class FormBuilderIconPicker extends FormBuilderFieldDecoration<String> {
  FormBuilderIconPicker({
    required super.name,
    super.key,
    super.validator,
    super.initialValue,
    super.onChanged,
    super.enabled = true,
    super.decoration = const InputDecoration(),
    this.iconSize = 32.0,
    this.title = 'Select icon',
    this.searchHintText = 'Search icons...',
    this.allCategoryLabel = 'All',
    this.noIconsFoundLabel = 'No icons found',
    this.suggestedLabel = 'Suggested',
    this.recentLabel = 'Recent',
    this.hintText = 'Tap to select an icon',
  }) : super(
         builder: (FormFieldState<String> field) {
           final state =
               field
                   as FormBuilderFieldDecorationState<
                     FormBuilderIconPicker,
                     String
                   >;
           final widget = state.widget;

           return InputDecorator(
             decoration: state.decoration,
             child: _IconPickerButton(
               selected: state.value,
               enabled: state.enabled,
               onSelected: state.didChange,
               iconSize: widget.iconSize,
               hintText: widget.hintText,
               title: widget.title,
               searchHintText: widget.searchHintText,
               allCategoryLabel: widget.allCategoryLabel,
               noIconsFoundLabel: widget.noIconsFoundLabel,
               suggestedLabel: widget.suggestedLabel,
               recentLabel: widget.recentLabel,
             ),
           );
         },
       );

  /// Size of the icon in the preview.
  final double iconSize;

  /// Dialog title.
  final String title;

  /// Hint text for the search field.
  final String searchHintText;

  /// Label for the "all" category.
  final String allCategoryLabel;

  /// Empty state label for search/category filters.
  final String noIconsFoundLabel;

  /// Section label for suggested icons.
  final String suggestedLabel;

  /// Section label for recent icons.
  final String recentLabel;

  /// Hint text shown when no icon is selected.
  final String hintText;

  @override
  FormBuilderFieldDecorationState<FormBuilderIconPicker, String>
  createState() => FormBuilderFieldDecorationState();

  /// Get an IconData from a stored icon name.
  static IconData? getIconData(String? iconName) {
    return getIconDataFromName(iconName);
  }
}

class _IconPickerButton extends StatelessWidget {
  const _IconPickerButton({
    required this.selected,
    required this.enabled,
    required this.onSelected,
    required this.iconSize,
    required this.hintText,
    required this.title,
    required this.searchHintText,
    required this.allCategoryLabel,
    required this.noIconsFoundLabel,
    required this.suggestedLabel,
    required this.recentLabel,
  });

  final String? selected;
  final bool enabled;
  final ValueChanged<String?> onSelected;
  final double iconSize;
  final String hintText;
  final String title;
  final String searchHintText;
  final String allCategoryLabel;
  final String noIconsFoundLabel;
  final String suggestedLabel;
  final String recentLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconData = selected != null ? getIconDataFromName(selected) : null;
    final tokens = TasklyTokens.of(context);

    return InkWell(
      onTap: enabled
          ? () async {
              final result = await _ValueIconPickerSheet.show(
                context,
                selectedIcon: selected,
                title: title,
                searchHintText: searchHintText,
                allCategoryLabel: allCategoryLabel,
                noIconsFoundLabel: noIconsFoundLabel,
                suggestedLabel: suggestedLabel,
                recentLabel: recentLabel,
              );
              if (result != null) {
                _RecentIconNames.remember(result);
                onSelected(result);
              }
            }
          : null,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLg,
          vertical: tokens.spaceMd,
        ),
        child: Row(
          children: [
            Container(
              width: iconSize + tokens.spaceLg,
              height: iconSize + tokens.spaceLg,
              decoration: BoxDecoration(
                color: iconData != null
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                border: iconData != null
                    ? Border.all(color: colorScheme.outlineVariant)
                    : Border.all(color: colorScheme.outlineVariant),
              ),
              child: iconData != null
                  ? Icon(
                      iconData,
                      size: iconSize,
                      color: colorScheme.onSurface,
                    )
                  : Icon(
                      Icons.add,
                      size: iconSize * 0.75,
                      color: colorScheme.onSurfaceVariant,
                    ),
            ),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: Text(
                iconData != null ? _getIconLabel(selected!) : hintText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: iconData != null
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String _getIconLabel(String iconName) {
    for (final category in defaultIconCategories) {
      for (final icon in category.icons) {
        if (icon.name == iconName) {
          return icon.label;
        }
      }
    }
    // Fallback: format the name nicely
    return iconName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}

class _ValueIconPickerSheet extends StatefulWidget {
  const _ValueIconPickerSheet({
    required this.title,
    required this.searchHintText,
    required this.allCategoryLabel,
    required this.noIconsFoundLabel,
    required this.suggestedLabel,
    required this.recentLabel,
    this.selectedIcon,
  });

  final String title;
  final String searchHintText;
  final String allCategoryLabel;
  final String noIconsFoundLabel;
  final String suggestedLabel;
  final String recentLabel;
  final String? selectedIcon;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String searchHintText,
    required String allCategoryLabel,
    required String noIconsFoundLabel,
    required String suggestedLabel,
    required String recentLabel,
    String? selectedIcon,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _ValueIconPickerSheet(
        title: title,
        searchHintText: searchHintText,
        allCategoryLabel: allCategoryLabel,
        noIconsFoundLabel: noIconsFoundLabel,
        suggestedLabel: suggestedLabel,
        recentLabel: recentLabel,
        selectedIcon: selectedIcon,
      ),
    );
  }

  @override
  State<_ValueIconPickerSheet> createState() => _ValueIconPickerSheetState();
}

class _ValueIconPickerSheetState extends State<_ValueIconPickerSheet> {
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
    for (final cat in defaultIconCategories) {
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

  List<IconItem> get _recentIcons {
    final recents = _RecentIconNames.items;
    if (recents.isEmpty) return const <IconItem>[];

    final byName = <String, IconItem>{
      for (final cat in defaultIconCategories)
        for (final icon in cat.icons) icon.name: icon,
    };

    final resolved = <IconItem>[];
    for (final name in recents) {
      final item = byName[name];
      if (item != null) resolved.add(item);
    }
    return resolved;
  }

  List<IconItem> get _suggestedIcons {
    const suggestions = <String>[
      'values',
      'target',
      'flag',
      'trophy',
      'lightbulb',
      'health',
      'home',
      'work',
      'group',
      'schedule',
      'checklist',
      'bookmark',
    ];

    final byName = <String, IconItem>{
      for (final cat in defaultIconCategories)
        for (final icon in cat.icons) icon.name: icon,
    };

    return [
      for (final name in suggestions)
        if (byName[name] != null) byName[name]!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final media = MediaQuery.of(context);
    final filteredIcons = _filteredIcons;
    final tokens = TasklyTokens.of(context);

    return SizedBox(
      height: media.size.height * 0.9,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLg,
              tokens.spaceSm,
              tokens.spaceSm,
              tokens.spaceSm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceLg,
              vertical: tokens.spaceSm,
            ),
            child: TextField(
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
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          SizedBox(height: tokens.spaceMd),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
            child: Row(
              children: [
                FilterChip(
                  label: Text(widget.allCategoryLabel),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                SizedBox(width: tokens.spaceSm),
                ...defaultIconCategories.map(
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

          SizedBox(height: tokens.spaceMd),

          Expanded(
            child: _query.trim().isEmpty && _selectedCategory == null
                ? _IconSectionsList(
                    suggestedLabel: widget.suggestedLabel,
                    suggested: _suggestedIcons,
                    recentLabel: widget.recentLabel,
                    recent: _recentIcons,
                    allLabel: widget.allCategoryLabel,
                    all: _iconsForCategory(null),
                    selectedIcon: widget.selectedIcon,
                    noIconsFoundLabel: widget.noIconsFoundLabel,
                  )
                : _IconGrid(
                    icons: filteredIcons,
                    selectedIcon: widget.selectedIcon,
                    emptyLabel: widget.noIconsFoundLabel,
                  ),
          ),
        ],
      ),
    );
  }
}

class _IconSectionsList extends StatelessWidget {
  const _IconSectionsList({
    required this.suggestedLabel,
    required this.suggested,
    required this.recentLabel,
    required this.recent,
    required this.allLabel,
    required this.all,
    required this.selectedIcon,
    required this.noIconsFoundLabel,
  });

  final String suggestedLabel;
  final List<IconItem> suggested;
  final String recentLabel;
  final List<IconItem> recent;
  final String allLabel;
  final List<IconItem> all;
  final String? selectedIcon;
  final String noIconsFoundLabel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceSm,
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceLg,
      ),
      children: [
        _IconSection(
          title: suggestedLabel,
          icons: suggested,
          selectedIcon: selectedIcon,
        ),
        if (recent.isNotEmpty) ...[
          SizedBox(height: TasklyTokens.of(context).spaceMd),
          _IconSection(
            title: recentLabel,
            icons: recent,
            selectedIcon: selectedIcon,
          ),
        ],
        SizedBox(height: TasklyTokens.of(context).spaceMd),
        _IconGrid(
          icons: all,
          selectedIcon: selectedIcon,
          emptyLabel: noIconsFoundLabel,
          title: allLabel,
          shrinkWrap: true,
        ),
      ],
    );
  }
}

class _IconSection extends StatelessWidget {
  const _IconSection({
    required this.title,
    required this.icons,
    required this.selectedIcon,
  });

  final String title;
  final List<IconItem> icons;
  final String? selectedIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    if (icons.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        _IconGrid(
          icons: icons,
          selectedIcon: selectedIcon,
          emptyLabel: '',
          shrinkWrap: true,
        ),
      ],
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({
    required this.icons,
    required this.selectedIcon,
    required this.emptyLabel,
    this.title,
    this.shrinkWrap = false,
  });

  final List<IconItem> icons;
  final String? selectedIcon;
  final String emptyLabel;
  final String? title;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final crossAxisCount = MediaQuery.sizeOf(context).width < 480 ? 6 : 8;

    if (icons.isEmpty) {
      if (emptyLabel.isEmpty) return SizedBox.shrink();
      return Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Text(
            emptyLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final grid = GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: tokens.spaceSm2,
        crossAxisSpacing: tokens.spaceSm2,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final icon = icons[index];
        final selected = icon.name == selectedIcon;
        return Tooltip(
          message: icon.label,
          child: Material(
            color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            child: InkWell(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              onTap: () => Navigator.of(context).pop(icon.name),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                  border: Border.all(
                    color: selected ? cs.primary : cs.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  icon.icon,
                  size: 22,
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (title == null) return grid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title!,
          style: theme.textTheme.labelLarge?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        SizedBox(
          height: shrinkWrap ? null : double.infinity,
          child: grid,
        ),
      ],
    );
  }
}
