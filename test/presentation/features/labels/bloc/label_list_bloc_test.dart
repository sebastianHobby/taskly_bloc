import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_helpers.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/presentation/features/labels/bloc/label_list_bloc.dart';

class MockLabelRepositoryContract extends Mock
    implements LabelRepositoryContract {}

class MockSettingsRepositoryContract extends Mock
    implements SettingsRepositoryContract {}

void main() {
  group('LabelOverviewBloc', () {
    late MockLabelRepositoryContract mockLabelRepository;
    late MockSettingsRepositoryContract mockSettingsRepository;
    late StreamController<List<Label>> labelsController;

    setUpAll(() {
      initializeTalkerForTest();
      registerFallbackValue(const SortPreferences(criteria: []));
      registerFallbackValue(LabelType.label);
      registerFallbackValue(PageKey.labelOverview);
      registerFallbackValue(SettingsKey.pageSort(PageKey.labelOverview));
    });

    setUp(() {
      mockLabelRepository = MockLabelRepositoryContract();
      mockSettingsRepository = MockSettingsRepositoryContract();
      labelsController = StreamController<List<Label>>.broadcast();

      when(
        () => mockLabelRepository.watchAll(),
      ).thenAnswer((_) => labelsController.stream);
      when(
        () => mockLabelRepository.watchByType(any()),
      ).thenAnswer((_) => labelsController.stream);
      when(
        () => mockSettingsRepository.load<SortPreferences?>(any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockSettingsRepository.save<SortPreferences?>(any(), any()),
      ).thenAnswer((_) async {});
      when(() => mockLabelRepository.delete(any())).thenAnswer((_) async {});
    });

    tearDown(() async {
      await labelsController.close();
    });

    Label createLabel({
      required String id,
      required String name,
      LabelType type = LabelType.label,
    }) {
      final now = DateTime.now();
      return Label(
        id: id,
        name: name,
        type: type,
        createdAt: now,
        updatedAt: now,
      );
    }

    group('initial state', () {
      test('is LabelOverviewInitial', () {
        final bloc = LabelOverviewBloc(
          labelRepository: mockLabelRepository,
        );

        expect(bloc.state, isA<LabelOverviewInitial>());
      });

      test('has default sort preferences', () {
        final bloc = LabelOverviewBloc(
          labelRepository: mockLabelRepository,
        );

        expect(
          bloc.currentSortPreferences.criteria.first.field,
          SortField.name,
        );
      });
    });

    group('LabelOverviewSubscriptionRequested', () {
      testSafe('calls watchAll when no type filter', () async {
        final bloc = LabelOverviewBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(const LabelOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(() => mockLabelRepository.watchAll()).called(1);
        await bloc.close();
      });

      testSafe('calls watchByType when type filter is set', () async {
        final bloc = LabelOverviewBloc(
          labelRepository: mockLabelRepository,
          typeFilter: LabelType.value,
        );

        bloc.add(const LabelOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => mockLabelRepository.watchByType(LabelType.value),
        ).called(1);
        await bloc.close();
      });

      testSafe('emits loaded state when labels are received', () async {
        final bloc = LabelOverviewBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(const LabelOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        labelsController.add([
          createLabel(id: '1', name: 'Work'),
          createLabel(id: '2', name: 'Personal'),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<LabelOverviewLoaded>());
        final loadedState = bloc.state as LabelOverviewLoaded;
        expect(loadedState.labels.length, 2);
        await bloc.close();
      });

      testSafe('emits error state when stream errors', () async {
        final bloc = LabelOverviewBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(const LabelOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        labelsController.addError(Exception('Database error'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<LabelOverviewError>());
        await bloc.close();
      });

      testSafe('loads saved sort preferences from settings', () async {
        const savedSort = SortPreferences(
          criteria: [
            SortCriterion(
              field: SortField.name,
              direction: SortDirection.descending,
            ),
          ],
        );
        when(
          () => mockSettingsRepository.load<SortPreferences?>(
            SettingsKey.pageSort(PageKey.labelOverview),
          ),
        ).thenAnswer((_) async => savedSort);

        final bloc = LabelOverviewBloc(
          labelRepository: mockLabelRepository,
          settingsRepository: mockSettingsRepository,
          pageKey: PageKey.labelOverview,
        );

        bloc.add(const LabelOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => mockSettingsRepository.load<SortPreferences?>(
            SettingsKey.pageSort(PageKey.labelOverview),
          ),
        ).called(1);
        expect(
          bloc.currentSortPreferences.criteria.first.direction,
          SortDirection.descending,
        );
        await bloc.close();
      });
    });

    group('sorting', () {
      testSafe('sorts labels by name ascending by default', () async {
        final bloc = LabelOverviewBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(const LabelOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        labelsController.add([
          createLabel(id: '1', name: 'Zebra'),
          createLabel(id: '2', name: 'Apple'),
          createLabel(id: '3', name: 'Mango'),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final loadedState = bloc.state as LabelOverviewLoaded;
        final names = loadedState.labels.map((l) => l.name).toList();
        expect(names, ['Apple', 'Mango', 'Zebra']);
        await bloc.close();
      });

      testSafe(
        'sorts labels by name descending when preference is set',
        () async {
          final bloc = LabelOverviewBloc(
            labelRepository: mockLabelRepository,
            initialSortPreferences: const SortPreferences(
              criteria: [
                SortCriterion(
                  field: SortField.name,
                  direction: SortDirection.descending,
                ),
              ],
            ),
          );

          bloc.add(const LabelOverviewSubscriptionRequested());
          await Future<void>.delayed(const Duration(milliseconds: 50));

          labelsController.add([
            createLabel(id: '1', name: 'Apple'),
            createLabel(id: '2', name: 'Zebra'),
            createLabel(id: '3', name: 'Mango'),
          ]);
          await Future<void>.delayed(const Duration(milliseconds: 50));

          final loadedState = bloc.state as LabelOverviewLoaded;
          final names = loadedState.labels.map((l) => l.name).toList();
          expect(names, ['Zebra', 'Mango', 'Apple']);
          await bloc.close();
        },
      );
    });

    group('LabelsSortChanged', () {
      testSafe('re-sorts labels with new preferences', () async {
        final bloc = LabelOverviewBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(const LabelOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        labelsController.add([
          createLabel(id: '1', name: 'Apple'),
          createLabel(id: '2', name: 'Zebra'),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Change sort to descending
        bloc.add(
          const LabelsSortChanged(
            preferences: SortPreferences(
              criteria: [
                SortCriterion(
                  field: SortField.name,
                  direction: SortDirection.descending,
                ),
              ],
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final loadedState = bloc.state as LabelOverviewLoaded;
        final names = loadedState.labels.map((l) => l.name).toList();
        expect(names, ['Zebra', 'Apple']);
        await bloc.close();
      });

      testSafe('persists sort preferences to settings', () async {
        final bloc = LabelOverviewBloc(
          labelRepository: mockLabelRepository,
          settingsRepository: mockSettingsRepository,
          pageKey: PageKey.labelOverview,
        );

        bloc.add(const LabelOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        labelsController.add([createLabel(id: '1', name: 'Test')]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        const newSort = SortPreferences(
          criteria: [
            SortCriterion(
              field: SortField.name,
              direction: SortDirection.descending,
            ),
          ],
        );
        bloc.add(const LabelsSortChanged(preferences: newSort));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => mockSettingsRepository.save<SortPreferences?>(
            SettingsKey.pageSort(PageKey.labelOverview),
            newSort,
          ),
        ).called(1);
        await bloc.close();
      });

      testSafe('does nothing when state is not loaded', () async {
        final bloc = LabelOverviewBloc(
          labelRepository: mockLabelRepository,
        );

        // State is initial, not loaded
        bloc.add(
          const LabelsSortChanged(
            preferences: SortPreferences(
              criteria: [
                SortCriterion(
                  field: SortField.name,
                  direction: SortDirection.descending,
                ),
              ],
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // State should still be initial
        expect(bloc.state, isA<LabelOverviewInitial>());
        await bloc.close();
      });
    });

    group('LabelOverviewDeleteLabel', () {
      testSafe('calls delete on repository', () async {
        final bloc = LabelOverviewBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(const LabelOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        labelsController.add([createLabel(id: '1', name: 'Work')]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final label = createLabel(id: '1', name: 'Work');
        bloc.add(LabelOverviewDeleteLabel(label: label));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(() => mockLabelRepository.delete('1')).called(1);
        await bloc.close();
      });

      testSafe('emits error on delete failure', () async {
        when(
          () => mockLabelRepository.delete(any()),
        ).thenThrow(Exception('Delete failed'));

        final bloc = LabelOverviewBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(const LabelOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        labelsController.add([createLabel(id: '1', name: 'Work')]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final label = createLabel(id: '1', name: 'Work');
        bloc.add(LabelOverviewDeleteLabel(label: label));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<LabelOverviewError>());
        await bloc.close();
      });
    });

    group('lifecycle', () {
      testSafe('closes cleanly', () async {
        final bloc = LabelOverviewBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(const LabelOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await bloc.close();
        // No assertion needed - just verify no exceptions
      });
    });
  });
}
