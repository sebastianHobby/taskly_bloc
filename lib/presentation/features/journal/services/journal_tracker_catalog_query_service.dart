import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';

class JournalTrackerCatalogSnapshot {
  const JournalTrackerCatalogSnapshot({
    required this.groups,
    required this.trackers,
    required this.preferences,
  });

  final List<TrackerGroup> groups;
  final List<TrackerDefinition> trackers;
  final List<TrackerPreference> preferences;

  Map<String, TrackerPreference> get preferencesByTrackerId => {
    for (final preference in preferences) preference.trackerId: preference,
  };
}

class JournalTrackerCatalogQueryService {
  const JournalTrackerCatalogQueryService({
    required JournalRepositoryContract repository,
  }) : _repository = repository;

  final JournalRepositoryContract _repository;

  Stream<JournalTrackerCatalogSnapshot> watchCatalog() {
    return Rx.combineLatest3<
      List<TrackerGroup>,
      List<TrackerDefinition>,
      List<TrackerPreference>,
      JournalTrackerCatalogSnapshot
    >(
      _repository.watchTrackerGroups(),
      _repository.watchTrackerDefinitions(),
      _repository.watchTrackerPreferences(),
      (groups, trackers, preferences) => JournalTrackerCatalogSnapshot(
        groups: groups,
        trackers: trackers,
        preferences: preferences,
      ),
    );
  }
}
