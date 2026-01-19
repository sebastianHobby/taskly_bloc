import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_ritual_bloc.dart';
import 'package:taskly_bloc/presentation/screens/widgets/my_day_hero_card.dart';
import 'package:taskly_bloc/presentation/screens/widgets/my_day_accepted_buckets_section.dart';
import 'package:taskly_bloc/presentation/screens/widgets/my_day_task_list_section.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_ritual_wizard_page.dart';

class MyDayPage extends StatelessWidget {
  const MyDayPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    final isCompact = WindowSizeClass.of(context).isCompact;
    final today = getIt<HomeDayService>().todayDayKeyUtc().toLocal();

    return MultiBlocProvider(
      providers: [
        BlocProvider<MyDayGateBloc>(create: (_) => getIt<MyDayGateBloc>()),
        BlocProvider<MyDayBloc>(create: (_) => getIt<MyDayBloc>()),
        BlocProvider<MyDayRitualBloc>(create: (_) => getIt<MyDayRitualBloc>()),
      ],
      child: BlocBuilder<MyDayRitualBloc, MyDayRitualState>(
        builder: (context, ritualState) {
          final needsRitual =
              ritualState is MyDayRitualReady && ritualState.needsRitual;

          if (needsRitual) {
            return const MyDayRitualWizardPage();
          }

          if (ritualState is MyDayRitualLoading) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('My Day'),
                actions: TasklyAppBarActions.withAttentionBell(
                  context,
                  actions: const <Widget>[],
                ),
              ),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('My Day'),
              actions: TasklyAppBarActions.withAttentionBell(
                context,
                actions: [
                  if (!isCompact)
                    EntityAddMenuButton(
                      onCreateTask: () => _openNewTaskEditor(
                        context,
                        defaultDay: today,
                      ),
                      onCreateProject: () => _openNewProjectEditor(
                        context,
                      ),
                    ),
                ],
              ),
            ),
            floatingActionButton: isCompact
                ? EntityAddSpeedDial(
                    heroTag: 'add_speed_dial_my_day',
                    onCreateTask: () => _openNewTaskEditor(
                      context,
                      defaultDay: today,
                    ),
                    onCreateProject: () => _openNewProjectEditor(
                      context,
                    ),
                  )
                : null,
            body: const _MyDayLoadedBody(),
          );
        },
      ),
    );
  }
}

class _MyDayLoadedBody extends StatelessWidget {
  const _MyDayLoadedBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyDayBloc, MyDayState>(
      builder: (context, state) {
        return switch (state) {
          MyDayLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          MyDayError(:final message) => Center(child: Text(message)),
          MyDayLoaded(
            :final summary,
            :final mix,
            :final tasks,
            :final acceptedDue,
            :final acceptedStarts,
            :final acceptedFocus,
          ) =>
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: MyDayHeroCard(summary: summary),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: MyDayAcceptedBucketsSection(
                          acceptedDue: acceptedDue,
                          acceptedStarts: acceptedStarts,
                          acceptedFocus: acceptedFocus,
                        ),
                      ),
                    ),
                  ),
                  MyDayTaskListSection(
                    tasks: tasks,
                    mix: mix,
                  ),
                ],
              ),
            ),
        };
      },
    );
  }
}
