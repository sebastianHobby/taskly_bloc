import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/settings.dart';
import 'package:taskly_bloc/features/settings/settings.dart';

import '../mocks/repository_mocks.dart';

void main() {
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
    registerFallbackValue(const NextActionsSettings());
  });

  group('NextActionsSettings persistence', () {
    test('includeInboxTasks changes from false to true', () async {
      // Initial settings with includeInboxTasks=false
      const initialSettings = AppSettings(
        nextActions: NextActionsSettings(),
      );

      // Updated settings with includeInboxTasks=true
      const updatedNextActions = NextActionsSettings(
        includeInboxTasks: true,
      );

      when(() => mockRepository.watchAll()).thenAnswer(
        (_) => Stream.value(initialSettings),
      );
      when(
        () => mockRepository.saveNextActionsSettings(any()),
      ).thenAnswer((_) async {});

      final bloc = SettingsBloc(settingsRepository: mockRepository);
      bloc.add(const SettingsSubscriptionRequested());

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Capture the save call
      when(
        () => mockRepository.saveNextActionsSettings(updatedNextActions),
      ).thenAnswer((_) async {});

      // Update settings
      bloc.add(SettingsUpdateNextActions(settings: updatedNextActions));

      // Wait for the update
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify save was called with includeInboxTasks=true
      verify(
        () => mockRepository.saveNextActionsSettings(updatedNextActions),
      ).called(1);

      await bloc.close();
    });

    test('tasksPerProject is correctly persisted', () async {
      const initialSettings = AppSettings(
        nextActions: NextActionsSettings(),
      );

      const updatedNextActions = NextActionsSettings(
        tasksPerProject: 7,
      );

      when(() => mockRepository.watchAll()).thenAnswer(
        (_) => Stream.value(initialSettings),
      );
      when(
        () => mockRepository.saveNextActionsSettings(any()),
      ).thenAnswer((_) async {});

      final bloc = SettingsBloc(settingsRepository: mockRepository);
      bloc.add(const SettingsSubscriptionRequested());

      await Future<void>.delayed(const Duration(milliseconds: 100));

      when(
        () => mockRepository.saveNextActionsSettings(updatedNextActions),
      ).thenAnswer((_) async {});

      bloc.add(SettingsUpdateNextActions(settings: updatedNextActions));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(
        () => mockRepository.saveNextActionsSettings(updatedNextActions),
      ).called(1);

      await bloc.close();
    });
  });
}
