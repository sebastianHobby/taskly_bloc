import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

/// A dialog for selecting an icon with search and category filtering.
///
/// Provides a better UX than a simple grid by:
/// - Grouping icons by category
/// - Providing search functionality
/// - Showing a compact preview with tap-to-select behavior
class IconPickerDialog extends StatefulWidget {
  const IconPickerDialog({
    required this.icons,
    required this.title,
    required this.searchHintText,
    required this.allCategoryLabel,
    required this.noIconsFoundLabel,
    this.selectedIcon,
    super.key,
  });

  final List<IconCategory> icons;
  final String? selectedIcon;
  final String title;

  /// Hint text for the search field.
  final String searchHintText;

  /// Label for the "all categories" chip.
  final String allCategoryLabel;

  /// Text shown when no icons match the filters.
  final String noIconsFoundLabel;

  /// Shows the icon picker dialog and returns the selected icon name.
  static Future<String?> show(
    BuildContext context, {
    required List<IconCategory> categories,
    required String title,
    required String searchHintText,
    required String allCategoryLabel,
    required String noIconsFoundLabel,
    String? selectedIcon,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => IconPickerDialog(
        icons: categories,
        selectedIcon: selectedIcon,
        title: title,
        searchHintText: searchHintText,
        allCategoryLabel: allCategoryLabel,
        noIconsFoundLabel: noIconsFoundLabel,
      ),
    );
  }

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<IconItem> get _filteredIcons {
    var icons = <IconItem>[];

    for (final category in widget.icons) {
      if (_selectedCategory == null || _selectedCategory == category.name) {
        icons.addAll(category.icons);
      }
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      icons = icons.where((icon) {
        return icon.name.toLowerCase().contains(query) ||
            icon.label.toLowerCase().contains(query);
      }).toList();
    }

    return icons;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final filteredIcons = _filteredIcons;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: widget.searchHintText,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            SizedBox(height: tokens.spaceSm),

            // Category chips
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
                  ...widget.icons.map(
                    (category) => Padding(
                      padding: EdgeInsets.only(right: tokens.spaceSm),
                      child: FilterChip(
                        label: Text(category.label),
                        selected: _selectedCategory == category.name,
                        onSelected: (_) => setState(
                          () => _selectedCategory =
                              _selectedCategory == category.name
                              ? null
                              : category.name,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: tokens.spaceSm),
            const Divider(height: 1),

            // Icon grid
            Expanded(
              child: filteredIcons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(height: tokens.spaceSm),
                          Text(
                            widget.noIconsFoundLabel,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(tokens.spaceLg),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemCount: filteredIcons.length,
                      itemBuilder: (context, index) {
                        final icon = filteredIcons[index];
                        final isSelected = widget.selectedIcon == icon.name;

                        return Tooltip(
                          message: icon.label,
                          child: Material(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(
                              tokens.radiusSm,
                            ),
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(icon.name),
                              borderRadius: BorderRadius.circular(
                                tokens.radiusSm,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    tokens.radiusSm,
                                  ),
                                  border: isSelected
                                      ? Border.all(
                                          color: colorScheme.primary,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Icon(
                                  icon.icon,
                                  size: 24,
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A category of icons.
class IconCategory {
  const IconCategory({
    required this.name,
    required this.label,
    required this.icons,
  });

  final String name;
  final String label;
  final List<IconItem> icons;
}

/// An icon item with name, label, and IconData.
class IconItem {
  const IconItem({
    required this.name,
    required this.label,
    required this.icon,
  });

  final String name;
  final String label;
  final IconData icon;
}
