/// Canonical template IDs for all section templates.
abstract final class SectionTemplateId {
  // Core list/section templates
  static const taskList = 'task_list';
  static const projectList = 'project_list';
  static const valueList = 'value_list';
  static const interleavedList = 'interleaved_list';
  static const agenda = 'agenda';
  static const allocation = 'allocation';

  // System composites
  static const somedayNullDates = 'someday_null_dates';

  // Former support-block behaviors (now inline sections)
  static const issuesSummary = 'issues_summary';
  static const checkInSummary = 'check_in_summary';
  static const allocationAlerts = 'allocation_alerts';
  static const entityHeader = 'entity_header';

  // Former custom screens (now templated)
  static const settingsMenu = 'settings_menu';
  static const workflowList = 'workflow_list';
  static const journalTimeline = 'journal_timeline';
  static const navigationSettings = 'navigation_settings';
  static const allocationSettings = 'allocation_settings';
  static const attentionRules = 'attention_rules';
  static const focusSetupWizard = 'focus_setup_wizard';
  static const screenManagement = 'screen_management';
  static const trackerManagement = 'tracker_management';
  static const wellbeingDashboard = 'wellbeing_dashboard';
  static const statisticsDashboard = 'statistics_dashboard';
}
