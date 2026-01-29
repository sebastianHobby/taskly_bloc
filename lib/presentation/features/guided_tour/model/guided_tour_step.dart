import 'package:flutter/material.dart';

enum GuidedTourStepKind { card, coachmark }

@immutable
class GuidedTourCoachmark {
  const GuidedTourCoachmark({
    required this.targetId,
    required this.title,
    required this.body,
  });

  final String targetId;
  final String title;
  final String body;
}

@immutable
class GuidedTourStep {
  const GuidedTourStep({
    required this.id,
    required this.route,
    required this.title,
    required this.body,
    required this.kind,
    this.coachmark,
  });

  final String id;
  final String route;
  final String title;
  final String body;
  final GuidedTourStepKind kind;
  final GuidedTourCoachmark? coachmark;
}

List<GuidedTourStep> buildGuidedTourSteps() {
  return [
    GuidedTourStep(
      id: 'welcome',
      route: '/anytime',
      title: 'Welcome to Taskly',
      body:
          'You are seeing a demo workspace for this tour. You will return to '
          'your real tasks when the tour ends.',
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'anytime_overview',
      route: '/anytime',
      title: 'Anytime shows every project',
      body:
          'Anytime is your home base. It keeps every project visible so you '
          'always know what is in motion.',
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'anytime_add',
      route: '/anytime',
      title: 'Add tasks here...',
      body: 'Use the + button to add a project or task from anywhere.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'anytime_create_project',
        title: 'Add tasks here...',
        body: 'Use the + button to add a project or task from anywhere.',
      ),
    ),
    GuidedTourStep(
      id: 'inbox_capture',
      route: '/anytime',
      title: 'Inbox for capture',
      body:
          'Capture now, organize later. Move tasks into projects when you '
          'are ready.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'anytime_inbox_row',
        title: 'Inbox for capture',
        body:
            'Capture now, organize later. Move tasks into projects when you '
            'are ready.',
      ),
    ),
    GuidedTourStep(
      id: 'task_project_value',
      route: '/task/new',
      title: 'Set the project',
      body:
          'Set the project to connect this task to a value. Taskly uses that '
          'to suggest the right work. You can also add extra values to a '
          'task.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'task_project_value',
        title: 'Set the project',
        body:
            'Set the project to connect this task to a value. Taskly uses '
            'that to suggest the right work. You can also add extra values '
            'to a task.',
      ),
    ),
    GuidedTourStep(
      id: 'project_detail',
      route: '/project/inbox/detail',
      title: 'Projects hold the work',
      body:
          'Open a project to see its tasks, deadlines, and priorities in one '
          'place.',
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'values_framing',
      route: '/values',
      title: 'Values guide your focus',
      body:
          'Values keep your days balanced. They shape suggestions and help '
          'you choose what matters most.',
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'values_list',
      route: '/values',
      title: 'Define what matters',
      body:
          'Add a few values so Taskly can recommend the right tasks and '
          'routines.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'values_list',
        title: 'Define what matters',
        body:
            'Add a few values so Taskly can recommend the right tasks and '
            'routines.',
      ),
    ),
    GuidedTourStep(
      id: 'routines_overview',
      route: '/routines',
      title: 'Routines build momentum',
      body:
          'Routines can be flexible or scheduled. Use them to keep progress '
          'steady.',
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'scheduled_horizon',
      route: '/scheduled',
      title: 'Scheduled looks ahead',
      body: 'See upcoming tasks by date so nothing sneaks up on you.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'scheduled_section_today',
        title: 'Scheduled looks ahead',
        body: 'See upcoming tasks by date so nothing sneaks up on you.',
      ),
    ),
    GuidedTourStep(
      id: 'plan_my_day_entry',
      route: '/my-day',
      title: 'Plan My Day',
      body: 'Review suggestions and pick the tasks you want to focus on today.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'my_day_plan_button',
        title: 'Plan My Day',
        body:
            'Review suggestions and pick the tasks you want to focus on '
            'today.',
      ),
    ),
    GuidedTourStep(
      id: 'plan_my_day_triage',
      route: '/my-day',
      title: 'Start with time-sensitive',
      body:
          "Start with what's time-sensitive. Choose the items you want to "
          'handle today.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'plan_my_day_triage',
        title: 'Start with time-sensitive',
        body:
            "Start with what's time-sensitive. Choose the items you want to "
            'handle today.',
      ),
    ),
    GuidedTourStep(
      id: 'plan_my_day_scheduled_routines',
      route: '/my-day',
      title: 'Scheduled routines',
      body: "Pick the scheduled habits you're committing to today.",
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'plan_my_day_routines_scheduled',
        title: 'Scheduled routines',
        body: "Pick the scheduled habits you're committing to today.",
      ),
    ),
    GuidedTourStep(
      id: 'plan_my_day_flexible_routines',
      route: '/my-day',
      title: 'Flexible routines',
      body: 'Pick flexible routines to make progress on your weekly targets.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'plan_my_day_routines_flexible',
        title: 'Flexible routines',
        body: 'Pick flexible routines to make progress on your weekly targets.',
      ),
    ),
    GuidedTourStep(
      id: 'plan_my_day_values',
      route: '/my-day',
      title: 'Value-aligned picks',
      body:
          'Choose value-aligned tasks to round out your plan. Suggestions '
          'follow task completions by default, or weekly check-ins if you '
          'want a more reflective approach.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'plan_my_day_values_card',
        title: 'Value-aligned picks',
        body:
            'Choose value-aligned tasks to round out your plan. Suggestions '
            'follow task completions by default, or weekly check-ins if you '
            'want a more reflective approach.',
      ),
    ),
    GuidedTourStep(
      id: 'plan_my_day_summary',
      route: '/my-day',
      title: 'Review and confirm',
      body: "Review your selections and confirm today's plan.",
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'my_day_summary',
      route: '/my-day',
      title: 'Your plan for today',
      body: 'Here is the list you just chose, mixing tasks and routines.',
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'my_day_focus_list',
      route: '/my-day',
      title: "Today's focus list",
      body:
          'This is the short list you commit to. Keep it realistic and move '
          'what is done to completed.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'my_day_focus_task_1',
        title: "Today's focus list",
        body:
            'This is the short list you commit to. Keep it realistic and '
            'move what is done to completed.',
      ),
    ),
    GuidedTourStep(
      id: 'finish',
      route: '/anytime',
      title: 'You are ready',
      body:
          'The tour is done. Open Settings > Guided tour anytime to replay '
          'it.',
      kind: GuidedTourStepKind.card,
    ),
  ];
}
