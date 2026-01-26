import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/routines/bloc/routine_list_bloc.dart';
import 'package:taskly_bloc/presentation/features/routines/widgets/routines_list.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

  void _createRoutine(BuildContext context) {
    Routing.toRoutineNew(context);
  }

  void _editRoutine(BuildContext context, String routineId) {
    Routing.toRoutineEdit(context, routineId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RoutineListBloc>(
      create: (context) => RoutineListBloc(
        routineRepository: getIt<RoutineRepositoryContract>(),
        sessionDayKeyService: getIt<SessionDayKeyService>(),
        errorReporter: context.read<AppErrorReporter>(),
      )..add(const RoutineListEvent.subscriptionRequested()),
      child: Builder(
        builder: (context) {
          final isCompact = WindowSizeClass.of(context).isCompact;

          return Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.routinesTitle),
              actions: TasklyAppBarActions.withAttentionBell(
                context,
                actions: [
                  if (!isCompact)
                    IconButton(
                      tooltip: context.l10n.routineCreateTooltip,
                      onPressed: () => _createRoutine(context),
                      icon: const Icon(Icons.add),
                    ),
                ],
              ),
            ),
            floatingActionButton: isCompact
                ? FloatingActionButton(
                    tooltip: context.l10n.routineCreateTooltip,
                    onPressed: () => _createRoutine(context),
                    heroTag: 'create_routine_fab',
                    child: const Icon(Icons.add),
                  )
                : null,
            body: BlocBuilder<RoutineListBloc, RoutineListState>(
              builder: (context, state) {
                return switch (state) {
                  RoutineListInitial() ||
                  RoutineListLoading() => const TasklyFeedRenderer(
                    spec: TasklyFeedSpec.loading(),
                  ),
                  RoutineListError(:final error) => TasklyFeedRenderer(
                    spec: TasklyFeedSpec.error(
                      message: friendlyErrorMessageForUi(
                        error,
                        context.l10n,
                      ),
                      retryLabel: context.l10n.retryButton,
                      onRetry: () => context.read<RoutineListBloc>().add(
                        const RoutineListEvent.subscriptionRequested(),
                      ),
                    ),
                  ),
                  RoutineListLoaded(:final routines) when routines.isEmpty =>
                    TasklyFeedRenderer(
                      spec: TasklyFeedSpec.empty(
                        empty: TasklyEmptyStateSpec(
                          icon: Icons.auto_awesome,
                          title: context.l10n.routineEmptyTitle,
                          description: context.l10n.routineEmptyDescription,
                          actionLabel: context.l10n.routineCreateCta,
                          onAction: () => _createRoutine(context),
                        ),
                      ),
                    ),
                  RoutineListLoaded(:final routines) => RoutinesListView(
                    items: routines,
                    onEditRoutine: (id) => _editRoutine(context, id),
                  ),
                };
              },
            ),
          );
        },
      ),
    );
  }
}
