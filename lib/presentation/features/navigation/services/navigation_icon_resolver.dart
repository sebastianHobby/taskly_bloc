import 'package:flutter/material.dart';

/// Resolves screen icons from screenId or iconName.
///
/// For system screens, the screenId is the single source of truth.
/// For custom screens, iconName provides user-selected icon override.
class NavigationIconResolver {
  const NavigationIconResolver();

  ({IconData icon, IconData selectedIcon}) resolve({
    required String screenId,
    required String? iconName,
  }) {
    // First try screenId (single source of truth for system screens)
    final byScreenId = _tryIconSetFor(screenId.toLowerCase());
    if (byScreenId != null) return byScreenId;

    // Fall back to iconName (for custom screens with user-selected icons)
    if (iconName != null && iconName.trim().isNotEmpty) {
      final byIconName = _tryIconSetFor(iconName.trim().toLowerCase());
      if (byIconName != null) return byIconName;
    }

    // Default icon for unknown screens
    return (icon: Icons.widgets_outlined, selectedIcon: Icons.widgets);
  }

  ({IconData icon, IconData selectedIcon})? _tryIconSetFor(String key) {
    return switch (key) {
      // ─────────────────────────────────────────────────────────────────
      // System screens (by screenKey)
      // ─────────────────────────────────────────────────────────────────
      'my_day' => (
        icon: Icons.wb_sunny_outlined,
        selectedIcon: Icons.wb_sunny,
      ),
      // Legacy screen keys (map to my_day icon)
      'today' => (
        icon: Icons.wb_sunny_outlined,
        selectedIcon: Icons.wb_sunny,
      ),
      'upcoming' => (icon: Icons.event_outlined, selectedIcon: Icons.event),
      // Planned screen (renamed from upcoming)
      'planned' => (icon: Icons.event_outlined, selectedIcon: Icons.event),
      'scheduled' => (icon: Icons.event_outlined, selectedIcon: Icons.event),
      'someday' => (
        icon: Icons.list_alt_outlined,
        selectedIcon: Icons.list_alt,
      ),
      'review_inbox' || 'review-inbox' => (
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications,
      ),
      // Legacy screen key (map to my_day icon)
      'next_actions' || 'next-actions' => (
        icon: Icons.wb_sunny_outlined,
        selectedIcon: Icons.wb_sunny,
      ),
      'projects' => (icon: Icons.folder_outlined, selectedIcon: Icons.folder),
      'labels' => (icon: Icons.label_outline, selectedIcon: Icons.label),
      'values' => (icon: Icons.star_outline, selectedIcon: Icons.star),
      'settings' => (
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
      ),
      'browse' => (
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore,
      ),

      // ─────────────────────────────────────────────────────────────────
      // Additional screens / settings pages
      // ─────────────────────────────────────────────────────────────────
      'journal' => (
        icon: Icons.book_outlined,
        selectedIcon: Icons.book,
      ),
      'trackers' => (
        icon: Icons.timeline_outlined,
        selectedIcon: Icons.timeline,
      ),
      'tasks' => (
        icon: Icons.checklist_outlined,
        selectedIcon: Icons.checklist,
      ),

      // ─────────────────────────────────────────────────────────────────
      // Common icon names (for custom screen iconName overrides)
      // ─────────────────────────────────────────────────────────────────
      'inbox' => (icon: Icons.inbox_outlined, selectedIcon: Icons.inbox),
      'folder' => (icon: Icons.folder_outlined, selectedIcon: Icons.folder),
      'label' => (icon: Icons.label_outline, selectedIcon: Icons.label),
      'star' => (icon: Icons.star_outline, selectedIcon: Icons.star),
      'bolt' => (icon: Icons.bolt_outlined, selectedIcon: Icons.bolt),
      'done_all' => (
        icon: Icons.done_all_outlined,
        selectedIcon: Icons.done_all,
      ),
      'favorite' => (
        icon: Icons.favorite_border,
        selectedIcon: Icons.favorite,
      ),
      'home' => (icon: Icons.home_outlined, selectedIcon: Icons.home),
      'work' => (icon: Icons.work_outline, selectedIcon: Icons.work),
      'flag' => (icon: Icons.flag_outlined, selectedIcon: Icons.flag),
      'bookmark' => (
        icon: Icons.bookmark_outline,
        selectedIcon: Icons.bookmark,
      ),
      'list' => (icon: Icons.list_outlined, selectedIcon: Icons.list),
      'check' => (
        icon: Icons.check_circle_outline,
        selectedIcon: Icons.check_circle,
      ),

      _ => null,
    };
  }
}
