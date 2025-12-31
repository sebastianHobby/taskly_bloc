import 'package:flutter/material.dart';

class NavigationIconResolver {
  const NavigationIconResolver();

  ({IconData icon, IconData selectedIcon}) resolve({
    required String screenId,
    required String? iconName,
  }) {
    final name = (iconName?.trim().toLowerCase()).toString();
    return _iconSetFor(name.isEmpty ? screenId.toLowerCase() : name);
  }

  ({IconData icon, IconData selectedIcon}) _iconSetFor(String key) {
    switch (key) {
      case 'inbox':
        return (icon: Icons.inbox_outlined, selectedIcon: Icons.inbox);
      case 'today':
        return (
          icon: Icons.calendar_today_outlined,
          selectedIcon: Icons.calendar_today,
        );
      case 'upcoming':
        return (icon: Icons.event_outlined, selectedIcon: Icons.event);
      case 'next_actions':
      case 'next-actions':
        return (
          icon: Icons.playlist_play_outlined,
          selectedIcon: Icons.playlist_play,
        );
      case 'projects':
        return (icon: Icons.folder_outlined, selectedIcon: Icons.folder);
      case 'labels':
        return (icon: Icons.label_outline, selectedIcon: Icons.label);
      case 'values':
        return (
          icon: Icons.favorite_border,
          selectedIcon: Icons.favorite,
        );
      case 'wellbeing':
        return (
          icon: Icons.psychology_outlined,
          selectedIcon: Icons.psychology,
        );
      case 'journal':
        return (
          icon: Icons.book_outlined,
          selectedIcon: Icons.book,
        );
      case 'trackers':
        return (
          icon: Icons.timeline_outlined,
          selectedIcon: Icons.timeline,
        );
      case 'allocation_settings':
      case 'allocation-settings':
        return (
          icon: Icons.tune_outlined,
          selectedIcon: Icons.tune,
        );
      case 'navigation_settings':
      case 'navigation-settings':
        return (
          icon: Icons.reorder_outlined,
          selectedIcon: Icons.reorder,
        );
      case 'settings':
        return (
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
        );
      case 'tasks':
        return (icon: Icons.checklist_outlined, selectedIcon: Icons.checklist);
      default:
        return (
          icon: Icons.widgets_outlined,
          selectedIcon: Icons.widgets,
        );
    }
  }
}
