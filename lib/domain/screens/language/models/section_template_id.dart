/// Canonical template IDs for all section templates.
abstract final class SectionTemplateId {
  // Core section templates
  static const allocation = 'allocation';

  // Dedicated hierarchy templates
  static const hierarchyValueProjectTaskV2 = 'hierarchy_value_project_task_v2';

  // V2 list/section templates
  static const taskListV2 = 'task_list_v2';
  static const projectListV2 = 'project_list_v2';
  static const valueListV2 = 'value_list_v2';
  static const interleavedListV2 = 'interleaved_list_v2';
  static const agendaV2 = 'agenda_v2';

  // Former support-block behaviors (now inline sections)
  static const issuesSummary = 'issues_summary';
  static const checkInSummary = 'check_in_summary';
  static const allocationAlerts = 'allocation_alerts';
  static const entityHeader = 'entity_header';

  // Former custom screens (now templated)
  static const settingsMenu = 'settings_menu';
  static const journalTimeline = 'journal_timeline';
  static const navigationSettings = 'navigation_settings';
  static const allocationSettings = 'allocation_settings';
  static const attentionRules = 'attention_rules';
  static const focusSetupWizard = 'focus_setup_wizard';
  static const trackerManagement = 'tracker_management';
  static const journalDashboard = 'journal_dashboard';
  static const statisticsDashboard = 'statistics_dashboard';

  // Navigation hub / browse
  static const browseHub = 'browse_hub';

  // Screen-level gates (full-screen)
  static const myDayFocusModeRequired = 'my_day_focus_mode_required';
}
