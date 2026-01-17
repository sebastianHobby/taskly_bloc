/// Canonical template IDs for all section templates.
abstract final class SectionTemplateId {
  // Dedicated hierarchy templates
  static const hierarchyValueProjectTaskV2 = 'hierarchy_value_project_task_v2';

  // V2 list/section templates
  static const taskListV2 = 'task_list_v2';
  static const valueListV2 = 'value_list_v2';
  static const interleavedListV2 = 'interleaved_list_v2';
  static const agendaV2 = 'agenda_v2';

  // Support-block behaviors
  static const attentionBannerV2 = 'attention_banner_v2';
  static const attentionInboxV1 = 'attention_inbox_v1';
  static const entityHeader = 'entity_header';

  // My Day
  static const myDayHeroV1 = 'my_day_hero_v1';
  static const myDayRankedTasksV1 = 'my_day_ranked_tasks_v1';

  // Values
  static const createValueCtaV1 = 'create_value_cta_v1';

  // Journal
  static const journalTodayComposerV1 = 'journal_today_composer_v1';
  static const journalTodayEntriesV1 = 'journal_today_entries_v1';
  static const journalHistoryTeaserV1 = 'journal_history_teaser_v1';
  static const journalHistoryListV1 = 'journal_history_list_v1';
  static const journalManageTrackersV1 = 'journal_manage_trackers_v1';

  // Former custom screens (now templated)
  static const settingsMenu = 'settings_menu';
  static const trackerManagement = 'tracker_management';
  static const statisticsDashboard = 'statistics_dashboard';

  // Screen-level gates (full-screen)
  static const myDayFocusModeRequired = 'my_day_focus_mode_required';
}
