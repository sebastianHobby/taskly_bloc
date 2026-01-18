import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/taskly_domain.dart'
    show AppFailure, OperationContext;

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
  JournalTrackersCubit({
    required JournalRepositoryContract repository,
    required AppErrorReporter errorReporter,
    required DateTime Function() nowUtc,
  }) : _repository = repository,
       _errorReporter = errorReporter,
       _nowUtc = nowUtc,
       super(const JournalTrackersLoading()) {
    _subscribe();
  }

  final JournalRepositoryContract _repository;
  final AppErrorReporter _errorReporter;
  final DateTime Function() _nowUtc;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  OperationContext _newContext({
    required String intent,
    required String operation,
    String? trackerId,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    return _contextFactory.create(
      feature: 'journal',
      screen: 'journal_trackers',
      intent: intent,
      operation: operation,
      entityType: 'tracker_definition',
      entityId: trackerId,
      extraFields: extraFields,
    );
  }

  void _reportIfUnexpectedOrUnmapped(
    Object error,
    StackTrace stackTrace, {
    required OperationContext context,
    required String message,
  }) {
    if (error is AppFailure && error.reportAsUnexpected) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: '$message (unexpected failure)',
      );
      return;
    }

    if (error is! AppFailure) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: '$message (unmapped exception)',
      );
    }
  }

  String _uiMessageFor(Object error, {required String fallback}) {
    if (error is AppFailure) return error.uiMessage();
    return fallback;
  }

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

    final nowUtc = _nowUtc();

    final context = _newContext(
      intent: 'create_tracker',
      operation: 'journal.saveTrackerDefinition',
      extraFields: <String, Object?>{'nameLength': trimmed.length},
    );

    try {
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
        context: context,
      );
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalTrackersCubit] createTracker failed',
      );

      emit(
        JournalTrackersError(
          _uiMessageFor(
            error,
            fallback: 'Failed to create tracker. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> savePreference(TrackerPreference preference) async {
    final context = _newContext(
      intent: 'save_preference',
      operation: 'journal.saveTrackerPreference',
      trackerId: preference.trackerId,
    );

    try {
      await _repository.saveTrackerPreference(preference, context: context);
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalTrackersCubit] savePreference failed',
      );

      emit(
        JournalTrackersError(
          _uiMessageFor(
            error,
            fallback: 'Failed to save preference. Please try again.',
          ),
        ),
      );
    }
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
              onError: (Object e, StackTrace st) {
                final context = _newContext(
                  intent: 'trackers_stream_error',
                  operation: 'journal.watchTrackerDefinitions+preferences',
                );

                _reportIfUnexpectedOrUnmapped(
                  e,
                  st,
                  context: context,
                  message: '[JournalTrackersCubit] trackers stream error',
                );

                emit(
                  JournalTrackersError(
                    _uiMessageFor(
                      e,
                      fallback: 'Failed to load trackers. Please try again.',
                    ),
                  ),
                );
              },
            );
  }
}
