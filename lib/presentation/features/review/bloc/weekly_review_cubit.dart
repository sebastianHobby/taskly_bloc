import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/settings.dart';

class WeeklyReviewConfig {
  WeeklyReviewConfig({
    required this.valuesSummaryEnabled,
    required this.valuesWindowWeeks,
    required this.valueWinsCount,
    required this.maintenanceEnabled,
    required this.showDeadlineRisk,
    required this.showDueSoonUnderControl,
    required this.showStaleItems,
    required this.showFrequentSnoozed,
  });

  factory WeeklyReviewConfig.fromSettings(GlobalSettings settings) {
    return WeeklyReviewConfig(
      valuesSummaryEnabled: settings.valuesSummaryEnabled,
      valuesWindowWeeks: settings.valuesSummaryWindowWeeks,
      valueWinsCount: settings.valuesSummaryWinsCount,
      maintenanceEnabled: settings.maintenanceEnabled,
      showDeadlineRisk: settings.maintenanceDeadlineRiskEnabled,
      showDueSoonUnderControl: settings.maintenanceDueSoonEnabled,
      showStaleItems: settings.maintenanceStaleEnabled,
      showFrequentSnoozed: settings.maintenanceFrequentSnoozedEnabled,
    );
  }

  final bool valuesSummaryEnabled;
  final int valuesWindowWeeks;
  final int valueWinsCount;
  final bool maintenanceEnabled;
  final bool showDeadlineRisk;
  final bool showDueSoonUnderControl;
  final bool showStaleItems;
  final bool showFrequentSnoozed;
}

enum WeeklyReviewStatus { loading, ready, failure }

class WeeklyReviewValueRing {
  const WeeklyReviewValueRing({
    required this.value,
    required this.percent,
  });

  final Value value;
  final double percent;
}

class WeeklyReviewValuesSummary {
  const WeeklyReviewValuesSummary({
    required this.rings,
    required this.topValueName,
    required this.bottomValueName,
    required this.hasData,
  });

  final List<WeeklyReviewValueRing> rings;
  final String? topValueName;
  final String? bottomValueName;
  final bool hasData;
}

class WeeklyReviewValueWin {
  const WeeklyReviewValueWin({
    required this.valueName,
    required this.completionCount,
  });

  final String valueName;
  final int completionCount;
}

