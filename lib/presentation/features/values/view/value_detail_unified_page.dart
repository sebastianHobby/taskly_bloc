import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/screens/language/models/value_stats.dart'
    as screens;
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';
import 'package:taskly_bloc/presentation/entity_views/value_view.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_detail_bloc.dart';
import 'package:taskly_bloc/core/performance/performance_logger.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_state.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/error_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/loading_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';

/// Unified value detail page using the screen model.
///
/// Fetches the value first, then creates a typed [ScreenSpec]
/// and renders using the unified pattern.
class ValueDetailUnifiedPage extends StatelessWidget {
  const ValueDetailUnifiedPage({
    required this.valueId,
    super.key,
  });

  final String valueId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ValueDetailBloc>(
      create: (_) => ValueDetailBloc(
        valueRepository: getIt<ValueRepositoryContract>(),
        valueId: valueId,
      ),
      child: _ValueDetailContent(valueId: valueId),
    );
  }
}

class _ValueDetailContent extends StatelessWidget {
  const _ValueDetailContent({required this.valueId});

  final String valueId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ValueDetailBloc, ValueDetailState>(
      builder: (context, state) {
        return switch (state) {
          ValueDetailInitial() ||
          ValueDetailLoadInProgress() => const _LoadingScaffold(),
          ValueDetailLoadSuccess(:final value) => _ValueScreenWithData(
            value: value,
          ),
          ValueDetailOperationFailure(:final errorDetails) => _ErrorScaffold(
            message: friendlyErrorMessageForUi(
              errorDetails.error,
              context.l10n,
            ),
            onRetry: () => context.read<ValueDetailBloc>().add(
              ValueDetailEvent.loadById(valueId: valueId),
            ),
          ),
          _ => const _LoadingScaffold(),
        };
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.valuesTitle)),
      body: const LoadingStateWidget(),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.valuesTitle)),
      body: ErrorStateWidget(message: message, onRetry: onRetry),
    );
  }
}

/// Main content view when value is loaded
class _ValueScreenWithData extends StatelessWidget {
  const _ValueScreenWithData({required this.value});

  final Value value;

  @override
  Widget build(BuildContext context) {
    final spec = ScreenSpec(
      id: 'value_${value.id}',
      screenKey: 'value_detail',
      name: value.name,
      template: const ScreenTemplateSpec.standardScaffoldV1(),
      modules: SlottedModules(
        primary: [
          ScreenModuleSpec.taskListV2(
            title: 'Tasks',
            params: ListSectionParamsV2(
              config: DataConfig.task(
                query: TaskQuery.forValue(valueId: value.id),
              ),
              pack: StylePackV2.standard,
              layout: const SectionLayoutSpecV2.flatList(
                separator: ListSeparatorV2.divider,
              ),
            ),
          ),
          ScreenModuleSpec.projectListV2(
            title: 'Projects',
            params: ListSectionParamsV2(
              config: DataConfig.project(
                query: ProjectQuery.byValues([value.id]),
              ),
              pack: StylePackV2.standard,
              layout: const SectionLayoutSpecV2.flatList(
                separator: ListSeparatorV2.spaced8,
              ),
            ),
          ),
        ],
      ),
    );

    return BlocProvider<ScreenSpecBloc>(
      create: (_) => ScreenSpecBloc(
        interpreter: getIt(),
      )..add(ScreenSpecLoadEvent(spec: spec)),
      child: BlocListener<ScreenSpecBloc, ScreenSpecState>(
        listenWhen: (previous, current) {
          return previous is! ScreenSpecLoadedState &&
              current is ScreenSpecLoadedState;
        },
        listener: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            getIt<PerformanceLogger>().markFirstPaint();
          });
        },
        child: _ValueScreenView(value: value),
      ),
    );
  }
}

class _ValueScreenView extends StatefulWidget {
  const _ValueScreenView({required this.value});

  final Value value;

  @override
  State<_ValueScreenView> createState() => _ValueScreenViewState();
}

class _ValueScreenViewState extends State<_ValueScreenView> {
  screens.ValueStats? _valueStats;
  bool _isLoadingStats = true;

  Value get value => widget.value;

  @override
  void initState() {
    super.initState();
    _loadValueStats();
  }

