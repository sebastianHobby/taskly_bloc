import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_preference.dart';

sealed class JournalTrackersState {
  const JournalTrackersState();
}

final class JournalTrackersLoading extends JournalTrackersState {
  const JournalTrackersLoading();
}

final class JournalTrackersLoaded extends JournalTrackersState {
  const JournalTrackersLoaded({
    required this.visibleDefinitions,
    required this.preferenceByTrackerId,
  });

  final List<TrackerDefinition> visibleDefinitions;
  final Map<String, TrackerPreference> preferenceByTrackerId;
}

final class JournalTrackersError extends JournalTrackersState {
  const JournalTrackersError(this.message);

  final String message;
}

class JournalTrackersCubit extends Cubit<JournalTrackersState> {
  JournalTrackersCubit({required JournalRepositoryContract repository})
    : _repository = repository,
      super(const JournalTrackersLoading()) {
    _subscribe();
  }

  final JournalRepositoryContract _repository;

  StreamSubscription<JournalTrackersLoaded>? _sub;

  List<TrackerDefinition> _latestVisible = const <TrackerDefinition>[];

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }

  Future<void> createTracker(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final nowUtc = DateTime.now().toUtc();

    await _repository.saveTrackerDefinition(
      TrackerDefinition(
        id: '',
        name: trimmed,
        description: null,
        scope: 'entry',
        valueType: 'yes_no',
        valueKind: 'boolean',
        opKind: 'set',
        createdAt: nowUtc,
        updatedAt: nowUtc,
        roles: const <String>[],
        config: const <String, dynamic>{},
        goal: const <String, dynamic>{},
        isActive: true,
        sortOrder: _latestVisible.length * 10 + 100,
        deletedAt: null,
        source: 'user',
        systemKey: null,
        minInt: null,
        maxInt: null,
        stepInt: null,
        linkedValueId: null,
        isOutcome: false,
        isInsightEnabled: false,
        higherIsBetter: null,
        unitKind: null,
        userId: null,
      ),
    );
  }

  Future<void> savePreference(TrackerPreference preference) async {
    await _repository.saveTrackerPreference(preference);
  }

  void _subscribe() {
    final defs$ = _repository.watchTrackerDefinitions();
    final prefs$ = _repository.watchTrackerPreferences();

    _sub =
        Rx.combineLatest2<
              List<TrackerDefinition>,
              List<TrackerPreference>,
              JournalTrackersLoaded
            >(
              defs$,
              prefs$,
              (defs, prefs) {
                final preferenceByTrackerId = {
                  for (final p in prefs) p.trackerId: p,
                };

                final visible =
                    defs
                        .where((d) => d.deletedAt == null)
                        .toList(growable: false)
                      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                _latestVisible = visible;

                return JournalTrackersLoaded(
                  visibleDefinitions: visible,
                  preferenceByTrackerId: preferenceByTrackerId,
                );
              },
            )
            .listen(
              emit,
              onError: (Object e) {
                emit(JournalTrackersError('Failed to load trackers: $e'));
              },
            );
  }
}
