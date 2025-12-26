import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/tracker.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/tracker_response_config.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/repositories/wellbeing_repository.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/presentation/blocs/tracker_management/tracker_management_bloc.dart';

class MockWellbeingRepository extends Mock implements WellbeingRepository {}

void main() {
  late WellbeingRepository repository;
  late TrackerManagementBloc bloc;

  setUp(() {
    repository = MockWellbeingRepository();
    bloc = TrackerManagementBloc(repository);
  });

  tearDown(() {
    bloc.close();
  });

  final testTracker = Tracker(
    id: 't-1',
    name: 'Exercise',
    responseType: TrackerResponseType.yesNo,
    config: const TrackerResponseConfig.yesNo(),
    entryScope: TrackerEntryScope.allDay,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );

  group('TrackerManagementBloc', () {
    test('initial state is initial', () {
      expect(bloc.state, equals(const TrackerManagementState.initial()));
    });

    group('loadTrackers', () {
      blocTest<TrackerManagementBloc, TrackerManagementState>(
        'emits [loading, loaded] when getAllTrackers succeeds',
        build: () {
          when(
            () => repository.getAllTrackers(),
          ).thenAnswer((_) async => [testTracker]);
          return bloc;
        },
        act: (bloc) => bloc.add(const TrackerManagementEvent.loadTrackers()),
        expect: () => [
          const TrackerManagementState.loading(),
          TrackerManagementState.loaded([testTracker]),
        ],
        verify: (_) {
          verify(() => repository.getAllTrackers()).called(1);
        },
      );

      blocTest<TrackerManagementBloc, TrackerManagementState>(
        'emits [loading, error] when getAllTrackers fails',
        build: () {
          when(
            () => repository.getAllTrackers(),
          ).thenThrow(Exception('Failed to load'));
          return bloc;
        },
        act: (bloc) => bloc.add(const TrackerManagementEvent.loadTrackers()),
        expect: () => [
          const TrackerManagementState.loading(),
          const TrackerManagementState.error('Exception: Failed to load'),
        ],
      );

      blocTest<TrackerManagementBloc, TrackerManagementState>(
        'emits loaded with empty list when no trackers exist',
        build: () {
          when(() => repository.getAllTrackers()).thenAnswer((_) async => []);
          return bloc;
        },
        act: (bloc) => bloc.add(const TrackerManagementEvent.loadTrackers()),
        expect: () => [
          const TrackerManagementState.loading(),
          const TrackerManagementState.loaded([]),
        ],
      );
    });

    group('saveTracker', () {
      blocTest<TrackerManagementBloc, TrackerManagementState>(
        'emits [loading, saved] when saveTracker succeeds',
        build: () {
          when(() => repository.saveTracker(any())).thenAnswer((_) async => {});
          return bloc;
        },
        act: (bloc) =>
            bloc.add(TrackerManagementEvent.saveTracker(testTracker)),
        expect: () => [
          const TrackerManagementState.loading(),
          const TrackerManagementState.saved(),
        ],
        verify: (_) {
          verify(() => repository.saveTracker(testTracker)).called(1);
        },
      );

      blocTest<TrackerManagementBloc, TrackerManagementState>(
        'emits [loading, error] when saveTracker fails',
        build: () {
          when(
            () => repository.saveTracker(any()),
          ).thenThrow(Exception('Failed to save'));
          return bloc;
        },
        act: (bloc) =>
            bloc.add(TrackerManagementEvent.saveTracker(testTracker)),
        expect: () => [
          const TrackerManagementState.loading(),
          const TrackerManagementState.error('Exception: Failed to save'),
        ],
      );
    });

    group('deleteTracker', () {
      blocTest<TrackerManagementBloc, TrackerManagementState>(
        'emits [loading, saved] when deleteTracker succeeds',
        build: () {
          when(
            () => repository.deleteTracker(any()),
          ).thenAnswer((_) async => {});
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const TrackerManagementEvent.deleteTracker('t-1')),
        expect: () => [
          const TrackerManagementState.loading(),
          const TrackerManagementState.saved(),
        ],
        verify: (_) {
          verify(() => repository.deleteTracker('t-1')).called(1);
        },
      );

      blocTest<TrackerManagementBloc, TrackerManagementState>(
        'emits [loading, error] when deleteTracker fails',
        build: () {
          when(
            () => repository.deleteTracker(any()),
          ).thenThrow(Exception('Failed to delete'));
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const TrackerManagementEvent.deleteTracker('t-1')),
        expect: () => [
          const TrackerManagementState.loading(),
          const TrackerManagementState.error('Exception: Failed to delete'),
        ],
      );
    });

    group('reorderTrackers', () {
      blocTest<TrackerManagementBloc, TrackerManagementState>(
        'emits [saved] when reorderTrackers succeeds',
        build: () {
          when(
            () => repository.reorderTrackers(any()),
          ).thenAnswer((_) async => {});
          return bloc;
        },
        act: (bloc) => bloc.add(
          const TrackerManagementEvent.reorderTrackers(['t-1', 't-2', 't-3']),
        ),
        expect: () => [
          const TrackerManagementState.saved(),
        ],
        verify: (_) {
          verify(
            () => repository.reorderTrackers(['t-1', 't-2', 't-3']),
          ).called(1);
        },
      );

      blocTest<TrackerManagementBloc, TrackerManagementState>(
        'emits [error] when reorderTrackers fails',
        build: () {
          when(
            () => repository.reorderTrackers(any()),
          ).thenThrow(Exception('Failed to reorder'));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const TrackerManagementEvent.reorderTrackers(['t-1', 't-2']),
        ),
        expect: () => [
          const TrackerManagementState.error('Exception: Failed to reorder'),
        ],
      );

      blocTest<TrackerManagementBloc, TrackerManagementState>(
        'handles empty list reordering',
        build: () {
          when(
            () => repository.reorderTrackers(any()),
          ).thenAnswer((_) async => {});
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const TrackerManagementEvent.reorderTrackers([])),
        expect: () => [
          const TrackerManagementState.saved(),
        ],
      );
    });

    group('state transitions', () {
      blocTest<TrackerManagementBloc, TrackerManagementState>(
        'can transition from saved back to loading',
        build: () {
          when(() => repository.saveTracker(any())).thenAnswer((_) async => {});
          when(
            () => repository.getAllTrackers(),
          ).thenAnswer((_) async => [testTracker]);
          return bloc;
        },
        act: (bloc) {
          bloc.add(TrackerManagementEvent.saveTracker(testTracker));
          return Future.delayed(
            const Duration(milliseconds: 100),
            () => bloc.add(const TrackerManagementEvent.loadTrackers()),
          );
        },
        expect: () => [
          const TrackerManagementState.loading(),
          const TrackerManagementState.saved(),
          const TrackerManagementState.loading(),
          TrackerManagementState.loaded([testTracker]),
        ],
      );
    });
  });
}
