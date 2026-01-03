import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/presentation/features/labels/bloc/label_list_bloc.dart';
import 'package:taskly_bloc/presentation/features/labels/widgets/add_label_fab.dart';
import 'package:taskly_bloc/presentation/features/labels/widgets/enhanced_value_card.dart';
import 'package:taskly_bloc/presentation/features/labels/widgets/value_detail_modal.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';

class ValueOverviewPage extends StatelessWidget {
  const ValueOverviewPage({
    required this.labelRepository,
    required this.settingsRepository,
    required this.pageKey,
    super.key,
  });

  final LabelRepositoryContract labelRepository;
  final SettingsRepositoryContract settingsRepository;
  final PageKey pageKey;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LabelOverviewBloc(
        labelRepository: labelRepository,
        typeFilter: LabelType.value,
        settingsRepository: settingsRepository,
        pageKey: pageKey,
      )..add(const LabelOverviewEvent.subscriptionRequested()),
      child: ValueOverviewView(
        labelRepository: labelRepository,
        settingsRepository: settingsRepository,
      ),
    );
  }
}

class ValueOverviewView extends StatefulWidget {
  const ValueOverviewView({
    required this.labelRepository,
    required this.settingsRepository,
    super.key,
  });

  final LabelRepositoryContract labelRepository;
  final SettingsRepositoryContract settingsRepository;

  @override
  State<ValueOverviewView> createState() => _ValueOverviewViewState();
}

class _ValueOverviewViewState extends State<ValueOverviewView> {
  late final ValueNotifier<bool> _isSheetOpen;
  Map<String, List<double>> _weeklyTrends = {};
  Map<String, ValueActivityStats> _activityStats = {};
  Map<String, int> _recentCompletions = {};
  int _totalRecentCompletions = 0;
  ValueRanking _valueRanking = const ValueRanking();
  int _unassignedTaskCount = 0;
  final int _unassignedProjectCount = 0;
  bool _isLoadingStats = true;

  // Display settings
  int _sparklineWeeks = 4;
  int _gapWarningThreshold = 15;

  @override
  void initState() {
    super.initState();
    _isSheetOpen = ValueNotifier<bool>(false);
    _loadDisplaySettings();
    _loadStats();
    _loadValueRanking();
  }

  @override
  void dispose() {
    _isSheetOpen.dispose();
    super.dispose();
  }

  Future<void> _loadDisplaySettings() async {
    final allocationConfig = await widget.settingsRepository.load(
      SettingsKey.allocation,
    );
    if (mounted) {
      setState(() {
        _sparklineWeeks = allocationConfig.displaySettings.sparklineWeeks;
        _gapWarningThreshold =
            allocationConfig.displaySettings.gapWarningThresholdPercent;
      });
      // Reload trends with new sparkline weeks
      await _loadStats();
    }
  }

