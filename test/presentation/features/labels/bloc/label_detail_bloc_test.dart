import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_helpers.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/labels/bloc/label_detail_bloc.dart';

class MockLabelRepositoryContract extends Mock
    implements LabelRepositoryContract {}

void main() {
  group('LabelDetailBloc', () {
    late MockLabelRepositoryContract mockLabelRepository;

    setUpAll(() {
      initializeTalkerForTest();
      registerFallbackValue(LabelType.label);
    });

    setUp(() {
      mockLabelRepository = MockLabelRepositoryContract();

      when(
        () => mockLabelRepository.getById(any()),
      ).thenAnswer((_) async => null);
      when(() => mockLabelRepository.delete(any())).thenAnswer((_) async {});
      when(
        () => mockLabelRepository.create(
          name: any(named: 'name'),
          color: any(named: 'color'),
          type: any(named: 'type'),
          iconName: any(named: 'iconName'),
        ),
      ).thenAnswer((_) async => 'new-label-id');
      when(
        () => mockLabelRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          color: any(named: 'color'),
          type: any(named: 'type'),
          iconName: any(named: 'iconName'),
        ),
      ).thenAnswer((_) async {});
    });

    Label createLabel({
      required String id,
      required String name,
    }) {
      final now = DateTime.now();
      return Label(
        id: id,
        name: name,
        createdAt: now,
        updatedAt: now,
      );
    }

    group('initial state', () {
      test('is LabelDetailInitial', () {
        final bloc = LabelDetailBloc(
          labelRepository: mockLabelRepository,
        );

        expect(bloc.state, isA<LabelDetailInitial>());
      });

      testSafe('automatically loads label when labelId is provided', () async {
        when(
          () => mockLabelRepository.getById('test-id'),
        ).thenAnswer((_) async => createLabel(id: 'test-id', name: 'Work'));

        final bloc = LabelDetailBloc(
          labelRepository: mockLabelRepository,
          labelId: 'test-id',
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(() => mockLabelRepository.getById('test-id')).called(1);
        expect(bloc.state, isA<LabelDetailLoadSuccess>());
        await bloc.close();
      });
    });

    group('LabelDetailGet', () {
      test(
        'emits load in progress then load success when label found',
        () async {
          when(
            () => mockLabelRepository.getById('test-id'),
          ).thenAnswer((_) async => createLabel(id: 'test-id', name: 'Work'));

          final bloc = LabelDetailBloc(
            labelRepository: mockLabelRepository,
          );

          bloc.add(const LabelDetailEvent.loadById(labelId: 'test-id'));
          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(bloc.state, isA<LabelDetailLoadSuccess>());
          final loadedState = bloc.state as LabelDetailLoadSuccess;
          expect(loadedState.label.id, 'test-id');
          expect(loadedState.label.name, 'Work');
          await bloc.close();
        },
      );

      test('emits operation failure when label not found', () async {
        when(
          () => mockLabelRepository.getById('missing-id'),
        ).thenAnswer((_) async => null);

        final bloc = LabelDetailBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(const LabelDetailEvent.loadById(labelId: 'missing-id'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<LabelDetailOperationFailure>());
        await bloc.close();
      });

      testSafe('emits operation failure when repository throws', () async {
        when(
          () => mockLabelRepository.getById('error-id'),
        ).thenThrow(Exception('Database error'));

        final bloc = LabelDetailBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(const LabelDetailEvent.loadById(labelId: 'error-id'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<LabelDetailOperationFailure>());
        await bloc.close();
      });
    });

    group('LabelDetailCreate', () {
      testSafe('calls create on repository with correct parameters', () async {
        final bloc = LabelDetailBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(
          const LabelDetailEvent.create(
            name: 'New Label',
            color: 'ff0000',
            type: LabelType.label,
            iconName: 'star',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => mockLabelRepository.create(
            name: 'New Label',
            color: 'ff0000',
            type: LabelType.label,
            iconName: 'star',
          ),
        ).called(1);
        await bloc.close();
      });

      testSafe('emits operation success on successful creation', () async {
        final bloc = LabelDetailBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(
          const LabelDetailEvent.create(
            name: 'New Label',
            color: 'ff0000',
            type: LabelType.label,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Allow bloc to process
        await Future.doWhile(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return bloc.state is LabelDetailInitial;
        }).timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        );

        expect(bloc.state, isA<LabelDetailOperationSuccess>());
        final successState = bloc.state as LabelDetailOperationSuccess;
        expect(successState.operation, EntityOperation.create);
        await bloc.close();
      });

      testSafe('emits operation failure when create throws', () async {
        when(
          () => mockLabelRepository.create(
            name: any(named: 'name'),
            color: any(named: 'color'),
            type: any(named: 'type'),
            iconName: any(named: 'iconName'),
          ),
        ).thenThrow(Exception('Creation failed'));

        final bloc = LabelDetailBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(
          const LabelDetailEvent.create(
            name: 'New Label',
            color: 'ff0000',
            type: LabelType.label,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<LabelDetailOperationFailure>());
        await bloc.close();
      });
    });

    group('LabelDetailUpdate', () {
      testSafe('calls update on repository with correct parameters', () async {
        final bloc = LabelDetailBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(
          const LabelDetailEvent.update(
            id: 'label-1',
            name: 'Updated Label',
            color: '00ff00',
            type: LabelType.value,
            iconName: 'heart',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => mockLabelRepository.update(
            id: 'label-1',
            name: 'Updated Label',
            color: '00ff00',
            type: LabelType.value,
            iconName: 'heart',
          ),
        ).called(1);
        await bloc.close();
      });

      testSafe('emits operation success on successful update', () async {
        final bloc = LabelDetailBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(
          const LabelDetailEvent.update(
            id: 'label-1',
            name: 'Updated Label',
            color: '00ff00',
            type: LabelType.label,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Allow bloc to process
        await Future.doWhile(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return bloc.state is LabelDetailInitial;
        }).timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        );

        expect(bloc.state, isA<LabelDetailOperationSuccess>());
        final successState = bloc.state as LabelDetailOperationSuccess;
        expect(successState.operation, EntityOperation.update);
        await bloc.close();
      });

      testSafe('emits operation failure when update throws', () async {
        when(
          () => mockLabelRepository.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            color: any(named: 'color'),
            type: any(named: 'type'),
            iconName: any(named: 'iconName'),
          ),
        ).thenThrow(Exception('Update failed'));

        final bloc = LabelDetailBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(
          const LabelDetailEvent.update(
            id: 'label-1',
            name: 'Updated Label',
            color: '00ff00',
            type: LabelType.label,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<LabelDetailOperationFailure>());
        await bloc.close();
      });
    });

    group('LabelDetailDelete', () {
      testSafe('calls delete on repository', () async {
        final bloc = LabelDetailBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(const LabelDetailEvent.delete(id: 'label-1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(() => mockLabelRepository.delete('label-1')).called(1);
        await bloc.close();
      });

      testSafe('emits operation success on successful delete', () async {
        final bloc = LabelDetailBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(const LabelDetailEvent.delete(id: 'label-1'));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Allow bloc to process
        await Future.doWhile(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return bloc.state is LabelDetailInitial;
        }).timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        );

        expect(bloc.state, isA<LabelDetailOperationSuccess>());
        final successState = bloc.state as LabelDetailOperationSuccess;
        expect(successState.operation, EntityOperation.delete);
        await bloc.close();
      });

      testSafe('emits operation failure when delete throws', () async {
        when(
          () => mockLabelRepository.delete(any()),
        ).thenThrow(Exception('Delete failed'));

        final bloc = LabelDetailBloc(
          labelRepository: mockLabelRepository,
        );

        bloc.add(const LabelDetailEvent.delete(id: 'label-1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<LabelDetailOperationFailure>());
        await bloc.close();
      });
    });

    group('lifecycle', () {
      testSafe('closes cleanly', () async {
        final bloc = LabelDetailBloc(
          labelRepository: mockLabelRepository,
        );

        await bloc.close();
        // No assertion needed - just verify no exceptions
      });
    });
  });
}
