import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/widgets/app_loading_screen.dart';
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
            return AppLoadingScreen(
              appBarTitle: context.l10n.myDayTitle,
              title: context.l10n.myDayPreparingTitle,
              subtitle: context.l10n.myDayPreparingSubtitle,
              icon: Icons.auto_awesome,
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
                        toolbarHeight: 56,
                        title: Text(
                          context.l10n.myDayTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
                  today: today,
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
  const _MyDayLoadedBody({
    required this.today,
    required this.onOpenPlan,
  });

  final DateTime today;
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
          MyDayLoading() => Center(
            child: AppLoadingContent(
              title: context.l10n.myDayPreparingTitle,
              subtitle: context.l10n.myDayPreparingSubtitle,
              icon: Icons.auto_awesome,
            ),
          ),
          MyDayError(:final message) => Center(child: Text(message)),
          MyDayLoaded(
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _MyDayHeaderRow(
                              today: today,
                              onUpdatePlan: () => onOpenPlan(null),
                            ),
                            const SizedBox(height: 12),
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
                              onWhyThese: () => _openRitualResume(
                                context,
                                initialSection:
                                    MyDayRitualWizardInitialSection.suggested,
                              ),
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

class _MyDayHeaderRow extends StatelessWidget {
  const _MyDayHeaderRow({
    required this.today,
    required this.onUpdatePlan,
  });

  final DateTime today;
  final VoidCallback onUpdatePlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat('EEE, MMM d', locale).format(today);

    return Row(
      children: [
        Expanded(
          child: Text(
            dateLabel,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        FilledButton.tonal(
          onPressed: onUpdatePlan,
          style: FilledButton.styleFrom(
            backgroundColor: cs.primaryContainer.withOpacity(0.6),
            foregroundColor: cs.primary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(context.l10n.myDayUpdatePlanTitle),
        ),
      ],
    );
  }
}