  Future<void> _loadValueStats() async {
    try {
      final analyticsService = getIt<AnalyticsService>();

      // Load all required data in parallel
      final results = await Future.wait([
        analyticsService.getValueWeeklyTrends(weeks: 8),
        analyticsService.getValueActivityStats(),
        analyticsService.getRecentCompletionsByValue(days: 56),
        analyticsService.getTotalRecentCompletions(days: 56),
      ]);

      final weeklyTrends = results[0] as Map<String, List<double>>;
      final activityStats = results[1] as Map<String, ValueActivityStats>;
      final recentCompletions = results[2] as Map<String, int>;
      final totalRecentCompletions = results[3] as int;

      // Calculate actual percent from recent completions
      final actualPercent = totalRecentCompletions > 0
          ? ((recentCompletions[value.id] ?? 0) / totalRecentCompletions) * 100
          : 0.0;

      // Get weekly trend data
      final weeklyTrend = weeklyTrends[value.id] ?? [];

      // Get activity stats
      final activity =
          activityStats[value.id] ??
          const ValueActivityStats(taskCount: 0, projectCount: 0);

      if (mounted) {
        setState(() {
          _valueStats = screens.ValueStats(
            targetPercent: 0, // No longer tracking target allocation
            actualPercent: actualPercent,
            taskCount: activity.taskCount,
            projectCount: activity.projectCount,
            weeklyTrend: weeklyTrend,
            gapWarningThreshold: 15,
          );
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  void _showEditValueSheet(BuildContext context) {
    final launcher = EditorLauncher.fromGetIt();
    unawaited(
      launcher.openValueEditor(
        context,
        valueId: value.id,
        onSaved: (savedValueId) {
          // Refresh the value details after edit
          context.read<ValueDetailBloc>().add(
            ValueDetailEvent.loadById(valueId: savedValueId),
          );
        },
        showDragHandle: true,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      title: l10n.deleteValue,
      itemName: value.name,
      description: l10n.deleteValueCascadeDescription,
    );

    if (confirmed && context.mounted) {
      context.read<ValueDetailBloc>().add(
        ValueDetailEvent.delete(id: value.id),
      );
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _showEditValueSheet(context);
      case 'delete':
        unawaited(_showDeleteConfirmation(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entityActionService = getIt<EntityActionService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(value.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l10n.editValue,
            onPressed: () => _showEditValueSheet(context),
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleMenuAction(context, action),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.deleteValue,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Entity header - use ValueView for values
          if (_isLoadingStats)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ValueView(
              value: value,
              stats: _valueStats,
              onTap: () => _showEditValueSheet(context),
            ),

          // Related lists via ScreenBloc
          Expanded(
            child: BlocBuilder<ScreenSpecBloc, ScreenSpecState>(
              builder: (context, state) {
                return switch (state) {
                  ScreenSpecInitialState() ||
                  ScreenSpecLoadingState() => const LoadingStateWidget(),
                  ScreenSpecLoadedState(:final data) => _buildRelatedLists(
                    context,
                    data,
                    entityActionService,
                  ),
                  ScreenSpecErrorState(:final message) => ErrorStateWidget(
                    message: message,
                    onRetry: () => Navigator.of(context).pop(),
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedLists(
    BuildContext context,
    ScreenSpecData data,
    EntityActionService entityActionService,
  ) {
    final sections = [
      ...data.sections.header,
      ...data.sections.primary,
    ];

    if (sections.isEmpty) {
      return EmptyStateWidget.noTasks(
        title: context.l10n.emptyTasksTitle,
        description: 'No tasks or projects associated with this value.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Data updates automatically via reactive streams
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          for (final section in sections)
            SectionWidget(
              section: section,
              displayConfig: section.displayConfig,
              onEntityTap: (entity) {
                if (entity is Task) {
                  Routing.toEntity(
                    context,
                    EntityType.task,
                    entity.id,
                  );
                } else if (entity is Project) {
                  Routing.toEntity(
                    context,
                    EntityType.project,
                    entity.id,
                  );
                }
              },
              onTaskCheckboxChanged: (task, value) async {
                if (value ?? false) {
                  await entityActionService.completeTask(task.id);
                } else {
                  await entityActionService.uncompleteTask(task.id);
                }
              },
              onTaskDelete: (task) async {
                await entityActionService.deleteTask(task.id);
              },
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}