class WeeklyReviewMaintenanceItem {
  const WeeklyReviewMaintenanceItem({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

class WeeklyReviewMaintenanceSection {
  const WeeklyReviewMaintenanceSection({
    required this.id,
    required this.title,
    required this.emptyMessage,
    required this.items,
  });

  final String id;
  final String title;
  final String emptyMessage;
  final List<WeeklyReviewMaintenanceItem> items;
}

class WeeklyReviewState {
  const WeeklyReviewState({
    this.status = WeeklyReviewStatus.loading,
    this.valuesSummary,
    this.valueWins = const [],
    this.maintenanceSections = const [],
    this.errorMessage,
  });

  final WeeklyReviewStatus status;
  final WeeklyReviewValuesSummary? valuesSummary;
  final List<WeeklyReviewValueWin> valueWins;
  final List<WeeklyReviewMaintenanceSection> maintenanceSections;
  final String? errorMessage;

  WeeklyReviewState copyWith({
    WeeklyReviewStatus? status,
    WeeklyReviewValuesSummary? valuesSummary,
    List<WeeklyReviewValueWin>? valueWins,
    List<WeeklyReviewMaintenanceSection>? maintenanceSections,
    String? errorMessage,
  }) {
    return WeeklyReviewState(
      status: status ?? this.status,
      valuesSummary: valuesSummary ?? this.valuesSummary,
      valueWins: valueWins ?? this.valueWins,
      maintenanceSections: maintenanceSections ?? this.maintenanceSections,
      errorMessage: errorMessage,
    );
  }
}

class WeeklyReviewCubit extends Cubit<WeeklyReviewState> {
  WeeklyReviewCubit({
    required AnalyticsService analyticsService,
    required AttentionEngineContract attentionEngine,
    required ValueRepositoryContract valueRepository,
  }) : _analyticsService = analyticsService,
       _attentionEngine = attentionEngine,
       _valueRepository = valueRepository,
       super(const WeeklyReviewState());

  final AnalyticsService _analyticsService;
  final AttentionEngineContract _attentionEngine;
  final ValueRepositoryContract _valueRepository;
  StreamSubscription<List<AttentionItem>>? _maintenanceSub;

  Future<void> load(WeeklyReviewConfig config) async {
    emit(state.copyWith(status: WeeklyReviewStatus.loading));

    try {
      final summary = config.valuesSummaryEnabled
          ? await _buildValuesSummary(config)
          : null;
      final wins = config.valuesSummaryEnabled
          ? await _buildValueWins(config)
          : const <WeeklyReviewValueWin>[];

      if (isClosed) return;

      emit(
        state.copyWith(
          status: WeeklyReviewStatus.ready,
          valuesSummary: summary,
          valueWins: wins,
          maintenanceSections: config.maintenanceEnabled
              ? const <WeeklyReviewMaintenanceSection>[]
              : _emptyMaintenanceSections(config),
          errorMessage: null,
        ),
      );

      await _maintenanceSub?.cancel();
      if (!config.maintenanceEnabled) return;

      _maintenanceSub = _attentionEngine
          .watch(const AttentionQuery(buckets: {AttentionBucket.action}))
          .listen(
            (items) {
              if (isClosed) return;
              final sections = _buildMaintenanceSections(items, config);
              emit(state.copyWith(maintenanceSections: sections));
            },
            onError: (Object error, StackTrace _) {
              if (isClosed) return;
              emit(
                state.copyWith(
                  status: WeeklyReviewStatus.failure,
                  errorMessage: '$error',
                ),
              );
            },
          );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: WeeklyReviewStatus.failure,
          errorMessage: '$e',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _maintenanceSub?.cancel();
    return super.close();
  }

  Future<WeeklyReviewValuesSummary> _buildValuesSummary(
    WeeklyReviewConfig config,
  ) async {
    final values = await _valueRepository.getAll();
    if (values.isEmpty) {
      return const WeeklyReviewValuesSummary(
        rings: [],
        topValueName: null,
        bottomValueName: null,
        hasData: false,
      );
    }

    final weeks = config.valuesWindowWeeks.clamp(1, 12);
    final days = weeks * 7;
    final completions = await _analyticsService.getRecentCompletionsByValue(
      days: days,
    );

    final total = completions.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) {
      return const WeeklyReviewValuesSummary(
        rings: [],
        topValueName: null,
        bottomValueName: null,
        hasData: false,
      );
    }

    final entries =
        values
            .map((value) {
              final count = completions[value.id] ?? 0;
              final percent = total == 0 ? 0.0 : count / total * 100;
              return WeeklyReviewValueRing(
                value: value,
                percent: percent,
              );
            })
            .toList(growable: false)
          ..sort((a, b) => b.percent.compareTo(a.percent));

    final topValue = entries.isEmpty ? null : entries.first.value.name;
    final bottomValue = entries.isEmpty ? null : entries.last.value.name;
    final rings = entries.take(5).toList(growable: false);

    return WeeklyReviewValuesSummary(
      rings: rings,
      topValueName: topValue,
      bottomValueName: bottomValue,
      hasData: true,
    );
  }

  Future<List<WeeklyReviewValueWin>> _buildValueWins(
    WeeklyReviewConfig config,
  ) async {
    final values = await _valueRepository.getAll();
    if (values.isEmpty) return const <WeeklyReviewValueWin>[];

    final weeks = config.valuesWindowWeeks.clamp(1, 12);
    final days = weeks * 7;
    final completions = await _analyticsService.getRecentCompletionsByValue(
      days: days,
    );

    if (completions.isEmpty) return const <WeeklyReviewValueWin>[];

    final valueById = {for (final v in values) v.id: v};

    final ranked = completions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxCount = config.valueWinsCount.clamp(1, 5);

    return ranked
        .where((entry) => entry.value > 0)
        .take(maxCount)
        .map((entry) {
          final valueName = valueById[entry.key]?.name ?? 'Value';
          return WeeklyReviewValueWin(
            valueName: valueName,
            completionCount: entry.value,
          );
        })
        .toList(growable: false);
  }

  List<WeeklyReviewMaintenanceSection> _buildMaintenanceSections(
    List<AttentionItem> items,
    WeeklyReviewConfig config,
  ) {
    final sections = <WeeklyReviewMaintenanceSection>[];

    if (config.showDeadlineRisk) {
      final riskItems = items.where(
        (i) => i.ruleKey == 'problem_project_deadline_risk',
      );
      sections.add(
        WeeklyReviewMaintenanceSection(
          id: 'deadline-risk',
          title: 'Deadline Risk',
          emptyMessage: 'No deadline risks this week.',
          items: riskItems.map(_mapDeadlineRiskItem).toList(growable: false),
        ),
      );
    }

    if (config.showDueSoonUnderControl) {
      sections.add(
        const WeeklyReviewMaintenanceSection(
          id: 'due-soon-under-control',
          title: 'Due Soon (Under Control)',
          emptyMessage: 'No upcoming projects need a check-in.',
          items: [],
        ),
      );
    }

    if (config.showStaleItems) {
      final staleItems = [
        ...items.where((i) => i.ruleKey == 'problem_task_stale'),
        ...items.where((i) => i.ruleKey == 'problem_project_idle'),
      ];
      sections.add(
        WeeklyReviewMaintenanceSection(
          id: 'stale-items',
          title: 'Stale Tasks & Projects',
          emptyMessage: 'No stale items right now.',
          items: staleItems.map(_mapStaleItem).toList(growable: false),
        ),
      );
    }

    if (config.showFrequentSnoozed) {
      sections.add(
        const WeeklyReviewMaintenanceSection(
          id: 'frequently-snoozed',
          title: 'Frequently Snoozed',
          emptyMessage: 'No items are stuck in a snooze loop.',
          items: [],
        ),
      );
    }

    return sections;
  }

  WeeklyReviewMaintenanceItem _mapDeadlineRiskItem(AttentionItem item) {
    final name =
        item.metadata?['project_name'] as String? ??
        item.metadata?['entity_display_name'] as String? ??
        'Project';
    final dueInDays = item.metadata?['due_in_days'] as int?;
    final unscheduled = item.metadata?['unscheduled_tasks_count'] as int? ?? 0;

    final dueLabel = switch (dueInDays) {
      null => 'due soon',
      0 => 'due today',
      1 => 'due tomorrow',
      < 0 => 'overdue by ${dueInDays.abs()} days',
      _ => 'due in $dueInDays days',
    };

    return WeeklyReviewMaintenanceItem(
      title: name,
      description: 'Project is $dueLabel with $unscheduled unscheduled tasks.',
    );
  }

  WeeklyReviewMaintenanceItem _mapStaleItem(AttentionItem item) {
    final name =
        item.metadata?['task_name'] as String? ??
        item.metadata?['project_name'] as String? ??
        item.metadata?['entity_display_name'] as String? ??
        'Item';

    return WeeklyReviewMaintenanceItem(
      title: name,
      description: 'No activity in 30 days.',
    );
  }

  List<WeeklyReviewMaintenanceSection> _emptyMaintenanceSections(
    WeeklyReviewConfig config,
  ) {
    return _buildMaintenanceSections(const [], config);
  }
}
