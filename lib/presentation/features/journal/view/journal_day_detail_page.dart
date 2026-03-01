import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_entry_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_day_trackers_card.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_today_shared_widgets.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalDayDetailPage extends StatelessWidget {
  const JournalDayDetailPage({
    required this.dayUtc,
    super.key,
  });

  final DateTime dayUtc;

  @override
  Widget build(BuildContext context) {
    final dayLocal = DateTime(dayUtc.year, dayUtc.month, dayUtc.day);

    return BlocProvider<JournalHistoryBloc>(
      create: (context) => JournalHistoryBloc(
        repository: context.read<JournalRepositoryContract>(),
        dayKeyService: context.read<HomeDayKeyService>(),
        settingsRepository: context.read<SettingsRepositoryContract>(),
        nowUtc: context.read<NowService>().nowUtc,
        initialFiltersOverride: JournalHistoryFilters.initial().copyWith(
          rangeStart: dayUtc,
          rangeEnd: dayUtc,
          lookbackDays: 1,
        ),
        persistFilters: false,
      )..add(const JournalHistoryStarted()),
      child: BlocBuilder<JournalHistoryBloc, JournalHistoryState>(
        builder: (context, state) {
          final tokens = TasklyTokens.of(context);

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.MMMEd().format(dayLocal),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    context.l10n.journalDayDetailTitle,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            body: switch (state) {
              JournalHistoryLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              JournalHistoryError(:final message) => Center(
                child: Padding(
                  padding: EdgeInsets.all(tokens.spaceLg),
                  child: Text(message),
                ),
              ),
              JournalHistoryLoaded() => _DayDetailBody(
                state: state,
                dayUtc: dayUtc,
              ),
            },
          );
        },
      ),
    );
  }
}

class _DayDetailBody extends StatelessWidget {
  const _DayDetailBody({
    required this.state,
    required this.dayUtc,
  });

  final JournalHistoryLoaded state;
  final DateTime dayUtc;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final day = dateOnly(dayUtc);
    final summary = state.days.firstWhere(
      (d) => dateOnly(d.day) == day,
      orElse: () => JournalHistoryDaySummary(
        day: day,
        entries: const <JournalEntry>[],
        eventsByEntryId: const <String, List<TrackerEvent>>{},
        latestEventByTrackerId: const <String, TrackerEvent>{},
        definitionById: const <String, TrackerDefinition>{},
        moodTrackerId: null,
        moodAverage: null,
        dayQuantityTotalsByTrackerId: const <String, double>{},
        dayAggregateValuesByTrackerId: const <String, double>{},
        factorTrackerIds: const <String>{},
        choiceLabelsByTrackerId: const <String, Map<String, String>>{},
      ),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        tokens.spaceLg,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.journalYourDayTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        JournalDayTrackersCard(
          summary: summary,
          previousSummary: null,
          dayTrackerDefinitions: state.dayTrackerDefinitions,
          dayTrackerOrderIds: state.dayTrackerOrderIds,
          hiddenDayTrackerIds: state.hiddenDayTrackerIds,
          ignoreHidden: true,
          onSaveValue: (definition, value) {
            context.read<JournalHistoryBloc>().add(
              JournalHistoryDayTrackerQuickValueSaved(
                day: summary.day,
                trackerId: definition.id,
                value: value,
              ),
            );
          },
          onAddDelta: (definition, delta) {
            context.read<JournalHistoryBloc>().add(
              JournalHistoryDayTrackerQuickDeltaAdded(
                day: summary.day,
                trackerId: definition.id,
                delta: delta,
              ),
            );
          },
          onLoadChoices: (trackerId) async {
            final choices = await context.read<JournalHistoryBloc>().getChoices(
              trackerId,
            );
            return [for (final choice in choices) choice.label];
          },
        ),
        SizedBox(height: tokens.spaceMd),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.journalMomentsTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => JournalEntryEditorRoutePage.showQuickCapture(
                context,
                selectedDayLocal: day,
              ),
              child: Text(context.l10n.journalAddEntry),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        if (summary.entries.isEmpty)
          Text(
            context.l10n.journalNoLogsForDay,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final entry in summary.entries)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceSm),
              child: JournalLogCard(
                entry: entry,
                events:
                    summary.eventsByEntryId[entry.id] ?? const <TrackerEvent>[],
                definitionById: summary.definitionById,
                moodTrackerId: summary.moodTrackerId,
                density: state.density,
                choiceLabelsByTrackerId: summary.choiceLabelsByTrackerId,
                onTap: () => Routing.toJournalEntryEdit(context, entry.id),
              ),
            ),
      ],
    );
  }
}
