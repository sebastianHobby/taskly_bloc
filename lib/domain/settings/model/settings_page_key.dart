/// Keys for persisted page-specific settings.
class SettingsPageKey {
  static const inbox = 'inbox';
  static const myDay = 'my_day';
  @Deprecated('Use myDay instead')
  static const today = 'today';
  static const upcoming = 'upcoming';
  static const tasks = 'tasks';
  static const projects = 'projects';
  static const labels = 'labels';
  static const values = 'values';
  @Deprecated('Use myDay instead')
  static const nextActions = 'nextActions';
}
