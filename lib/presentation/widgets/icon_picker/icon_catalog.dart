import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';

/// Default icon categories used by the app.
///
/// Note: Strings here are app-owned; taskly_ui stays l10n-agnostic.
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
      IconItem(
        name: 'pending',
        label: 'Pending',
        icon: Icons.pending_actions,
      ),
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
      IconItem(
        name: 'priority',
        label: 'Priority',
        icon: Icons.priority_high,
      ),
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
      IconItem(
        name: 'calendar',
        label: 'Calendar',
        icon: Icons.calendar_month,
      ),
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
    name: 'journal',
    label: 'Journal',
    icons: [
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

/// Returns the [IconData] for a stored icon name.
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
