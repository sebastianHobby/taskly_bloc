import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/settings.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/features/settings/settings.dart';

class MockSettingsRepository extends Mock
    implements SettingsRepositoryContract {}

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
          () => mockRepository.watch(),
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
          () => mockRepository.watch(),
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
        final expectedSettings = const AppSettings().upsertPageSort(
          pageKey: SettingsPageKey.inbox,
          preferences: preferences,
        );

        when(
          () => mockRepository.save(expectedSettings),
        ).thenAnswer((_) async {});

        bloc.add(
          const SettingsUpdatePageSort(
            pageKey: SettingsPageKey.inbox,
            preferences: preferences,
          ),
        );
      },
      expect: () {
        const preferences = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.deadlineDate),
            SortCriterion(field: SortField.name),
          ],
        );
        final updatedSettings = const AppSettings().upsertPageSort(
          pageKey: SettingsPageKey.inbox,
          preferences: preferences,
        );

        return <SettingsState>[
          const SettingsState(status: SettingsStatus.loading),
          const SettingsState(
            status: SettingsStatus.loaded,
            settings: AppSettings(),
          ),
          SettingsState(
            status: SettingsStatus.loaded,
            settings: updatedSettings,
          ),
        ];
      },
      verify: (bloc) {
        const preferences = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.deadlineDate),
            SortCriterion(field: SortField.name),
          ],
        );
        final expectedSettings = const AppSettings().upsertPageSort(
          pageKey: SettingsPageKey.inbox,
          preferences: preferences,
        );

        verify(() => mockRepository.save(expectedSettings)).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'updates next actions settings and persists them',
      setUp: () {
        when(
          () => mockRepository.watch(),
        ).thenAnswer((_) => Stream.value(const AppSettings()));
      },
      build: () => SettingsBloc(settingsRepository: mockRepository),
      act: (bloc) async {
        bloc.add(const SettingsSubscriptionRequested());
        const updatedNextActions = NextActionsSettings(
          tasksPerProject: 4,
        );
        final expectedSettings = const AppSettings().updateNextActions(
          updatedNextActions,
        );

        when(
          () => mockRepository.save(expectedSettings),
        ).thenAnswer((_) async {});

        bloc.add(
          const SettingsUpdateNextActions(settings: updatedNextActions),
        );
      },
      expect: () {
        const updatedNextActions = NextActionsSettings(
          tasksPerProject: 4,
        );
        final expectedSettings = const AppSettings().updateNextActions(
          updatedNextActions,
        );
        return <SettingsState>[
          const SettingsState(status: SettingsStatus.loading),
          const SettingsState(
            status: SettingsStatus.loaded,
            settings: AppSettings(),
          ),
          SettingsState(
            status: SettingsStatus.loaded,
            settings: expectedSettings,
          ),
        ];
      },
      verify: (bloc) {
        const updatedNextActions = NextActionsSettings(
          tasksPerProject: 4,
        );
        final expectedSettings = const AppSettings().updateNextActions(
          updatedNextActions,
        );
        verify(() => mockRepository.save(expectedSettings)).called(1);
      },
    );
  });
}
