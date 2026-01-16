import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/analytics/model/date_range.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_event.dart';
import 'package:taskly_bloc/domain/queries/journal_query.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/time/date_only.dart';

final class JournalTodayEntriesModuleInterpreterV1 {
  JournalTodayEntriesModuleInterpreterV1({
    required JournalRepositoryContract repository,
    DateTime Function()? nowUtc,
  }) : _repository = repository,
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  final JournalRepositoryContract _repository;
  final DateTime Function() _nowUtc;

  Stream<SectionDataResult> watch() {
    final nowUtc = _nowUtc();
    final startUtc = dateOnly(nowUtc);
    final endUtc = startUtc
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));

    final defs$ = _repository.watchTrackerDefinitions();
    final entries$ = _repository.watchJournalEntriesByQuery(
      JournalQuery.forDate(nowUtc),
    );
    final events$ = _repository.watchTrackerEvents(
      range: DateRange(start: startUtc, end: endUtc),
      anchorType: 'entry',
    );

    return Rx.combineLatest3<
      List<TrackerDefinition>,
      List<JournalEntry>,
      List<TrackerEvent>,
      SectionDataResult
    >(defs$, entries$, events$, (defs, entries, events) {
      final definitionById = {for (final d in defs) d.id: d};

      String? moodTrackerId;
      for (final d in defs) {
        if (d.systemKey == 'mood') {
          moodTrackerId = d.id;
          break;
        }
      }

      final eventsByEntryId = <String, List<TrackerEvent>>{};
      for (final e in events) {
        final entryId = e.entryId;
        if (entryId == null) continue;
        (eventsByEntryId[entryId] ??= <TrackerEvent>[]).add(e);
      }

      return SectionDataResult.journalTodayEntriesV1(
        entries: entries,
        eventsByEntryId: eventsByEntryId,
        definitionById: definitionById,
        moodTrackerId: moodTrackerId,
      );
    });
  }
}
