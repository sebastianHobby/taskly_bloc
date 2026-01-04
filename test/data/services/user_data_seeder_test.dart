import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/services/user_data_seeder.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/models/label.dart';

class MockLabelRepositoryContract extends Mock
    implements LabelRepositoryContract {}

void main() {
  group('UserDataSeeder', () {
    late MockLabelRepositoryContract mockLabelRepository;
    late UserDataSeeder seeder;
    late Label pinnedLabel;

    setUpAll(() {
      initializeTalkerForTest();
      registerFallbackValue(SystemLabelType.pinned);
    });

    setUp(() {
      mockLabelRepository = MockLabelRepositoryContract();
      seeder = UserDataSeeder(
        labelRepository: mockLabelRepository,
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
      test('seeds system labels', () async {
        when(
          () => mockLabelRepository.getOrCreateSystemLabel(any()),
        ).thenAnswer((_) async => pinnedLabel);

        await seeder.seedAll('test-user-123');

        verify(
          () => mockLabelRepository.getOrCreateSystemLabel(
            SystemLabelType.pinned,
          ),
        ).called(2); // Called by both ensurePinnedLabelExists and migrate
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

      test('is idempotent - safe to call multiple times', () async {
        when(
          () => mockLabelRepository.getOrCreateSystemLabel(any()),
        ).thenAnswer((_) async => pinnedLabel);

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
      });
    });
  });
}
