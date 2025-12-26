abstract class AppRouteName {
  static const projects = 'projects';
  static const projectDetail = 'projectDetail';
  static const taskNextActions = 'taskNextActions';
  static const taskNextActionsSettings = 'taskNextActionsSettings';

  static const inbox = 'inbox';
  static const today = 'today';
  static const upcoming = 'upcoming';
  static const tasks = 'tasks';
  static const labels = 'labels';
  static const values = 'values';
  static const labelDetail = 'labelDetail';

  // New features
  static const reviews = 'reviews';
  static const reviewDetail = 'reviewDetail';
  static const wellbeing = 'wellbeing';
  static const journal = 'journal';
}

abstract class AppRoutePath {
  static const projects = '/projects';
  static const taskNextActions = '/tasks/next-actions';
  static const taskNextActionsSettings = '/tasks/next-actions/settings';
  static const projectDetail = '/projects/detail';
  static const inbox = '/inbox';
  static const today = '/tasks/today';
  static const upcoming = '/tasks/upcoming';
  static const tasks = '/tasks';
  static const labels = '/labels';
  static const values = '/values';

  // New features
  static const reviews = '/reviews';
  static const reviewDetail = '/reviews/detail';
  static const wellbeing = '/wellbeing';
  static const journal = '/wellbeing/journal';
}
