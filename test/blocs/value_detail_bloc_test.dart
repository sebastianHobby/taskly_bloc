import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/values/bloc/value_detail_bloc.dart';

class MockValueRepository extends Mock implements ValueRepositoryContract {}

void main() {
  late MockValueRepository mockRepository;
  late ValueModel sampleValue;

  setUp(() {
    mockRepository = MockValueRepository();
    final now = DateTime.now();
    sampleValue = ValueModel(
      id: 'v1',
      createdAt: now,
      updatedAt: now,
      name: 'Value 1',
    );
  });

  blocTest<ValueDetailBloc, ValueDetailState>(
    'get emits loadInProgress then loadSuccess when repository returns a value',
    setUp: () {
      when(
        () => mockRepository.get('v1'),
      ).thenAnswer((_) async => sampleValue);
    },
    build: () =>
        ValueDetailBloc(valueRepository: mockRepository, valueId: 'v1'),
    expect: () => <dynamic>[
      const ValueDetailState.loadInProgress(),
      isA<ValueDetailLoadSuccess>(),
    ],
  );

  blocTest<ValueDetailBloc, ValueDetailState>(
    'get emits operationFailure when repository returns null',
    setUp: () {
      when(() => mockRepository.get('v1')).thenAnswer((_) async => null);
    },
    build: () =>
        ValueDetailBloc(valueRepository: mockRepository, valueId: 'v1'),
    expect: () => <dynamic>[
      const ValueDetailState.loadInProgress(),
      isA<ValueDetailOperationFailure>(),
    ],
  );

  blocTest<ValueDetailBloc, ValueDetailState>(
    'get emits operationFailure when repository throws',
    setUp: () {
      when(
        () => mockRepository.get('v1'),
      ).thenAnswer((_) async => throw Exception('boom'));
    },
    build: () =>
        ValueDetailBloc(valueRepository: mockRepository, valueId: 'v1'),
    expect: () => <dynamic>[
      const ValueDetailState.loadInProgress(),
      isA<ValueDetailOperationFailure>(),
    ],
  );

  blocTest<ValueDetailBloc, ValueDetailState>(
    'create emits operationSuccess on successful create',
    setUp: () {
      when(
        () => mockRepository.create(name: any(named: 'name')),
      ).thenAnswer((_) async {});
    },
    build: () => ValueDetailBloc(valueRepository: mockRepository),
    act: (bloc) => bloc.add(const ValueDetailEvent.create(name: 'New')),
    expect: () => <dynamic>[
      const ValueDetailState.operationSuccess(
        operation: EntityOperation.create,
      ),
    ],
  );

  blocTest<ValueDetailBloc, ValueDetailState>(
    'create emits operationFailure when create throws',
    setUp: () {
      when(
        () => mockRepository.create(name: any(named: 'name')),
      ).thenAnswer((_) async => throw Exception('fail'));
    },
    build: () => ValueDetailBloc(valueRepository: mockRepository),
    act: (bloc) => bloc.add(const ValueDetailEvent.create(name: 'New')),
    expect: () => <dynamic>[isA<ValueDetailOperationFailure>()],
  );

  blocTest<ValueDetailBloc, ValueDetailState>(
    'update emits operationSuccess on successful update',
    setUp: () {
      when(
        () => mockRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async {});
    },
    build: () => ValueDetailBloc(valueRepository: mockRepository),
    act: (bloc) =>
        bloc.add(const ValueDetailEvent.update(id: 'v1', name: 'Updated')),
    expect: () => <dynamic>[
      const ValueDetailState.operationSuccess(
        operation: EntityOperation.update,
      ),
    ],
  );

  blocTest<ValueDetailBloc, ValueDetailState>(
    'update emits operationFailure when update throws',
    setUp: () {
      when(
        () => mockRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async => throw Exception('bad'));
    },
    build: () => ValueDetailBloc(valueRepository: mockRepository),
    act: (bloc) =>
        bloc.add(const ValueDetailEvent.update(id: 'v1', name: 'Updated')),
    expect: () => <dynamic>[isA<ValueDetailOperationFailure>()],
  );

  blocTest<ValueDetailBloc, ValueDetailState>(
    'delete emits operationSuccess on successful delete',
    setUp: () {
      when(() => mockRepository.delete(any())).thenAnswer((_) async {});
    },
    build: () => ValueDetailBloc(valueRepository: mockRepository),
    act: (bloc) => bloc.add(const ValueDetailEvent.delete(id: 'v1')),
    expect: () => <dynamic>[
      const ValueDetailState.operationSuccess(
        operation: EntityOperation.delete,
      ),
    ],
  );

  blocTest<ValueDetailBloc, ValueDetailState>(
    'delete emits operationFailure when delete throws',
    setUp: () {
      when(
        () => mockRepository.delete(any()),
      ).thenAnswer((_) async => throw Exception('oh no'));
    },
    build: () => ValueDetailBloc(valueRepository: mockRepository),
    act: (bloc) => bloc.add(const ValueDetailEvent.delete(id: 'v1')),
    expect: () => <dynamic>[isA<ValueDetailOperationFailure>()],
  );
}
