import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/time.dart';

sealed class RoutineDetailSupportEvent {
  const RoutineDetailSupportEvent();
}

final class RoutineDetailSupportStarted extends RoutineDetailSupportEvent {
  const RoutineDetailSupportStarted();
}

final class RoutineDetailSupportIfThenSaved extends RoutineDetailSupportEvent {
  const RoutineDetailSupportIfThenSaved({
    required this.ifText,
    required this.thenText,
    this.note,
    this.source = 'routine_detail',
  });

  final String ifText;
  final String thenText;
  final String? note;
  final String source;
}

final class RoutineDetailSupportOutcomeRecorded
    extends RoutineDetailSupportEvent {
  const RoutineDetailSupportOutcomeRecorded({
    required this.planResolutionId,
    required this.outcome,
    this.source = 'routine_detail',
  });

  final String planResolutionId;
  final String outcome;
  final String source;
}

enum RoutineDetailSupportStatus { loading, ready, failure }

class RoutineSupportPlanHistory {
  const RoutineSupportPlanHistory({
    required this.id,
    required this.ifText,
    required this.thenText,
    required this.createdAt,
    this.note,
    this.outcome,
  });

  final String id;
  final String ifText;
  final String thenText;
  final String? note;
  final String? outcome;
  final DateTime createdAt;
}

class RoutineDetailSupportState {
  const RoutineDetailSupportState({
    this.status = RoutineDetailSupportStatus.loading,
    this.routine,
    this.snapshot,
    this.supportItem,
    this.weeklyAdherence = const <double>[],
    this.strengthScore = 0,
    this.strengthDelta = 0,
    this.planHistory = const <RoutineSupportPlanHistory>[],
    this.prefillPlan,
    this.pendingOutcomePlanId,
    this.error,
  });

  final RoutineDetailSupportStatus status;
  final Routine? routine;
  final RoutineCadenceSnapshot? snapshot;
  final AttentionItem? supportItem;
  final List<double> weeklyAdherence;
  final int strengthScore;
  final int strengthDelta;
  final List<RoutineSupportPlanHistory> planHistory;
  final RoutineSupportPlanHistory? prefillPlan;
  final String? pendingOutcomePlanId;
  final Object? error;

  RoutineDetailSupportState copyWith({
    RoutineDetailSupportStatus? status,
    Routine? routine,
    RoutineCadenceSnapshot? snapshot,
    AttentionItem? supportItem,
    List<double>? weeklyAdherence,
    int? strengthScore,
    int? strengthDelta,
    List<RoutineSupportPlanHistory>? planHistory,
    RoutineSupportPlanHistory? prefillPlan,
    String? pendingOutcomePlanId,
    Object? error,
  }) {
    return RoutineDetailSupportState(
      status: status ?? this.status,
      routine: routine ?? this.routine,
      snapshot: snapshot ?? this.snapshot,
      supportItem: supportItem ?? this.supportItem,
      weeklyAdherence: weeklyAdherence ?? this.weeklyAdherence,
      strengthScore: strengthScore ?? this.strengthScore,
      strengthDelta: strengthDelta ?? this.strengthDelta,
      planHistory: planHistory ?? this.planHistory,
      prefillPlan: prefillPlan ?? this.prefillPlan,
      pendingOutcomePlanId: pendingOutcomePlanId ?? this.pendingOutcomePlanId,
      error: error,
    );
  }
}

