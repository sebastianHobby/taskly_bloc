import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_preference.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';

final class JournalTodayComposerModuleInterpreterV1 {
  JournalTodayComposerModuleInterpreterV1({
    required JournalRepositoryContract repository,
  }) : _repository = repository;

  final JournalRepositoryContract _repository;

  Stream<SectionDataResult> watch() {
    final defs$ = _repository.watchTrackerDefinitions();
    final prefs$ = _repository.watchTrackerPreferences();

    return Rx.combineLatest2<
      List<TrackerDefinition>,
      List<TrackerPreference>,
      SectionDataResult
    >(defs$, prefs$, (defs, prefs) {
      final preferenceByTrackerId = {
        for (final p in prefs) p.trackerId: p,
      };

      String? moodTrackerId;
      for (final d in defs) {
        if (d.systemKey == 'mood') {
          moodTrackerId = d.id;
          break;
        }
      }

      final pinnedTrackers =
          defs
              .where((d) => d.isActive && d.deletedAt == null)
              .where((d) => d.systemKey != 'mood')
              .where((d) {
                final pref = preferenceByTrackerId[d.id];
                return (pref?.pinned ?? false) ||
                    (pref?.showInQuickAdd ?? false);
              })
              .toList(growable: false)
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      return SectionDataResult.journalTodayComposerV1(
        pinnedTrackers: pinnedTrackers,
        moodTrackerId: moodTrackerId,
      );
    });
  }
}
