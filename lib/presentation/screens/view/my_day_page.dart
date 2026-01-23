import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_ritual_bloc.dart';
import 'package:taskly_bloc/presentation/screens/widgets/my_day_ritual_sections_card.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_ritual_wizard_page.dart';

enum _MyDayMode { execute, plan }

class MyDayPage extends StatefulWidget {
  const MyDayPage({super.key});

  @override
  State<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends State<MyDayPage> {
  _MyDayMode _mode = _MyDayMode.execute;
  MyDayRitualWizardInitialSection? _planInitialSection;

  Future<void> _openNewTaskEditor(
    BuildContext context, {
    required DateTime defaultDay,
  }) {
    return EditorLauncher.fromGetIt().openTaskEditor(
      context,
      taskId: null,
      showDragHandle: true,
      defaultStartDate: defaultDay,
      defaultDeadlineDate: defaultDay,
    );
  }

  Future<void> _openNewProjectEditor(BuildContext context) {
    return EditorLauncher.fromGetIt().openProjectEditor(
      context,
      projectId: null,
      showDragHandle: true,
    );
  }

  void _enterPlanMode(
    BuildContext context, {
    MyDayRitualWizardInitialSection? initialSection,
  }) {
    context.read<MyDayRitualBloc>().add(const MyDayRitualStarted());

    setState(() {
      _mode = _MyDayMode.plan;
      _planInitialSection = initialSection;
    });
  }

  void _exitPlanMode() {
    setState(() {
      _mode = _MyDayMode.execute;
      _planInitialSection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = getIt<HomeDayService>().todayDayKeyUtc().toLocal();

    return MultiBlocProvider(
      providers: [
        BlocProvider<MyDayGateBloc>(create: (_) => getIt<MyDayGateBloc>()),
        BlocProvider<MyDayBloc>(create: (_) => getIt<MyDayBloc>()),
        BlocProvider<MyDayRitualBloc>(create: (_) => getIt<MyDayRitualBloc>()),
        BlocProvider(create: (_) => SelectionCubit()),
      ],
      child: BlocBuilder<MyDayRitualBloc, MyDayRitualState>(
        builder: (context, ritualState) {
          final needsRitual =
              ritualState is MyDayRitualReady && ritualState.needsRitual;

          final effectiveMode = needsRitual ? _MyDayMode.plan : _mode;

          if (effectiveMode == _MyDayMode.plan) {
            return MyDayRitualWizardPage(
              allowClose: !needsRitual,
              initialSection: _planInitialSection,
              onCloseRequested: _exitPlanMode,
            );
          }

          if (ritualState is MyDayRitualLoading) {
            return Scaffold(
              appBar: AppBar(
                title: Text(context.l10n.myDayTitle),
                actions: TasklyAppBarActions.withAttentionBell(
                  context,
                  actions: const <Widget>[],
                ),
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.myDayPreparingTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.myDayPreparingSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return BlocBuilder<SelectionCubit, SelectionState>(
            builder: (context, selectionState) {
              return Scaffold(
                appBar: selectionState.isSelectionMode
                    ? SelectionAppBar(
                        baseTitle: context.l10n.myDayTitle,
                        onExit: () {},
                      )
                    : AppBar(
                        title: Text(context.l10n.myDayTitle),
                        actions: TasklyAppBarActions.withAttentionBell(
                          context,
                          actions: const <Widget>[],
                        ),
                      ),
                floatingActionButton: selectionState.isSelectionMode
                    ? null
                    : EntityAddSpeedDial(
                        heroTag: 'add_speed_dial_my_day',
                        onCreateTask: () => _openNewTaskEditor(
                          context,
                          defaultDay: today,
                        ),
                        onCreateProject: () => _openNewProjectEditor(
                          context,
                        ),
                      ),
                body: _MyDayLoadedBody(
                  onOpenPlan: (initialSection) => _enterPlanMode(
                    context,
                    initialSection: initialSection,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MyDayLoadedBody extends StatelessWidget {
  const _MyDayLoadedBody({required this.onOpenPlan});

  final void Function(MyDayRitualWizardInitialSection? initialSection)
  onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final ritualState = context.watch<MyDayRitualBloc>().state;
    final focusReasons = ritualState is MyDayRitualReady
        ? ritualState.curatedReasons
        : const <String, String>{};

    return BlocBuilder<MyDayBloc, MyDayState>(
      builder: (context, state) {
        return switch (state) {
          MyDayLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          MyDayError(:final message) => Center(child: Text(message)),
          MyDayLoaded(
            :final summary,
            :final acceptedDue,
            :final acceptedStarts,
            :final acceptedFocus,
            :final dueAcceptedTotalCount,
            :final startsAcceptedTotalCount,
            :final focusAcceptedTotalCount,
            :final selectedTotalCount,
            :final missingDueCount,
            :final missingStartsCount,
          ) =>
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _UpdatePlanCard(
                              selectedTotalCount: selectedTotalCount,
                              progressLabel: context.l10n
                                  .projectDetailCompletedCount(
                                    summary.doneCount,
                                    summary.totalCount,
                                  ),
                              onUpdatePlan: () => onOpenPlan(null),
                            ),
                            const SizedBox(height: 10),
                            MyDayRitualSectionsCard(
                              acceptedDue: acceptedDue,
                              acceptedStarts: acceptedStarts,
                              acceptedFocus: acceptedFocus,
                              focusReasons: focusReasons,
                              showCompletionMessage:
                                  selectedTotalCount > 0 &&
                                  acceptedDue.isEmpty &&
                                  acceptedStarts.isEmpty &&
                                  acceptedFocus.isEmpty,
                              onAddOneMoreFocus: selectedTotalCount > 0
                                  ? () => _openRitualResume(
                                      context,
                                      initialSection:
                                          MyDayRitualWizardInitialSection
                                              .suggested,
                                    )
                                  : null,
                              dueCounts: MyDayBucketCounts(
                                acceptedCount: dueAcceptedTotalCount,
                                otherCount: missingDueCount,
                              ),
                              startsCounts: MyDayBucketCounts(
                                acceptedCount: startsAcceptedTotalCount,
                                otherCount: missingStartsCount,
                              ),
                              onAddMissingDue: missingDueCount > 0
                                  ? () => _openRitualResume(
                                      context,
                                      initialSection:
                                          MyDayRitualWizardInitialSection.due,
                                    )
                                  : null,
                              onAddMissingStarts: missingStartsCount > 0
                                  ? () => _openRitualResume(
                                      context,
                                      initialSection:
                                          MyDayRitualWizardInitialSection
                                              .starts,
                                    )
                                  : null,
                              focusCounts: MyDayBucketCounts(
                                acceptedCount: focusAcceptedTotalCount,
                                otherCount: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        };
      },
    );
  }

  void _openRitualResume(
    BuildContext context, {
    MyDayRitualWizardInitialSection? initialSection,
  }) {
    onOpenPlan(initialSection);
  }
}

class _UpdatePlanCard extends StatelessWidget {
  const _UpdatePlanCard({
    required this.selectedTotalCount,
    required this.progressLabel,
    required this.onUpdatePlan,
  });

  final int selectedTotalCount;
  final String progressLabel;
  final VoidCallback onUpdatePlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;

    final title = selectedTotalCount == 0
        ? l10n.myDayPlanCardTitle
        : l10n.myDayPlanCardTitleWithPicked(selectedTotalCount);

    final buttonLabel = selectedTotalCount == 0
        ? l10n.myDayPlanCardButtonPlan
        : l10n.myDayUpdatePlanTitle;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progressLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onUpdatePlan,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
