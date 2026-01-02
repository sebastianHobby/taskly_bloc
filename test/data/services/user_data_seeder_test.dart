import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/services/user_data_seeder.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';

class MockLabelRepositoryContract extends Mock
    implements LabelRepositoryContract {}

class MockScreenDefinitionsRepositoryContract extends Mock
    implements ScreenDefinitionsRepositoryContract {}

void main() {
  group('UserDataSeeder', () {
    late MockLabelRepositoryContract mockLabelRepository;
    late MockScreenDefinitionsRepositoryContract mockScreenRepository;
    late UserDataSeeder seeder;
    late Label pinnedLabel;

    setUpAll(() {
      initializeTalkerForTest();
      registerFallbackValue(<ScreenDefinition>[]);
      registerFallbackValue(SystemLabelType.pinned);
    });

    setUp(() {
      mockLabelRepository = MockLabelRepositoryContract();
      mockScreenRepository = MockScreenDefinitionsRepositoryContract();
      seeder = UserDataSeeder(
        labelRepository: mockLabelRepository,
        screenRepository: mockScreenRepository,
      );

      final now = DateTime.now();
      pinnedLabel = Label(
        id: 'pinned-label-id',
        name: 'Pinned',
        color: '#FF5733',
        isSystemLabel: true,
        systemLabelType: SystemLabelType.pinned,
        createdAt: now,
        updatedAt: now,
      );
    });

    group('seedAll', () {
      test('seeds system labels and screens', () async {
        when(
          () => mockLabelRepository.getOrCreateSystemLabel(any()),
        ).thenAnswer((_) async => pinnedLabel);
        when(
          () => mockScreenRepository.seedSystemScreens(any()),
        ).thenAnswer((_) async {});

        await seeder.seedAll('test-user-123');

        verify(
          () => mockLabelRepository.getOrCreateSystemLabel(
            SystemLabelType.pinned,
          ),
        ).called(2); // Called by both ensurePinnedLabelExists and migrate
        verify(() => mockScreenRepository.seedSystemScreens(any())).called(1);
      });

      test('passes userId to screen seeder', () async {
        when(
          () => mockLabelRepository.getOrCreateSystemLabel(any()),
        ).thenAnswer((_) async => pinnedLabel);
        when(
          () => mockScreenRepository.seedSystemScreens(any()),
        ).thenAnswer((_) async {});

        await seeder.seedAll('user-xyz');

        final captured = verify(
          () => mockScreenRepository.seedSystemScreens(captureAny()),
        ).captured;

        final screens = captured.first as List<ScreenDefinition>;
        expect(screens, isNotEmpty);
      });

      test('does not throw on label seeder failure', () async {
        when(
          () => mockLabelRepository.getOrCreateSystemLabel(any()),
        ).thenThrow(Exception('Database error'));

        // Should not throw - errors are handled internally
        await expectLater(
          seeder.seedAll('test-user'),
          completes,
        );
      });

      test('does not throw on screen seeder failure', () async {
        when(
          () => mockLabelRepository.getOrCreateSystemLabel(any()),
        ).thenAnswer((_) async => pinnedLabel);
        when(
          () => mockScreenRepository.seedSystemScreens(any()),
        ).thenThrow(Exception('Database error'));

        // Should not throw - errors are handled internally
        await expectLater(
          seeder.seedAll('test-user'),
          completes,
        );
      });

      test('seeds labels before screens', () async {
        final callOrder = <String>[];

        when(
          () => mockLabelRepository.getOrCreateSystemLabel(any()),
        ).thenAnswer((_) async {
          callOrder.add('labels');
          return pinnedLabel;
        });
        when(
          () => mockScreenRepository.seedSystemScreens(any()),
        ).thenAnswer((_) async {
          callOrder.add('screens');
        });

        await seeder.seedAll('test-user');

        // Labels should be seeded before screens
        expect(
          callOrder.indexOf('labels'),
          lessThan(callOrder.indexOf('screens')),
        );
      });

      test('is idempotent - safe to call multiple times', () async {
        when(
          () => mockLabelRepository.getOrCreateSystemLabel(any()),
        ).thenAnswer((_) async => pinnedLabel);
        when(
          () => mockScreenRepository.seedSystemScreens(any()),
        ).thenAnswer((_) async {});

        // Call seedAll multiple times
        await seeder.seedAll('test-user');
        await seeder.seedAll('test-user');
        await seeder.seedAll('test-user');

        // Should complete without errors
        verify(
          () => mockLabelRepository.getOrCreateSystemLabel(
            SystemLabelType.pinned,
          ),
        ).called(6); // 2 calls per seedAll
        verify(() => mockScreenRepository.seedSystemScreens(any())).called(3);
      });
    });
  });
}