  Future<void> _loadStats() async {
    final analyticsService = getIt<AnalyticsService>();
    try {
      final results = await Future.wait([
        analyticsService.getValueWeeklyTrends(weeks: _sparklineWeeks),
        analyticsService.getValueActivityStats(),
        analyticsService.getRecentCompletionsByValue(days: _sparklineWeeks * 7),
        analyticsService.getTotalRecentCompletions(days: _sparklineWeeks * 7),
        analyticsService.getOrphanTaskCount(),
      ]);

      if (mounted) {
        setState(() {
          _weeklyTrends = results[0] as Map<String, List<double>>;
          _activityStats = results[1] as Map<String, ValueActivityStats>;
          _recentCompletions = results[2] as Map<String, int>;
          _totalRecentCompletions = results[3] as int;
          _unassignedTaskCount = results[4] as int;
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

  Future<void> _loadValueRanking() async {
    final ranking = await widget.settingsRepository.load(
      SettingsKey.valueRanking,
    );
    if (mounted) {
      setState(() {
        _valueRanking = ranking;
      });
    }
  }

  void _showValueStatsModal(BuildContext context, Label value) {
    final stats = _buildStatsForValue(value);
    ValueDetailModal.show(context, value: value, stats: stats);
  }

  ValueStats _buildStatsForValue(Label value) {
    // Calculate target percent from ranking
    final rankItem = _valueRanking.items.firstWhere(
      (item) => item.labelId == value.id,
      orElse: () => ValueRankItem(labelId: value.id, weight: 5),
    );

    final totalWeight = _valueRanking.items.fold<int>(
      0,
      (sum, item) => sum + item.weight,
    );
    final targetPercent = totalWeight > 0
        ? (rankItem.weight / totalWeight) * 100
        : 0.0;

    // Calculate actual percent from recent completions
    final actualPercent = _totalRecentCompletions > 0
        ? ((_recentCompletions[value.id] ?? 0) / _totalRecentCompletions) * 100
        : 0.0;

    // Get weekly trend
    final weeklyTrend = _weeklyTrends[value.id] ?? [];

    // Get activity stats
    final activity =
        _activityStats[value.id] ??
        const ValueActivityStats(taskCount: 0, projectCount: 0);

    return ValueStats(
      targetPercent: targetPercent,
      actualPercent: actualPercent,
      taskCount: activity.taskCount,
      projectCount: activity.projectCount,
      weeklyTrend: weeklyTrend,
      gapWarningThreshold: _gapWarningThreshold,
    );
  }

  Future<void> _onReorder(
    int oldIndex,
    int newIndex,
    List<Label> labels,
  ) async {
    // Adjust for removal
    var adjustedNewIndex = newIndex;
    if (newIndex > oldIndex) adjustedNewIndex--;

    final values = List<Label>.from(labels);
    final item = values.removeAt(oldIndex);
    values.insert(adjustedNewIndex, item);

    // Auto-calculate weights based on position (rank-based decay)
    final n = values.length;
    final triangularNumber = n * (n + 1) ~/ 2; // Sum of 1..n

    final updatedItems = <ValueRankItem>[];
    for (var i = 0; i < n; i++) {
      final rank = i + 1;
      // Weight is n - rank + 1 for rank-based decay, scaled to 1-10
      final rawWeight = (n - rank + 1) / triangularNumber;
      final scaledWeight = (rawWeight * 9).round() + 1; // Scale to 1-10

      updatedItems.add(
        ValueRankItem(
          labelId: values[i].id,
          weight: scaledWeight,
          sortOrder: i,
        ),
      );
    }

    final newRanking = ValueRanking(items: updatedItems);

    // Save to settings
    await widget.settingsRepository.save(
      SettingsKey.valueRanking,
      newRanking,
    );

    if (mounted) {
      setState(() {
        _valueRanking = newRanking;
      });
    }
  }

  List<Label> _sortLabelsByRanking(List<Label> labels) {
    if (_valueRanking.items.isEmpty) return labels;

    final sorted = List<Label>.from(labels);
    sorted.sort((a, b) {
      final aItem = _valueRanking.items.firstWhere(
        (item) => item.labelId == a.id,
        orElse: () => ValueRankItem(labelId: a.id, sortOrder: 999),
      );
      final bItem = _valueRanking.items.firstWhere(
        (item) => item.labelId == b.id,
        orElse: () => ValueRankItem(labelId: b.id, sortOrder: 999),
      );
      return aItem.sortOrder.compareTo(bItem.sortOrder);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<LabelOverviewBloc, LabelOverviewState>(
      builder: (context, state) {
        return state.when(
          initial: () => const Center(child: CircularProgressIndicator()),
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (labels) {
            final sortedLabels = _sortLabelsByRanking(labels);

            return Scaffold(
              appBar: AppBar(
                title: Text(l10n.labelTypeValueHeading),
              ),
              body: labels.isEmpty
                  ? EmptyStateWidget.noValues(
                      title: l10n.noValuesFound,
                    )
                  : _isLoadingStats
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(context, sortedLabels),
              floatingActionButton: AddLabelFab(
                labelRepository: widget.labelRepository,
                initialType: LabelType.value,
                lockType: true,
                tooltip: l10n.createValueOption,
                heroTag: 'create_value_fab',
              ),
            );
          },
          error: (error, stackTrace) => Center(
            child: Text(
              friendlyErrorMessageForUi(error, l10n),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, List<Label> labels) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: labels.length + 1, // +1 for unassigned section
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < labels.length && newIndex <= labels.length) {
          unawaited(_onReorder(oldIndex, newIndex, labels));
        }
      },
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        // Unassigned section at the bottom
        if (index == labels.length) {
          return _UnassignedSection(
            key: const ValueKey('unassigned'),
            taskCount: _unassignedTaskCount,
            projectCount: _unassignedProjectCount,
            colorScheme: colorScheme,
            l10n: l10n,
          );
        }

        final label = labels[index];
        final stats = _buildStatsForValue(label);
        final rank = index + 1;

        return EnhancedValueCard(
          key: ValueKey(label.id),
          value: label,
          stats: stats,
          rank: rank,
          onTap: () => _showValueStatsModal(context, label),
        );
      },
    );
  }
}

class _UnassignedSection extends StatelessWidget {
  const _UnassignedSection({
    required this.taskCount,
    required this.projectCount,
    required this.colorScheme,
    required this.l10n,
    super.key,
  });

  final int taskCount;
  final int projectCount;
  final ColorScheme colorScheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.inbox, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.unassignedWorkTitle,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  l10n.valueActivityCounts(taskCount, projectCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
