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
      title: 'My Day',
      body: 'My Day shows your selected tasks and routines for today.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'nav_my_day',
        title: 'My Day',
        body: 'My Day shows your selected tasks and routines for today.',
      ),
    ),
    GuidedTourStep(
      id: 'my_day_plan_button',
      route: '/my-day',
      title: 'Plan My Day',
      body: "Build today's plan by choosing tasks and routines for today.",
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'my_day_plan_button',
        title: 'Plan My Day',
        body: "Build today's plan by choosing tasks and routines for today.",
      ),
    ),
    GuidedTourStep(
      id: 'plan_my_day_triage',
      route: '/my-day',
      title: 'Due today',
      body:
          'Overdue and due-today items are in your plan. Reschedule if not '
          'today.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'plan_my_day_triage',
        title: 'Due today',
        body:
            'Overdue and due-today items are in your plan. Reschedule if not '
            'today.',
      ),
    ),
    GuidedTourStep(
      id: 'plan_my_day_routines',
      route: '/my-day',
      title: 'Routines',
      body: 'Scheduled and flexible routines show up here. Keep or deselect.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'plan_my_day_routines_block',
        title: 'Routines',
        body: 'Scheduled and flexible routines show up here. Keep or deselect.',
      ),
    ),
    GuidedTourStep(
      id: 'plan_my_day_values',
      route: '/my-day',
      title: 'Suggestions by value',
      body: 'Add value-aligned tasks based on your latest ratings.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'plan_my_day_values_card',
        title: 'Suggestions by value',
        body: 'Add value-aligned tasks based on your latest ratings.',
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
      title: 'Projects',
      body: 'Build your project list with tasks grouped underneath.',
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'projects_create_project',
      route: '/projects',
      title: 'Create a project',
      body: "Start a project to organize what you're working on.",
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'projects_create_project',
        title: 'Create a project',
        body: "Start a project to organize what you're working on.",
      ),
    ),
    GuidedTourStep(
      id: 'values_alignment',
      route: '/projects',
      title: 'Values-led suggestions',
      body:
          'Assign a value to each project. Taskly uses your ratings to guide '
          'suggestions.',
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'project_detail_suggestions',
      route: '/project/${DemoDataProvider.demoProjectGymId}/detail',
      title: 'How suggestions work',
      body:
          'Taskly uses your weekly value ratings to guide suggestions. Lower '
          'ratings or downward trends can surface more tasks.',
      kind: GuidedTourStepKind.card,
    ),
    GuidedTourStep(
      id: 'scheduled_horizon',
      route: '/scheduled',
      title: 'Scheduled',
      body: 'A date-based view of tasks and projects to plan ahead.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'scheduled_section_today',
        title: 'Scheduled',
        body: 'A date-based view of tasks and projects to plan ahead.',
      ),
    ),
    GuidedTourStep(
      id: 'finish',
      route: '/projects',
      title: 'All set',
      body: "You're ready to plan and act. Replay the tour in Settings.",
      kind: GuidedTourStepKind.card,
    ),
  ];
}
