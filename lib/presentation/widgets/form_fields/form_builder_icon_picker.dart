import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';

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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: iconSize + 16,
              height: iconSize + 16,
              decoration: BoxDecoration(
                color: iconData != null
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
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
            const SizedBox(width: 12),
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

    return SizedBox(
      height: media.size.height * 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: Text(widget.allCategoryLabel),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ...defaultIconCategories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
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

          const SizedBox(height: 10),

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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        _IconSection(
          title: suggestedLabel,
          icons: suggested,
          selectedIcon: selectedIcon,
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 16),
          _IconSection(
            title: recentLabel,
            icons: recent,
            selectedIcon: selectedIcon,
          ),
        ],
        const SizedBox(height: 16),
        _IconGrid(
          icons: all,
          selectedIcon: selectedIcon,
          emptyLabel: noIconsFoundLabel,
          title: allLabel,
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

    if (icons.isEmpty) return const SizedBox.shrink();

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
        const SizedBox(height: 10),
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
    final crossAxisCount = MediaQuery.sizeOf(context).width < 480 ? 6 : 8;

    if (icons.isEmpty) {
      if (emptyLabel.isEmpty) return const SizedBox.shrink();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final icon = icons[index];
        final selected = icon.name == selectedIcon;
        return Tooltip(
          message: icon.label,
          child: Material(
            color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(icon.name),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
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
        const SizedBox(height: 10),
        SizedBox(
          height: shrinkWrap ? null : double.infinity,
          child: grid,
        ),
      ],
    );
  }
}
