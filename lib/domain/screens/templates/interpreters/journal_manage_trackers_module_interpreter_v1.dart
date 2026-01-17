import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';

final class JournalManageTrackersModuleInterpreterV1 {
  JournalManageTrackersModuleInterpreterV1({
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
      final preferenceByTrackerId = {for (final p in prefs) p.trackerId: p};

      final visibleDefinitions =
          defs.where((d) => d.deletedAt == null).toList(growable: false)
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      return SectionDataResult.journalManageTrackersV1(
        visibleDefinitions: visibleDefinitions,
        preferenceByTrackerId: preferenceByTrackerId,
      );
    });
  }
}
