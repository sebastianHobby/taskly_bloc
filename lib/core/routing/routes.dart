abstract class AppRouteName {
  static const screen = 'screen';
  static const projects = 'projects';
  static const projectDetail = 'projectDetail';
  static const taskNextActions = 'taskNextActions';
  static const taskNextActionsSettings = 'taskNextActionsSettings';
  static const taskDetail = 'taskDetail';

  static const navigationSettings = 'navigationSettings';
  static const appSettings = 'appSettings';

  static const inbox = 'inbox';
  static const today = 'today';
  static const upcoming = 'upcoming';
  static const tasks = 'tasks';
  static const labels = 'labels';
  static const values = 'values';
  static const labelDetail = 'labelDetail';

  // New features
  static const wellbeing = 'wellbeing';
  static const journal = 'journal';
  static const trackerManagement = 'trackerManagement';
}

abstract class AppRoutePath {
  static const screenBase = '/s';
  static const screen = '$screenBase/:screenId';
  static const navigationSettings = '/settings/navigation';
  static const appSettings = '/settings/app';

  static const projects = '/projects';
  static const taskNextActions = '/tasks/next-actions';
  static const taskNextActionsSettings = '/tasks/next-actions/settings';
  static const projectDetail = '/projects/:projectId';
  static const taskDetail = '/tasks/:taskId';
  static const inbox = '$screenBase/inbox';
  static const today = '$screenBase/today';
  static const upcoming = '$screenBase/upcoming';
  static const tasks = '/tasks';
  static const labels = '/labels';
  static const values = '/values';

  // New features
  static const wellbeing = '/wellbeing';
  static const journal = '/wellbeing/journal';
  static const trackerManagement = '/wellbeing/trackers';
}
