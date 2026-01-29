import 'package:flutter/widgets.dart';

abstract final class GuidedTourAnchors {
  static final GlobalKey anytimeCreateProject = GlobalKey();
  static final GlobalKey anytimeInboxRow = GlobalKey();
  static final GlobalKey valuesList = GlobalKey();
  static final GlobalKey myDayPlanButton = GlobalKey();
  static final GlobalKey myDayFocusTask1 = GlobalKey();
  static final GlobalKey scheduledSectionToday = GlobalKey();
  static final GlobalKey taskProjectAndValue = GlobalKey();
  static final GlobalKey planMyDayTriage = GlobalKey();
  static final GlobalKey planMyDayScheduledRoutines = GlobalKey();
  static final GlobalKey planMyDayFlexibleRoutines = GlobalKey();
  static final GlobalKey planMyDayValuesCard = GlobalKey();

  static GlobalKey? keyFor(String id) {
    return switch (id) {
      'anytime_create_project' => anytimeCreateProject,
      'anytime_inbox_row' => anytimeInboxRow,
      'values_list' => valuesList,
      'my_day_plan_button' => myDayPlanButton,
      'my_day_focus_task_1' => myDayFocusTask1,
      'scheduled_section_today' => scheduledSectionToday,
      'task_project_value' => taskProjectAndValue,
      'plan_my_day_triage' => planMyDayTriage,
      'plan_my_day_routines_scheduled' => planMyDayScheduledRoutines,
      'plan_my_day_routines_flexible' => planMyDayFlexibleRoutines,
      'plan_my_day_values_card' => planMyDayValuesCard,
      _ => null,
    };
  }
}
