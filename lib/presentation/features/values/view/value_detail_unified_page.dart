import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/value.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/services/screens/entity_action_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/values/view/value_detail_view.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/enhanced_value_card.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/entity_header.dart';
import 'package:taskly_bloc/presentation/widgets/error_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/loading_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';

/// Unified value detail page using the screen model.
///
/// Fetches the value first, then creates a dynamic ScreenDefinition
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
    // Create dynamic screen definition for this value
    final definition = SystemScreenDefinitions.forValue(
      valueId: value.id,
      valueName: value.name,
      valueColor: value.color,
    );

    return BlocProvider<ScreenBloc>(
      create: (context) => ScreenBloc(
        screenRepository: getIt(),
        interpreter: getIt<ScreenDataInterpreter>(),
      )..add(ScreenEvent.load(definition: definition)),
      child: _ValueScreenView(value: value),
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
  ValueStats? _valueStats;
  int _valueRank = 1;
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
      final settingsRepository = getIt<SettingsRepositoryContract>();

      // Load all required data in parallel
      final results = await Future.wait([
        analyticsService.getValueWeeklyTrends(weeks: 8),
        analyticsService.getValueActivityStats(),
        analyticsService.getRecentCompletionsByValue(days: 56),
        analyticsService.getTotalRecentCompletions(days: 56),
        settingsRepository.load(SettingsKey.valueRanking),
      ]);

      final weeklyTrends = results[0] as Map<String, List<double>>;
      final activityStats = results[1] as Map<String, ValueActivityStats>;
      final recentCompletions = results[2] as Map<String, int>;
      final totalRecentCompletions = results[3] as int;
      final valueRanking = results[4] as ValueRanking;

      // Calculate total weight for percentage calculation
      final totalWeight = valueRanking.items.fold<int>(
        0,
        (sum, item) => sum + item.weight,
      );

      // Find ranking item for this value
      final rankIndex = valueRanking.items.indexWhere(
        (item) => item.valueId == value.id,
      );
      final rankItem = rankIndex >= 0
          ? valueRanking.items[rankIndex]
          : ValueRankItem(valueId: value.id, weight: 5);

      // Calculate target percent from ranking weight
      final targetPercent = totalWeight > 0
          ? (rankItem.weight / totalWeight) * 100
          : 0.0;

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
          _valueStats = ValueStats(
            targetPercent: targetPercent,
            actualPercent: actualPercent,
            taskCount: activity.taskCount,
            projectCount: activity.projectCount,
            weeklyTrend: weeklyTrend,
            gapWarningThreshold: 15,
          );
          _valueRank = rankIndex >= 0 ? rankIndex + 1 : 0;
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
    unawaited(
      showDetailModal<void>(
        context: context,
        childBuilder: (modalSheetContext) => SafeArea(
          top: false,
          child: ValueDetailSheetPage(
            valueId: value.id,
            valueRepository: getIt<ValueRepositoryContract>(),
            onSaved: (savedValueId) {
              // Refresh the value details after edit
              context.read<ValueDetailBloc>().add(
                ValueDetailEvent.loadById(valueId: savedValueId),
              );
            },
          ),
        ),
        showDragHandle: true,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteValue),
        content: Text(
          'Are you sure you want to delete "${value.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.deleteValue),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
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
          // Entity header - use EnhancedValueCard for values
          if (_isLoadingStats)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            EnhancedValueCard(
              value: value,
              rank: _valueRank,
              stats: _valueStats,
              onTap: () => _showEditValueSheet(context),
              notRankedMessage: _valueRank == 0
                  ? l10n.notRankedDragToRank
                  : null,
            ),

          // Related lists via ScreenBloc
          Expanded(
            child: BlocBuilder<ScreenBloc, ScreenState>(
              builder: (context, state) {
                return switch (state) {
                  ScreenInitialState() ||
                  ScreenLoadingState() => const LoadingStateWidget(),
                  ScreenLoadedState(:final data) => _buildRelatedLists(
                    context,
                    data,
                    entityActionService,
                  ),
                  ScreenErrorState(:final message) => ErrorStateWidget(
                    message: message,
                    onRetry: () => context.read<ScreenBloc>().add(
                      const ScreenEvent.refresh(),
                    ),
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
    ScreenData data,
    EntityActionService entityActionService,
  ) {
    if (data.sections.isEmpty) {
      return EmptyStateWidget.noTasks(
        title: context.l10n.emptyTasksTitle,
        description: 'No tasks or projects associated with this value.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ScreenBloc>().add(const ScreenEvent.refresh());
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: data.sections.length,
        itemBuilder: (context, index) {
          final section = data.sections[index];
          return SectionWidget(
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
              if (context.mounted) {
                context.read<ScreenBloc>().add(const ScreenEvent.refresh());
              }
            },
            onTaskDelete: (task) async {
              await entityActionService.deleteTask(task.id);
              if (context.mounted) {
                context.read<ScreenBloc>().add(const ScreenEvent.refresh());
              }
            },
          );
        },
      ),
    );
  }
}
