import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/settings.dart';
import 'package:taskly_bloc/features/settings/settings.dart';

import '../mocks/repository_mocks.dart';

void main() {
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
  });

  group('SettingsBloc', () {
    blocTest<SettingsBloc, SettingsState>(
      'emits loading then loaded when subscription requested',
      setUp: () {
        when(
          () => mockRepository.watchAll(),
        ).thenAnswer((_) => Stream.value(const AppSettings()));
      },
      build: () => SettingsBloc(settingsRepository: mockRepository),
      act: (bloc) => bloc.add(const SettingsSubscriptionRequested()),
      expect: () => const <SettingsState>[
        SettingsState(status: SettingsStatus.loading),
        SettingsState(
          status: SettingsStatus.loaded,
          settings: AppSettings(),
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'updates sort for a page and persists it',
      setUp: () {
        when(
          () => mockRepository.watchAll(),
        ).thenAnswer((_) => Stream.value(const AppSettings()));
      },
      build: () => SettingsBloc(settingsRepository: mockRepository),
      act: (bloc) async {
        bloc.add(const SettingsSubscriptionRequested());
        const preferences = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.deadlineDate),
            SortCriterion(field: SortField.name),
          ],
        );
        when(
          () => mockRepository.savePageSort(
            SettingsPageKey.inbox,
            preferences,
          ),
        ).thenAnswer((_) async {});

        bloc.add(
          const SettingsUpdatePageSort(
            pageKey: SettingsPageKey.inbox,
            preferences: preferences,
          ),
        );
      },
      expect: () => const <SettingsState>[
        SettingsState(status: SettingsStatus.loading),
        SettingsState(
          status: SettingsStatus.loaded,
          settings: AppSettings(),
        ),
        // No third emission: removed optimistic emit,
        // watch stream emission happens after save completes
      ],
      verify: (bloc) {
        const preferences = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.deadlineDate),
            SortCriterion(field: SortField.name),
          ],
        );
        verify(
          () => mockRepository.savePageSort(
            SettingsPageKey.inbox,
            preferences,
          ),
        ).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'updates next actions settings and persists them',
      setUp: () {
        when(
          () => mockRepository.watchAll(),
        ).thenAnswer((_) => Stream.value(const AppSettings()));
      },
      build: () => SettingsBloc(settingsRepository: mockRepository),
      act: (bloc) async {
        bloc.add(const SettingsSubscriptionRequested());
        const updatedNextActions = NextActionsSettings(
          tasksPerProject: 4,
        );
        when(
          () => mockRepository.saveNextActionsSettings(updatedNextActions),
        ).thenAnswer((_) async {});

        bloc.add(
          const SettingsUpdateNextActions(settings: updatedNextActions),
        );
      },
      expect: () => const <SettingsState>[
        SettingsState(status: SettingsStatus.loading),
        SettingsState(
          status: SettingsStatus.loaded,
          settings: AppSettings(),
        ),
        // No third emission: removed optimistic emit,
        // watch stream emission happens after save completes
      ],
      verify: (bloc) {
        const updatedNextActions = NextActionsSettings(
          tasksPerProject: 4,
        );
        verify(
          () => mockRepository.saveNextActionsSettings(updatedNextActions),
        ).called(1);
      },
    );
  });
}
