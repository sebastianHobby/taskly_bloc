@Tags(['unit', 'bloc', 'labels'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/not_found_entity.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/labels/bloc/label_detail_bloc.dart';

import '../../../../fixtures/test_data.dart';
import '../../../../helpers/custom_matchers.dart';
import '../../../../helpers/fallback_values.dart';
import '../../../../mocks/repository_mocks.dart';

/// Tests for [LabelDetailBloc] covering label CRUD operations.
///
/// Coverage:
/// - ✅ Initialization
/// - ✅ Auto-loading when labelId provided
/// - ✅ Loading label data
/// - ✅ Creating new labels
/// - ✅ Updating existing labels
/// - ✅ Deleting labels
/// - ✅ Error handling for all operations
void main() {
  late MockLabelRepositoryContract mockLabelRepo;

  setUpAll(registerAllFallbackValues);

  setUp(() {
    mockLabelRepo = MockLabelRepositoryContract();
  });

  group('LabelDetailBloc', () {
    group('initialization', () {
      test('initial state is LabelDetailInitial when no labelId', () {
        final bloc = LabelDetailBloc(labelRepository: mockLabelRepo);

        expect(bloc.state, isInitialState());
        bloc.close();
      });

      blocTest<LabelDetailBloc, LabelDetailState>(
        'auto-loads label when labelId is provided',
        build: () {
          final label = TestData.label(id: 'label-1');
          when(
            () => mockLabelRepo.get('label-1'),
          ).thenAnswer((_) async => label);

          return LabelDetailBloc(
            labelRepository: mockLabelRepo,
            labelId: 'label-1',
          );
        },
        expect: () => [
          isLoadingState(),
          isA<LabelDetailLoadSuccess>().having(
            (s) => s.label.id,
            'label.id',
            'label-1',
          ),
        ],
      );
    });

    group('get event', () {
      blocTest<LabelDetailBloc, LabelDetailState>(
        'emits [loading, success] when label exists',
        build: () {
          final label = TestData.label(
            id: 'label-1',
            name: 'Important',
            color: '#FF0000',
          );
          when(
            () => mockLabelRepo.get('label-1'),
          ).thenAnswer((_) async => label);

          return LabelDetailBloc(labelRepository: mockLabelRepo);
        },
        act: (bloc) => bloc.add(const LabelDetailEvent.get(labelId: 'label-1')),
        expect: () => [
          isLoadingState(),
          isA<LabelDetailLoadSuccess>()
              .having((s) => s.label.id, 'label.id', 'label-1')
              .having((s) => s.label.name, 'label.name', 'Important')
              .having((s) => s.label.color, 'label.color', '#FF0000'),
        ],
      );

      blocTest<LabelDetailBloc, LabelDetailState>(
        'emits failure when label not found',
        build: () {
          when(
            () => mockLabelRepo.get('nonexistent'),
          ).thenAnswer((_) async => null);

          return LabelDetailBloc(labelRepository: mockLabelRepo);
        },
        act: (bloc) =>
            bloc.add(const LabelDetailEvent.get(labelId: 'nonexistent')),
        expect: () => [
          isLoadingState(),
          predicate<LabelDetailOperationFailure>(
            (state) => state.errorDetails.error == NotFoundEntity.label,
          ),
        ],
      );

      blocTest<LabelDetailBloc, LabelDetailState>(
        'emits failure on repository error',
        build: () {
          when(
            () => mockLabelRepo.get(any()),
          ).thenThrow(Exception('Database error'));

          return LabelDetailBloc(labelRepository: mockLabelRepo);
        },
        act: (bloc) => bloc.add(const LabelDetailEvent.get(labelId: 'label-1')),
        expect: () => [
          isLoadingState(),
          isOperationFailureState(),
        ],
      );
    });

    group('create event', () {
      blocTest<LabelDetailBloc, LabelDetailState>(
        'emits success on successful creation',
        build: () {
          when(
            () => mockLabelRepo.create(
              name: any(named: 'name'),
              color: any(named: 'color'),
              type: any(named: 'type'),
              iconName: any(named: 'iconName'),
            ),
          ).thenAnswer((_) async {});

          return LabelDetailBloc(labelRepository: mockLabelRepo);
        },
        act: (bloc) => bloc.add(
          const LabelDetailEvent.create(
            name: 'New Label',
            color: '#00FF00',
            type: LabelType.label,
          ),
        ),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<LabelDetailOperationSuccess>().having(
            (s) => s.operation,
            'operation',
            EntityOperation.create,
          ),
        ],
        verify: (_) {
          verify(
            () => mockLabelRepo.create(
              name: 'New Label',
              color: '#00FF00',
              type: LabelType.label,
            ),
          ).called(1);
        },
      );

      blocTest<LabelDetailBloc, LabelDetailState>(
        'creates label with icon when provided',
        build: () {
          when(
            () => mockLabelRepo.create(
              name: any(named: 'name'),
              color: any(named: 'color'),
              type: any(named: 'type'),
              iconName: any(named: 'iconName'),
            ),
          ).thenAnswer((_) async {});

          return LabelDetailBloc(labelRepository: mockLabelRepo);
        },
        act: (bloc) => bloc.add(
          const LabelDetailEvent.create(
            name: 'Value Label',
            color: '#0000FF',
            type: LabelType.value,
            iconName: 'star',
          ),
        ),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isOperationSuccessState(),
        ],
        verify: (_) {
          verify(
            () => mockLabelRepo.create(
              name: 'Value Label',
              color: '#0000FF',
              type: LabelType.value,
              iconName: 'star',
            ),
          ).called(1);
        },
      );

      blocTest<LabelDetailBloc, LabelDetailState>(
        'emits failure on creation error',
        build: () {
          when(
            () => mockLabelRepo.create(
              name: any(named: 'name'),
              color: any(named: 'color'),
              type: any(named: 'type'),
              iconName: any(named: 'iconName'),
            ),
          ).thenThrow(Exception('Create failed'));

          return LabelDetailBloc(labelRepository: mockLabelRepo);
        },
        act: (bloc) => bloc.add(
          const LabelDetailEvent.create(
            name: 'New Label',
            color: '#FF0000',
            type: LabelType.label,
          ),
        ),
        expect: () => [
          isOperationFailureState(),
        ],
      );
    });

    group('update event', () {
      blocTest<LabelDetailBloc, LabelDetailState>(
        'emits success on successful update',
        build: () {
          when(
            () => mockLabelRepo.update(
              id: any(named: 'id'),
              name: any(named: 'name'),
              color: any(named: 'color'),
              type: any(named: 'type'),
              iconName: any(named: 'iconName'),
            ),
          ).thenAnswer((_) async {});

          return LabelDetailBloc(labelRepository: mockLabelRepo);
        },
        act: (bloc) => bloc.add(
          const LabelDetailEvent.update(
            id: 'label-1',
            name: 'Updated Label',
            color: '#FFFFFF',
            type: LabelType.value,
          ),
        ),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<LabelDetailOperationSuccess>().having(
            (s) => s.operation,
            'operation',
            EntityOperation.update,
          ),
        ],
        verify: (_) {
          verify(
            () => mockLabelRepo.update(
              id: 'label-1',
              name: 'Updated Label',
              color: '#FFFFFF',
              type: LabelType.value,
            ),
          ).called(1);
        },
      );

      blocTest<LabelDetailBloc, LabelDetailState>(
        'emits failure on update error',
        build: () {
          when(
            () => mockLabelRepo.update(
              id: any(named: 'id'),
              name: any(named: 'name'),
              color: any(named: 'color'),
              type: any(named: 'type'),
              iconName: any(named: 'iconName'),
            ),
          ).thenThrow(Exception('Update failed'));

          return LabelDetailBloc(labelRepository: mockLabelRepo);
        },
        act: (bloc) => bloc.add(
          const LabelDetailEvent.update(
            id: 'label-1',
            name: 'Updated',
            color: '#000000',
            type: LabelType.label,
          ),
        ),
        expect: () => [
          isOperationFailureState(),
        ],
      );
    });

    group('delete event', () {
      blocTest<LabelDetailBloc, LabelDetailState>(
        'emits success on successful deletion',
        build: () {
          when(() => mockLabelRepo.delete(any())).thenAnswer((_) async {});

          return LabelDetailBloc(labelRepository: mockLabelRepo);
        },
        act: (bloc) => bloc.add(const LabelDetailEvent.delete(id: 'label-1')),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<LabelDetailOperationSuccess>().having(
            (s) => s.operation,
            'operation',
            EntityOperation.delete,
          ),
        ],
        verify: (_) {
          verify(() => mockLabelRepo.delete('label-1')).called(1);
        },
      );

      blocTest<LabelDetailBloc, LabelDetailState>(
        'emits failure on deletion error',
        build: () {
          when(
            () => mockLabelRepo.delete(any()),
          ).thenThrow(Exception('Delete failed'));

          return LabelDetailBloc(labelRepository: mockLabelRepo);
        },
        act: (bloc) => bloc.add(const LabelDetailEvent.delete(id: 'label-1')),
        expect: () => [
          isOperationFailureState(),
        ],
      );
    });
  });
}
