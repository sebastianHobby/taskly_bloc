import 'package:flutter/widgets.dart';

abstract final class GuidedTourAnchors {
  static final GlobalKey projectsCreateProject = GlobalKey();
  static final GlobalKey valuesList = GlobalKey();
  static final GlobalKey myDayPlanButton = GlobalKey();
  static final GlobalKey myDayNavItem = GlobalKey();
  static final GlobalKey scheduledSectionToday = GlobalKey();
  static final GlobalKey routinesScheduledExample = GlobalKey();
  static final GlobalKey routinesFlexibleExample = GlobalKey();
  static final GlobalKey planMyDayTriage = GlobalKey();
  static final GlobalKey planMyDayScheduledRoutines = GlobalKey();
  static final GlobalKey planMyDayFlexibleRoutines = GlobalKey();
  static final GlobalKey planMyDayValuesCard = GlobalKey();

  static GlobalKey? keyFor(String id) {
    return switch (id) {
      'projects_create_project' => projectsCreateProject,
      'values_list' => valuesList,
      'my_day_plan_button' => myDayPlanButton,
      'nav_my_day' => myDayNavItem,
      'scheduled_section_today' => scheduledSectionToday,
      'routines_scheduled_example' => routinesScheduledExample,
      'routines_flexible_example' => routinesFlexibleExample,
      'plan_my_day_triage' => planMyDayTriage,
      'plan_my_day_routines_scheduled' => planMyDayScheduledRoutines,
      'plan_my_day_routines_flexible' => planMyDayFlexibleRoutines,
      'plan_my_day_values_card' => planMyDayValuesCard,
      _ => null,
    };
  }
}
