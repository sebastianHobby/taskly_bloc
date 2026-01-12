import 'package:flutter/material.dart';

/// A dialog for selecting an icon with search and category filtering.
///
/// Provides a better UX than a simple grid by:
/// - Grouping icons by category
/// - Providing search functionality
/// - Showing a compact preview with tap-to-select behavior
class IconPickerDialog extends StatefulWidget {
  const IconPickerDialog({
    required this.icons,
    this.selectedIcon,
    this.title = 'Select Icon',
    super.key,
  });

  final List<IconCategory> icons;
  final String? selectedIcon;
  final String title;

  /// Shows the icon picker dialog and returns the selected icon name.
  static Future<String?> show(
    BuildContext context, {
    String? selectedIcon,
    List<IconCategory>? categories,
    String title = 'Select Icon',
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => IconPickerDialog(
        icons: categories ?? defaultIconCategories,
        selectedIcon: selectedIcon,
        title: title,
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
              padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search icons...',
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

            const SizedBox(height: 8),

            // Category chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  ...widget.icons.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
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

            const SizedBox(height: 8),
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
                          const SizedBox(height: 8),
                          Text(
                            'No icons found',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
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
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(icon.name),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
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

/// Default icon categories for the picker.
const List<IconCategory> defaultIconCategories = [
  IconCategory(
    name: 'tasks',
    label: 'Tasks',
    icons: [
      IconItem(name: 'inbox', label: 'Inbox', icon: Icons.inbox),
      IconItem(name: 'my_day', label: 'My Day', icon: Icons.wb_sunny),
      IconItem(name: 'today', label: 'Today', icon: Icons.today),
      IconItem(name: 'upcoming', label: 'Upcoming', icon: Icons.event),
      IconItem(
        name: 'next_actions',
        label: 'Next Actions',
        icon: Icons.playlist_play,
      ),
      IconItem(name: 'checklist', label: 'Checklist', icon: Icons.checklist),
      IconItem(name: 'task', label: 'Task', icon: Icons.task_alt),
      IconItem(name: 'done', label: 'Done', icon: Icons.done_all),
      IconItem(name: 'pending', label: 'Pending', icon: Icons.pending_actions),
    ],
  ),
  IconCategory(
    name: 'organization',
    label: 'Organization',
    icons: [
      IconItem(name: 'projects', label: 'Projects', icon: Icons.folder),
      IconItem(
        name: 'folder_open',
        label: 'Folder Open',
        icon: Icons.folder_open,
      ),
      IconItem(name: 'work', label: 'Work', icon: Icons.work),
      IconItem(
        name: 'business',
        label: 'Business',
        icon: Icons.business_center,
      ),
      IconItem(name: 'labels', label: 'Labels', icon: Icons.label),
      IconItem(name: 'tag', label: 'Tag', icon: Icons.local_offer),
      IconItem(name: 'category', label: 'Category', icon: Icons.category),
      IconItem(name: 'bookmark', label: 'Bookmark', icon: Icons.bookmark),
    ],
  ),
  IconCategory(
    name: 'goals',
    label: 'Goals & Values',
    icons: [
      IconItem(name: 'values', label: 'Values', icon: Icons.star),
      IconItem(name: 'flag', label: 'Flag', icon: Icons.flag),
      IconItem(name: 'target', label: 'Target', icon: Icons.gps_fixed),
      IconItem(name: 'trophy', label: 'Trophy', icon: Icons.emoji_events),
      IconItem(name: 'priority', label: 'Priority', icon: Icons.priority_high),
      IconItem(name: 'rocket', label: 'Rocket', icon: Icons.rocket_launch),
    ],
  ),
  IconCategory(
    name: 'review',
    label: 'Review',
    icons: [
      IconItem(name: 'rate_review', label: 'Review', icon: Icons.rate_review),
      IconItem(name: 'review', label: 'Reviews', icon: Icons.reviews),
      IconItem(name: 'refresh', label: 'Refresh', icon: Icons.refresh),
      IconItem(name: 'sync', label: 'Sync', icon: Icons.sync),
      IconItem(name: 'loop', label: 'Loop', icon: Icons.loop),
    ],
  ),
  IconCategory(
    name: 'time',
    label: 'Time & Schedule',
    icons: [
      IconItem(name: 'schedule', label: 'Schedule', icon: Icons.schedule),
      IconItem(name: 'calendar', label: 'Calendar', icon: Icons.calendar_month),
      IconItem(name: 'timer', label: 'Timer', icon: Icons.timer),
      IconItem(name: 'alarm', label: 'Alarm', icon: Icons.alarm),
      IconItem(name: 'history', label: 'History', icon: Icons.history),
      IconItem(
        name: 'hourglass',
        label: 'Hourglass',
        icon: Icons.hourglass_empty,
      ),
    ],
  ),
  IconCategory(
    name: 'wellbeing',
    label: 'Wellbeing',
    icons: [
      IconItem(name: 'wellbeing', label: 'Wellbeing', icon: Icons.favorite),
      IconItem(name: 'mood', label: 'Mood', icon: Icons.mood),
      IconItem(name: 'journal', label: 'Journal', icon: Icons.book),
      IconItem(name: 'self_care', label: 'Self Care', icon: Icons.spa),
      IconItem(name: 'health', label: 'Health', icon: Icons.health_and_safety),
      IconItem(
        name: 'meditation',
        label: 'Meditation',
        icon: Icons.self_improvement,
      ),
    ],
  ),
  IconCategory(
    name: 'views',
    label: 'Views & Layout',
    icons: [
      IconItem(name: 'list', label: 'List', icon: Icons.list),
      IconItem(name: 'view_list', label: 'View List', icon: Icons.view_list),
      IconItem(name: 'grid', label: 'Grid', icon: Icons.grid_view),
      IconItem(name: 'dashboard', label: 'Dashboard', icon: Icons.dashboard),
      IconItem(name: 'table', label: 'Table', icon: Icons.table_chart),
      IconItem(name: 'kanban', label: 'Kanban', icon: Icons.view_kanban),
    ],
  ),
  IconCategory(
    name: 'misc',
    label: 'Miscellaneous',
    icons: [
      IconItem(name: 'settings', label: 'Settings', icon: Icons.settings),
      IconItem(name: 'tune', label: 'Tune', icon: Icons.tune),
      IconItem(name: 'filter', label: 'Filter', icon: Icons.filter_list),
      IconItem(name: 'sort', label: 'Sort', icon: Icons.sort),
      IconItem(name: 'search', label: 'Search', icon: Icons.search),
      IconItem(name: 'lightbulb', label: 'Lightbulb', icon: Icons.lightbulb),
      IconItem(name: 'info', label: 'Info', icon: Icons.info),
      IconItem(name: 'home', label: 'Home', icon: Icons.home),
      IconItem(name: 'person', label: 'Person', icon: Icons.person),
      IconItem(name: 'group', label: 'Group', icon: Icons.group),
      IconItem(name: 'trackers', label: 'Trackers', icon: Icons.track_changes),
    ],
  ),
];

/// Get an IconData from a stored icon name.
IconData? getIconDataFromName(String? iconName) {
  if (iconName == null) return null;
  for (final category in defaultIconCategories) {
    for (final icon in category.icons) {
      if (icon.name == iconName) {
        return icon.icon;
      }
    }
  }
  return null;
}
