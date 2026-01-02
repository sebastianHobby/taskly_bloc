import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/data/services/system_label_seeder.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/models/label.dart';

class MockLabelRepositoryContract extends Mock
    implements LabelRepositoryContract {}

void main() {
  group('SystemLabelSeeder', () {
    late MockLabelRepositoryContract mockLabelRepository;
    late SystemLabelSeeder seeder;
    late Label pinnedLabel;

    setUp(() {
      mockLabelRepository = MockLabelRepositoryContract();
      seeder = SystemLabelSeeder(labelRepository: mockLabelRepository);
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

    group('ensurePinnedLabelExists', () {
      test(
        'calls getOrCreateSystemLabel with SystemLabelType.pinned',
        () async {
          when(
            () => mockLabelRepository.getOrCreateSystemLabel(
              SystemLabelType.pinned,
            ),
          ).thenAnswer((_) async => pinnedLabel);

          final result = await seeder.ensurePinnedLabelExists();

          expect(result, pinnedLabel);
          verify(
            () => mockLabelRepository.getOrCreateSystemLabel(
              SystemLabelType.pinned,
            ),
          ).called(1);
        },
      );

      test('returns the created/existing label', () async {
        final customPinnedLabel = pinnedLabel.copyWith(id: 'custom-id');
        when(
          () => mockLabelRepository.getOrCreateSystemLabel(
            SystemLabelType.pinned,
          ),
        ).thenAnswer((_) async => customPinnedLabel);

        final result = await seeder.ensurePinnedLabelExists();

        expect(result.id, 'custom-id');
        expect(result.systemLabelType, SystemLabelType.pinned);
      });

      test('propagates repository errors', () async {
        when(
          () => mockLabelRepository.getOrCreateSystemLabel(
            SystemLabelType.pinned,
          ),
        ).thenThrow(Exception('Database error'));

        expect(
          () => seeder.ensurePinnedLabelExists(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('migrateNextActionTasks', () {
      test('ensures pinned label exists', () async {
        when(
          () => mockLabelRepository.getOrCreateSystemLabel(
            SystemLabelType.pinned,
          ),
        ).thenAnswer((_) async => pinnedLabel);

        await seeder.migrateNextActionTasks();

        verify(
          () => mockLabelRepository.getOrCreateSystemLabel(
            SystemLabelType.pinned,
          ),
        ).called(1);
      });
    });

    group('seedAll', () {
      test(
        'calls ensurePinnedLabelExists and migrateNextActionTasks',
        () async {
          when(
            () => mockLabelRepository.getOrCreateSystemLabel(
              SystemLabelType.pinned,
            ),
          ).thenAnswer((_) async => pinnedLabel);

          await seeder.seedAll();

          // seedAll internally calls both methods, both of which call
          // getOrCreateSystemLabel
          verify(
            () => mockLabelRepository.getOrCreateSystemLabel(
              SystemLabelType.pinned,
            ),
          ).called(2);
        },
      );

      test('propagates repository errors', () async {
        when(
          () => mockLabelRepository.getOrCreateSystemLabel(
            SystemLabelType.pinned,
          ),
        ).thenThrow(Exception('Database error'));

        expect(
          () => seeder.seedAll(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