class RoutineDetailSupportBloc
    extends Bloc<RoutineDetailSupportEvent, RoutineDetailSupportState> {
  RoutineDetailSupportBloc({
    required String routineId,
    required RoutineRepositoryContract routineRepository,
    required AttentionEngineContract attentionEngine,
    required AttentionRepositoryContract attentionRepository,
    required AttentionResolutionService attentionResolutionService,
    required NowService nowService,
    RoutineScheduleService scheduleService = const RoutineScheduleService(),
  }) : _routineId = routineId,
       _routineRepository = routineRepository,
       _attentionEngine = attentionEngine,
       _attentionRepository = attentionRepository,
       _attentionResolutionService = attentionResolutionService,
       _nowService = nowService,
       _scheduleService = scheduleService,
       super(const RoutineDetailSupportState()) {
    on<RoutineDetailSupportStarted>(_onStarted, transformer: restartable());
    on<RoutineDetailSupportIfThenSaved>(
      _onIfThenSaved,
      transformer: sequential(),
    );
    on<RoutineDetailSupportOutcomeRecorded>(
      _onOutcomeRecorded,
      transformer: sequential(),
    );
  }

  final String _routineId;
  final RoutineRepositoryContract _routineRepository;
  final AttentionEngineContract _attentionEngine;
  final AttentionRepositoryContract _attentionRepository;
  final AttentionResolutionService _attentionResolutionService;
  final NowService _nowService;
  final RoutineScheduleService _scheduleService;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  Future<void> _onStarted(
    RoutineDetailSupportStarted event,
    Emitter<RoutineDetailSupportState> emit,
  ) async {
    emit(
      const RoutineDetailSupportState(
        status: RoutineDetailSupportStatus.loading,
      ),
    );

    final routine$ = _routineRepository.watchById(_routineId);
    final completions$ = _routineRepository.watchCompletions();
    final skips$ = _routineRepository.watchSkips();
    final attention$ = _attentionEngine.watch(
      const AttentionQuery(
        buckets: {AttentionBucket.action},
        entityTypes: {AttentionEntityType.routine},
      ),
    );
    final resolutions$ = _attentionRepository.watchResolutionsForEntity(
      _routineId,
      AttentionEntityType.routine,
    );

    final combined$ =
        Rx.combineLatest5<
          Routine?,
          List<RoutineCompletion>,
          List<RoutineSkip>,
          List<AttentionItem>,
          List<AttentionResolution>,
          RoutineDetailSupportState
        >(routine$, completions$, skips$, attention$, resolutions$, (
          routine,
          completions,
          skips,
          attentionItems,
          resolutions,
        ) {
          if (routine == null) {
            return const RoutineDetailSupportState(
              status: RoutineDetailSupportStatus.failure,
              error: 'routine_not_found',
            );
          }

          final nowUtc = _nowService.nowUtc();
          final dayKey = dateOnly(nowUtc);
          final snapshot = _scheduleService.buildSnapshot(
            routine: routine,
            dayKeyUtc: dayKey,
            completions: completions,
            skips: skips,
          );
          final weekly = _weeklyAdherence(
            routine: routine,
            completions: completions,
            nowDay: dayKey,
            weeks: 8,
          );
          final strength = _strengthScore(weekly);
          final delta = _strengthDelta(weekly);
          final supportItem = attentionItems
              .where((item) => item.ruleKey == 'problem_routine_support')
              .where((item) => item.entityId == routine.id)
              .cast<AttentionItem?>()
              .firstWhere((_) => true, orElse: () => null);
          final history = _parsePlanHistory(resolutions);
          final prefill = history.firstWhere(
            (plan) => plan.outcome == 'helped',
            orElse: () => RoutineSupportPlanHistory(
              id: '',
              ifText: '',
              thenText: '',
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          );
          final resolvedPrefill = prefill.id.isEmpty ? null : prefill;
          final pendingOutcomePlan = history
              .where((plan) => plan.outcome == null)
              .cast<RoutineSupportPlanHistory?>()
              .firstWhere((_) => true, orElse: () => null);
          final pendingOutcomePlanId =
              pendingOutcomePlan != null &&
                  dayKey
                          .difference(dateOnly(pendingOutcomePlan.createdAt))
                          .inDays >=
                      7
              ? pendingOutcomePlan.id
              : null;

          return RoutineDetailSupportState(
            status: RoutineDetailSupportStatus.ready,
            routine: routine,
            snapshot: snapshot,
            supportItem: supportItem,
            weeklyAdherence: weekly,
            strengthScore: strength,
            strengthDelta: delta,
            planHistory: history.take(3).toList(growable: false),
            prefillPlan: resolvedPrefill,
            pendingOutcomePlanId: pendingOutcomePlanId,
          );
        });

    await emit.forEach<RoutineDetailSupportState>(
      combined$,
      onData: (next) => next,
      onError: (error, _) => RoutineDetailSupportState(
        status: RoutineDetailSupportStatus.failure,
        error: error,
      ),
    );
  }

  Future<void> _onIfThenSaved(
    RoutineDetailSupportIfThenSaved event,
    Emitter<RoutineDetailSupportState> emit,
  ) async {
    final item = state.supportItem;
    if (item == null) return;
    final nowUtc = _nowService.nowUtc();
    final context = _contextFactory.create(
      feature: 'routines',
      screen: 'routine_detail',
      intent: 'routine_support_if_then_saved',
      operation: 'attention.resolution.reviewed',
      entityType: 'routine',
      entityId: _routineId,
      extraFields: <String, Object?>{
        'planType': 'if_then',
        'source': event.source,
      },
    );
    await _attentionResolutionService.recordReviewedWithDetails(
      item: item,
      nowUtc: nowUtc,
      actionDetails: <String, dynamic>{
        'kind': 'support_plan',
        'plan_type': 'if_then',
        'if_text': event.ifText,
        'then_text': event.thenText,
        'note': event.note,
        'source': event.source,
      },
      context: context,
    );
  }

  Future<void> _onOutcomeRecorded(
    RoutineDetailSupportOutcomeRecorded event,
    Emitter<RoutineDetailSupportState> emit,
  ) async {
    final item = state.supportItem;
    if (item == null) return;
    final nowUtc = _nowService.nowUtc();
    final context = _contextFactory.create(
      feature: 'routines',
      screen: 'routine_detail',
      intent: 'routine_support_outcome_recorded',
      operation: 'attention.resolution.reviewed',
      entityType: 'routine',
      entityId: _routineId,
      extraFields: <String, Object?>{
        'outcome': event.outcome,
        'source': event.source,
      },
    );
    await _attentionResolutionService.recordReviewedWithDetails(
      item: item,
      nowUtc: nowUtc,
      actionDetails: <String, dynamic>{
        'kind': 'support_plan_outcome',
        'plan_resolution_id': event.planResolutionId,
        'outcome': event.outcome,
        'source': event.source,
      },
      context: context,
    );
  }

  List<RoutineSupportPlanHistory> _parsePlanHistory(
    List<AttentionResolution> resolutions,
  ) {
    final plans = <String, RoutineSupportPlanHistory>{};
    final outcomes = <String, String>{};
    final sorted = resolutions.toList(growable: false)
      ..sort((a, b) => b.resolvedAt.compareTo(a.resolvedAt));

    for (final resolution in sorted) {
      final details = resolution.actionDetails ?? const <String, dynamic>{};
      if (details['kind'] == 'support_plan_outcome') {
        final planId = details['plan_resolution_id'] as String?;
        final outcome = details['outcome'] as String?;
        if (planId != null &&
            planId.trim().isNotEmpty &&
            outcome != null &&
            outcome.trim().isNotEmpty) {
          outcomes.putIfAbsent(planId, () => outcome);
        }
        continue;
      }

      if (details['kind'] != 'support_plan') continue;
      final ifText = details['if_text'] as String?;
      final thenText = details['then_text'] as String?;
      if (ifText == null || thenText == null) continue;
      plans.putIfAbsent(
        resolution.id,
        () => RoutineSupportPlanHistory(
          id: resolution.id,
          ifText: ifText,
          thenText: thenText,
          note: details['note'] as String?,
          createdAt: resolution.resolvedAt,
        ),
      );
    }

    final merged =
        plans.values
            .map((plan) {
              return RoutineSupportPlanHistory(
                id: plan.id,
                ifText: plan.ifText,
                thenText: plan.thenText,
                note: plan.note,
                createdAt: plan.createdAt,
                outcome: outcomes[plan.id],
              );
            })
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return merged;
  }

  List<double> _weeklyAdherence({
    required Routine routine,
    required List<RoutineCompletion> completions,
    required DateTime nowDay,
    required int weeks,
  }) {
    final safeWeeks = weeks < 1 ? 1 : weeks;
    final series = <double>[];
    final weekStart = nowDay.subtract(
      Duration(days: nowDay.weekday - DateTime.monday),
    );
    for (var i = safeWeeks - 1; i >= 0; i--) {
      final start = weekStart.subtract(Duration(days: i * 7));
      final end = start.add(const Duration(days: 6));
      final actual = completions.where((completion) {
        if (completion.routineId != routine.id) return false;
        final day = dateOnly(
          completion.completedDayLocal ?? completion.completedAtUtc,
        );
        return !(day.isBefore(start) || day.isAfter(end));
      }).length;
      final expected = _expectedForDays(routine: routine, days: 7);
      series.add(
        expected <= 0 ? 0 : (actual / expected * 100).clamp(0, 200).toDouble(),
      );
    }
    return series;
  }

  int _expectedForDays({required Routine routine, required int days}) {
    if (days <= 0) return 0;
    return switch (routine.periodType) {
      RoutinePeriodType.day => routine.targetCount * days,
      RoutinePeriodType.week => ((routine.targetCount / 7) * days).round(),
      RoutinePeriodType.fortnight =>
        ((routine.targetCount / 14) * days).round(),
      RoutinePeriodType.month => ((routine.targetCount / 30) * days).round(),
    };
  }

  int _strengthScore(List<double> weeklyAdherence) {
    if (weeklyAdherence.isEmpty) return 0;
    final latest4 = weeklyAdherence.length <= 4
        ? weeklyAdherence
        : weeklyAdherence.sublist(weeklyAdherence.length - 4);
    final avg = latest4.reduce((a, b) => a + b) / latest4.length;
    return avg.clamp(0, 100).round();
  }

  int _strengthDelta(List<double> weeklyAdherence) {
    if (weeklyAdherence.length < 8) return 0;
    final latest = weeklyAdherence.sublist(weeklyAdherence.length - 4);
    final prior = weeklyAdherence.sublist(
      weeklyAdherence.length - 8,
      weeklyAdherence.length - 4,
    );
    final latestAvg = latest.reduce((a, b) => a + b) / latest.length;
    final priorAvg = prior.reduce((a, b) => a + b) / prior.length;
    return (latestAvg - priorAvg).round();
  }
}
