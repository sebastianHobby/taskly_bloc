/// Categories for organizing screens in the navigation
enum ScreenCategory {
  /// Core workspace screens (inbox, today, upcoming, projects, labels, values)
  workspace,

  /// Wellbeing and health tracking features (dashboard, journal, trackers)
  wellbeing,

  /// Settings and configuration screens (app settings, navigation, allocation)
  settings;

  /// User-friendly display name
  String get displayName {
    switch (this) {
      case ScreenCategory.workspace:
        return 'Workspace';
      case ScreenCategory.wellbeing:
        return 'Wellbeing';
      case ScreenCategory.settings:
        return 'Settings';
    }
  }
}
