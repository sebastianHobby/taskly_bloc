import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/features/labels/bloc/label_detail_bloc.dart';

class MockLabelRepository extends Mock implements LabelRepositoryContract {}

void main() {
  late MockLabelRepository mockRepository;
  late Label sampleLabel;

  setUp(() {
    mockRepository = MockLabelRepository();
    final now = DateTime.now();
    sampleLabel = Label(
      id: 'l1',
      createdAt: now,
      updatedAt: now,
      name: 'Label 1',
    );
  });

  blocTest<LabelDetailBloc, LabelDetailState>(
    'get emits loadInProgress then loadSuccess when repository returns a label',
    setUp: () {
      when(
        () => mockRepository.get('l1'),
      ).thenAnswer((_) async => sampleLabel);
    },
    build: () =>
        LabelDetailBloc(labelRepository: mockRepository, labelId: 'l1'),
    expect: () => <dynamic>[
      const LabelDetailState.loadInProgress(),
      isA<LabelDetailLoadSuccess>(),
    ],
  );

  blocTest<LabelDetailBloc, LabelDetailState>(
    'get emits operationFailure when repository returns null',
    setUp: () {
      when(() => mockRepository.get('l1')).thenAnswer((_) async => null);
    },
    build: () =>
        LabelDetailBloc(labelRepository: mockRepository, labelId: 'l1'),
    expect: () => <dynamic>[
      const LabelDetailState.loadInProgress(),
      isA<LabelDetailOperationFailure>(),
    ],
  );

  blocTest<LabelDetailBloc, LabelDetailState>(
    'get emits operationFailure when repository throws',
    setUp: () {
      when(
        () => mockRepository.get('l1'),
      ).thenAnswer((_) async => throw Exception('boom'));
    },
    build: () =>
        LabelDetailBloc(labelRepository: mockRepository, labelId: 'l1'),
    expect: () => <dynamic>[
      const LabelDetailState.loadInProgress(),
      isA<LabelDetailOperationFailure>(),
    ],
  );

  blocTest<LabelDetailBloc, LabelDetailState>(
    'create emits operationSuccess on successful create',
    setUp: () {
      when(
        () => mockRepository.create(name: any(named: 'name')),
      ).thenAnswer((_) async {});
    },
    build: () => LabelDetailBloc(labelRepository: mockRepository),
    act: (bloc) => bloc.add(const LabelDetailEvent.create(name: 'New')),
    expect: () => <dynamic>[
      const LabelDetailState.operationSuccess(
        operation: EntityOperation.create,
      ),
    ],
  );

  blocTest<LabelDetailBloc, LabelDetailState>(
    'create emits operationFailure when create throws',
    setUp: () {
      when(
        () => mockRepository.create(name: any(named: 'name')),
      ).thenAnswer((_) async => throw Exception('fail'));
    },
    build: () => LabelDetailBloc(labelRepository: mockRepository),
    act: (bloc) => bloc.add(const LabelDetailEvent.create(name: 'New')),
    expect: () => <dynamic>[isA<LabelDetailOperationFailure>()],
  );

  blocTest<LabelDetailBloc, LabelDetailState>(
    'update emits operationSuccess on successful update',
    setUp: () {
      when(
        () => mockRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async {});
    },
    build: () => LabelDetailBloc(labelRepository: mockRepository),
    act: (bloc) =>
        bloc.add(const LabelDetailEvent.update(id: 'l1', name: 'Updated')),
    expect: () => <dynamic>[
      const LabelDetailState.operationSuccess(
        operation: EntityOperation.update,
      ),
    ],
  );

  blocTest<LabelDetailBloc, LabelDetailState>(
    'update emits operationFailure when update throws',
    setUp: () {
      when(
        () => mockRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async => throw Exception('bad'));
    },
    build: () => LabelDetailBloc(labelRepository: mockRepository),
    act: (bloc) =>
        bloc.add(const LabelDetailEvent.update(id: 'l1', name: 'Updated')),
    expect: () => <dynamic>[isA<LabelDetailOperationFailure>()],
  );

  blocTest<LabelDetailBloc, LabelDetailState>(
    'delete emits operationSuccess on successful delete',
    setUp: () {
      when(() => mockRepository.delete(any())).thenAnswer((_) async {});
    },
    build: () => LabelDetailBloc(labelRepository: mockRepository),
    act: (bloc) => bloc.add(const LabelDetailEvent.delete(id: 'l1')),
    expect: () => <dynamic>[
      const LabelDetailState.operationSuccess(
        operation: EntityOperation.delete,
      ),
    ],
  );

  blocTest<LabelDetailBloc, LabelDetailState>(
    'delete emits operationFailure when delete throws',
    setUp: () {
      when(
        () => mockRepository.delete(any()),
      ).thenAnswer((_) async => throw Exception('oh no'));
    },
    build: () => LabelDetailBloc(labelRepository: mockRepository),
    act: (bloc) => bloc.add(const LabelDetailEvent.delete(id: 'l1')),
    expect: () => <dynamic>[isA<LabelDetailOperationFailure>()],
  );
}
