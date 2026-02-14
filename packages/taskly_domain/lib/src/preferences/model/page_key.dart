/// Enum representing different pages in the app that have persisted settings.
///
/// Each page can have its own sort preferences and display settings.
enum PageKey {
  /// Tasks inbox view
  tasksInbox('tasks_inbox'),

  /// Tasks today view
  tasksToday('tasks_today'),

  /// Tasks upcoming view
  tasksUpcoming('tasks_upcoming'),

  /// Task overview page (main tasks page)
  taskOverview('task_overview'),

  /// Projects overview page
  projectOverview('project_overview'),

  /// Project detail page
  projectDetail('project_detail'),

  /// My Day page
  myDay('my_day'),

  /// Scheduled page
  scheduled('scheduled'),

  /// Labels overview page
  labelOverview('label_overview');

  const PageKey(this.key);

  /// The string key used for persistence.
  final String key;

  /// Create PageKey from string key.
  static PageKey fromKey(String key) {
    return PageKey.values.firstWhere(
      (e) => e.key == key,
      orElse: () => throw ArgumentError('Unknown page key: $key'),
    );
  }
}
