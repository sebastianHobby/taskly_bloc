import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/routines/bloc/routine_detail_support_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class RoutineDetailPage extends StatelessWidget {
  const RoutineDetailPage({
    required this.routineId,
    this.openIfThenComposer = false,
    super.key,
  });

  final String routineId;
  final bool openIfThenComposer;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RoutineDetailSupportBloc(
        routineId: routineId,
        routineRepository: context.read<RoutineRepositoryContract>(),
        attentionEngine: context.read<AttentionEngineContract>(),
        attentionRepository: context.read<AttentionRepositoryContract>(),
        attentionResolutionService: context.read<AttentionResolutionService>(),
        nowService: context.read<NowService>(),
      )..add(const RoutineDetailSupportStarted()),
      child: _RoutineDetailView(
        routineId: routineId,
        openIfThenComposer: openIfThenComposer,
      ),
    );
  }
}

class _RoutineDetailView extends StatefulWidget {
  const _RoutineDetailView({
    required this.routineId,
    required this.openIfThenComposer,
  });

  final String routineId;
  final bool openIfThenComposer;

  @override
  State<_RoutineDetailView> createState() => _RoutineDetailViewState();
}

class _RoutineDetailViewState extends State<_RoutineDetailView> {
  bool _composerOpenedFromRoute = false;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.myDayBadgeRoutine),
        actions: [
          IconButton(
            tooltip: context.l10n.routineEditLabel,
            onPressed: () => Routing.toRoutineEdit(context, widget.routineId),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: BlocBuilder<RoutineDetailSupportBloc, RoutineDetailSupportState>(
        builder: (context, state) {
          if (state.status == RoutineDetailSupportStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == RoutineDetailSupportStatus.failure ||
              state.routine == null ||
              state.snapshot == null) {
            return Center(
              child: Text(context.l10n.routineNotFound),
            );
          }

          if (widget.openIfThenComposer &&
              !_composerOpenedFromRoute &&
              state.supportItem != null) {
            _composerOpenedFromRoute = true;
            unawaited(_showIfThenComposer(context, state: state));
          }

          final routine = state.routine!;
          final snapshot = state.snapshot!;

          return ListView(
            padding: EdgeInsets.all(tokens.spaceLg),
            children: [
              Text(
                routine.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.spaceXxs2),
              Text(
                '${routine.periodType.name} · ${routine.scheduleMode.name} · ${context.l10n.routineRemaining(snapshot.remainingCount)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.spaceLg),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trajectory',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: tokens.spaceSm),
                    Row(
                      children: [
                        Text(
                          'Strength ${state.strengthScore}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(width: tokens.spaceSm),
                        Text(
                          state.strengthDelta >= 0
                              ? 'up +${state.strengthDelta}'
                              : 'down ${state.strengthDelta}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: state.strengthDelta >= 0
                                    ? scheme.primary
                                    : scheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: tokens.spaceSm),
                    Wrap(
                      spacing: tokens.spaceXs2,
                      children: [
                        for (final value in state.weeklyAdherence)
                          Container(
                            width: 26,
                            padding: EdgeInsets.symmetric(
                              vertical: tokens.spaceXxs2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                tokens.radiusSm,
                              ),
                            ),
                            child: Text(
                              value.toStringAsFixed(0),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: tokens.spaceSm),
              if (state.supportItem != null)
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Behavior support',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: tokens.spaceSm),
                      Text(
                        'Small changes restore momentum. Tune this routine for this week.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: tokens.spaceSm),
                      if (_suggestionLine(state.supportItem!) != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: tokens.spaceSm),
                          child: Text(
                            _suggestionLine(state.supportItem!)!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      Wrap(
                        spacing: tokens.spaceSm,
                        runSpacing: tokens.spaceSm,
                        children: [
                          FilledButton.tonal(
                            onPressed: () => _showIfThenComposer(
                              context,
                              state: state,
                            ),
                            child: const Text('Create if-then plan'),
                          ),
                          OutlinedButton(
                            onPressed: () => Routing.toRoutineEdit(
                              context,
                              widget.routineId,
                            ),
                            child: const Text('Reschedule one day'),
                          ),
                          OutlinedButton(
                            onPressed: () => Routing.toRoutineEdit(
                              context,
                              widget.routineId,
                            ),
                            child: const Text('Lower target 1 week'),
                          ),
                        ],
                      ),
                      if (state.pendingOutcomePlanId != null) ...[
                        SizedBox(height: tokens.spaceSm),
                        Text(
                          'Did your last plan help?',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        SizedBox(height: tokens.spaceXxs2),
                        Wrap(
                          spacing: tokens.spaceSm,
                          children: [
                            _OutcomeButton(
                              label: 'Helped',
                              onTap: () => _recordOutcome(
                                context,
                                planId: state.pendingOutcomePlanId!,
                                outcome: 'helped',
                              ),
                            ),
                            _OutcomeButton(
                              label: 'Somewhat',
                              onTap: () => _recordOutcome(
                                context,
                                planId: state.pendingOutcomePlanId!,
                                outcome: 'somewhat',
                              ),
                            ),
                            _OutcomeButton(
                              label: 'Not',
                              onTap: () => _recordOutcome(
                                context,
                                planId: state.pendingOutcomePlanId!,
                                outcome: 'not',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              if (state.planHistory.isNotEmpty) ...[
                SizedBox(height: tokens.spaceSm),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent support plans',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: tokens.spaceSm),
                      for (final plan in state.planHistory) ...[
                        Text('If ${plan.ifText} -> ${plan.thenText}'),
                        if ((plan.note ?? '').trim().isNotEmpty)
                          Text(
                            plan.note!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        Text(
                          plan.outcome == null
                              ? 'Outcome pending'
                              : 'Outcome: ${plan.outcome}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        if (plan != state.planHistory.last)
                          Divider(height: tokens.spaceLg),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _showIfThenComposer(
    BuildContext context, {
    required RoutineDetailSupportState state,
  }) async {
    final prefill = state.prefillPlan;
    final ifController = TextEditingController(text: prefill?.ifText ?? '');
    final thenController = TextEditingController(text: prefill?.thenText ?? '');
    final noteController = TextEditingController(text: prefill?.note ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final tokens = TasklyTokens.of(context);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            tokens.spaceLg + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'If-Then plan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.spaceSm),
              TextField(
                controller: ifController,
                decoration: const InputDecoration(labelText: 'When'),
              ),
              SizedBox(height: tokens.spaceSm),
              TextField(
                controller: thenController,
                decoration: const InputDecoration(labelText: 'Then'),
              ),
              SizedBox(height: tokens.spaceSm),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              SizedBox(height: tokens.spaceSm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    if (ifController.text.trim().isEmpty ||
                        thenController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Save plan'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if ((saved ?? false) && context.mounted) {
      context.read<RoutineDetailSupportBloc>().add(
        RoutineDetailSupportIfThenSaved(
          ifText: ifController.text.trim(),
          thenText: thenController.text.trim(),
          note: noteController.text.trim().isEmpty
              ? null
              : noteController.text.trim(),
        ),
      );
    }
    ifController.dispose();
    thenController.dispose();
    noteController.dispose();
  }

  void _recordOutcome(
    BuildContext context, {
    required String planId,
    required String outcome,
  }) {
    context.read<RoutineDetailSupportBloc>().add(
      RoutineDetailSupportOutcomeRecorded(
        planResolutionId: planId,
        outcome: outcome,
      ),
    );
  }

  String? _suggestionLine(AttentionItem item) {
    final fromDay = item.metadata?['most_missed_weekday'] as int?;
    final toDay = item.metadata?['most_success_weekday'] as int?;
    if (fromDay == null || toDay == null) return null;
    return 'Suggestion: move one session from weekday $fromDay to $toDay.';
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      padding: EdgeInsets.all(tokens.spaceLg),
      child: child,
    );
  }
}

class _OutcomeButton extends StatelessWidget {
  const _OutcomeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(label),
    );
  }
}
