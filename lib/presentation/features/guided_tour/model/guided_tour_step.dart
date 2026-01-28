import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

enum GuidedTourStepKind { card, coachmark }

enum GuidedTourPreviewType {
  anytimeOverview,
  inboxDetail,
  projectDetail,
  routines,
  planMyDay,
  myDayExecution,
  scheduled,
  valuesIntro,
}

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
    this.previewType,
    this.coachmark,
  });

  final String id;
  final String route;
  final String title;
  final String body;
  final GuidedTourStepKind kind;
  final GuidedTourPreviewType? previewType;
  final GuidedTourCoachmark? coachmark;
}

List<GuidedTourStep> buildGuidedTourSteps() {
  final anytime = Routing.screenPath('someday');
  final myDay = Routing.screenPath('my_day');
  final scheduled = Routing.screenPath('scheduled');
  final routines = Routing.screenPath('routines');
  final values = Routing.screenPath('values');

  return [
    GuidedTourStep(
      id: 'anytime_overview',
      route: anytime,
      title: 'Anytime',
      body:
          'Anytime is where all your tasks and projects live. '
          'My Day brings the right ones forward when it matters.',
      kind: GuidedTourStepKind.card,
      previewType: GuidedTourPreviewType.anytimeOverview,
    ),
    GuidedTourStep(
      id: 'inbox_detail',
      route: '/project/inbox/detail',
      title: 'Inbox',
      body:
          'Inbox is for capturing tasks quickly. Move them into projects and '
          'add values when you are ready.',
      kind: GuidedTourStepKind.card,
      previewType: GuidedTourPreviewType.inboxDetail,
    ),
    GuidedTourStep(
      id: 'create_project',
      route: anytime,
      title: 'Create a project',
      body: 'Group related tasks together.',
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'anytime_create',
        title: 'Create a project',
        body: 'Projects help you keep related tasks together.',
      ),
    ),
    GuidedTourStep(
      id: 'project_detail',
      route: '/project/inbox/detail',
      title: 'Project details',
      body:
          "Projects keep tasks and values together. Tasks inherit the project's "
          'value, and you can add another value when needed.',
      kind: GuidedTourStepKind.card,
      previewType: GuidedTourPreviewType.projectDetail,
    ),
    GuidedTourStep(
      id: 'routines',
      route: routines,
      title: 'Routines',
      body:
          'Routines are habits linked to your values. '
          'They can show up in Plan My Day when you want them to.',
      kind: GuidedTourStepKind.card,
      previewType: GuidedTourPreviewType.routines,
    ),
    GuidedTourStep(
      id: 'plan_my_day_entry',
      route: myDay,
      title: 'Plan My Day',
      body:
          'Taskly uses your values, routines, and urgent items to build '
          "today's focus list. You confirm the final picks.",
      kind: GuidedTourStepKind.coachmark,
      coachmark: GuidedTourCoachmark(
        targetId: 'my_day_plan_button',
        title: 'Plan My Day',
        body: "Tap to build today's plan.",
      ),
    ),
    GuidedTourStep(
      id: 'plan_my_day_flow',
      route: myDay,
      title: 'Pick what matters most',
      body: "Choose a few suggestions to build today's list.",
      kind: GuidedTourStepKind.card,
      previewType: GuidedTourPreviewType.planMyDay,
    ),
    GuidedTourStep(
      id: 'my_day_execution',
      route: myDay,
      title: 'My Day',
      body: "This is today's focus list.",
      kind: GuidedTourStepKind.card,
      previewType: GuidedTourPreviewType.myDayExecution,
    ),
    GuidedTourStep(
      id: 'scheduled',
      route: scheduled,
      title: 'Scheduled',
      body: 'Upcoming tasks and projects, grouped by date.',
      kind: GuidedTourStepKind.card,
      previewType: GuidedTourPreviewType.scheduled,
    ),
    GuidedTourStep(
      id: 'values',
      route: values,
      title: 'Values',
      body: 'Values guide suggestions and balance your focus.',
      kind: GuidedTourStepKind.card,
      previewType: GuidedTourPreviewType.valuesIntro,
    ),
  ];
}
