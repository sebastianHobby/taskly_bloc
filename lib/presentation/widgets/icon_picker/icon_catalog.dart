import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui_icons.dart';

/// Returns the [IconData] for a stored icon name.
IconData? getIconDataFromName(String? iconName) {
  if (iconName == null) return null;
  return tasklySymbolIconDataFromName(iconName) ??
      _legacyIconOverrides[iconName];
}

/// Formats an icon name for display in tooltips.
String formatIconLabel(String iconName) {
  return iconName
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');
}

const Map<String, IconData> _legacyIconOverrides = {
  'inbox': Icons.inbox,
  'my_day': Icons.wb_sunny,
  'today': Icons.today,
  'upcoming': Icons.event,
  'checklist': Icons.checklist,
  'task': Icons.task_alt,
  'done': Icons.done_all,
  'pending': Icons.pending_actions,
  'projects': Icons.folder,
  'folder_open': Icons.folder_open,
  'work': Icons.work,
  'business': Icons.business_center,
  'labels': Icons.label,
  'tag': Icons.local_offer,
  'category': Icons.category,
  'bookmark': Icons.bookmark,
  'values': Icons.star,
  'flag': Icons.flag,
  'target': Icons.gps_fixed,
  'trophy': Icons.emoji_events,
  'priority': Icons.priority_high,
  'rocket': Icons.rocket_launch,
  'rate_review': Icons.rate_review,
  'review': Icons.reviews,
  'refresh': Icons.refresh,
  'sync': Icons.sync,
  'loop': Icons.loop,
  'schedule': Icons.schedule,
  'calendar': Icons.calendar_month,
  'timer': Icons.timer,
  'alarm': Icons.alarm,
  'history': Icons.history,
  'hourglass': Icons.hourglass_empty,
  'mood': Icons.mood,
  'journal': Icons.book,
  'self_care': Icons.spa,
  'health': Icons.health_and_safety,
  'meditation': Icons.self_improvement,
  'list': Icons.list,
  'view_list': Icons.view_list,
  'grid': Icons.grid_view,
  'dashboard': Icons.dashboard,
  'table': Icons.table_chart,
  'kanban': Icons.view_kanban,
  'settings': Icons.settings,
  'tune': Icons.tune,
  'filter': Icons.filter_list,
  'sort': Icons.sort,
  'search': Icons.search,
  'lightbulb': Icons.lightbulb,
  'info': Icons.info,
  'home': Icons.home,
  'person': Icons.person,
  'group': Icons.group,
  'trackers': Icons.track_changes,
};
