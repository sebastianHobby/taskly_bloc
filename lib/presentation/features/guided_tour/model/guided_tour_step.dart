import 'package:flutter/material.dart';

import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';

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
      route: '/my-day',
      title: 'Welcome to Taskly',
      body:
          'You are seeing a demo workspace for this tour. You will return to '
          'your real tasks when the tour ends.',
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'my_day_overview',
      route: '/my-day',
      title: 'Your plan for today',
      body: "My Day surfaces what matters and what's due.",
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'my_day_plan_button',
      route: '/my-day',
      title: 'Plan My Day',
      body: 'Choose tasks and routines that balance values and deadlines.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'my_day_plan_button',
        title: 'Plan My Day',
        body: 'Choose tasks and routines that balance values and deadlines.',
      ),
    ),
    GuidedTourStep(
      id: 'plan_my_day_triage',
      route: '/my-day',
      title: "What's due",
      body: 'Choose the time-sensitive tasks you want to handle today.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'plan_my_day_triage',
        title: "What's due",
        body: 'Choose the time-sensitive tasks you want to handle today.',
      ),
    ),
    GuidedTourStep(
      id: 'plan_my_day_scheduled_routines',
      route: '/my-day',
      title: 'Scheduled routines',
      body: "Pick the routines you're committing to today.",
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'plan_my_day_routines_scheduled',
        title: 'Scheduled routines',
        body: "Pick the routines you're committing to today.",
      ),
    ),
    GuidedTourStep(
      id: 'plan_my_day_flexible_routines',
      route: '/my-day',
      title: 'Flexible routines',
      body: 'Choose routines that move your weekly targets forward.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'plan_my_day_routines_flexible',
        title: 'Flexible routines',
        body: 'Choose routines that move your weekly targets forward.',
      ),
    ),
    GuidedTourStep(
      id: 'plan_my_day_values',
      route: '/my-day',
      title: 'What matters',
      body: 'Add value-aligned tasks to balance deadlines with what matters.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'plan_my_day_values_card',
        title: 'What matters',
        body: 'Add value-aligned tasks to balance deadlines with what matters.',
      ),
    ),
    GuidedTourStep(
      id: 'values_list',
      route: '/values',
      title: 'Define what matters',
      body: 'Add a few values so suggestions can keep what matters in focus.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'values_list',
        title: 'Define what matters',
        body: 'Add a few values so suggestions can keep what matters in focus.',
      ),
    ),
    GuidedTourStep(
      id: 'routines_scheduled_example',
      route: '/routines',
      title: 'Scheduled routines',
      body: 'Routines tied to set days to build consistency.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'routines_scheduled_example',
        title: 'Scheduled routines',
        body: 'Routines tied to set days to build consistency.',
      ),
    ),
    GuidedTourStep(
      id: 'routines_flexible_example',
      route: '/routines',
      title: 'Flexible routines',
      body: 'Routines you choose when to complete, week to week.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'routines_flexible_example',
        title: 'Flexible routines',
        body: 'Routines you choose when to complete, week to week.',
      ),
    ),
    GuidedTourStep(
      id: 'projects_overview',
      route: '/projects',
      title: 'Build your project list',
      body: "Projects is the source for today's plan in My Day.",
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'projects_create_project',
      route: '/projects',
      title: 'Create a project',
      body: "Start a project so My Day can pull from it.",
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'projects_create_project',
        title: 'Create a project',
        body: "Start a project so My Day can pull from it.",
      ),
    ),
    GuidedTourStep(
      id: 'values_alignment',
      route: '/projects',
      title: 'Values-led suggestions',
      body:
          'Set a value for each project. Taskly picks projects across your '
          'values, then chooses tasks inside them to keep progress balanced. '
          "You'll see those suggestions in Plan My Day.",
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'project_detail_suggestions',
      route: '/project/${DemoDataProvider.demoProjectGymId}/detail',
      title: 'How tasks get suggested',
      body: 'Taskly uses deadlines and priority to choose the next best tasks.',
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'scheduled_horizon',
      route: '/scheduled',
      title: "What's coming up",
      body: 'A date-based view to plan ahead.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'scheduled_section_today',
        title: "What's coming up",
        body: 'A date-based view to plan ahead.',
      ),
    ),
    GuidedTourStep(
      id: 'finish',
      route: '/projects',
      title: 'All set',
      body:
          "You're ready to plan and act. Replay the tour anytime in Settings.",
      kind: GuidedTourStepKind.card,
    ),
  ];
}
