import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/features/values/bloc/value_detail_bloc.dart';

class MockValueRepository extends Mock implements ValueRepository {}

void main() {
  late MockValueRepository mockRepository;
  late ValueTableData sampleValue;

  setUpAll(() {
    registerFallbackValue(ValueTableCompanion(id: const Value('f')));
  });

  setUp(() {
    mockRepository = MockValueRepository();
    sampleValue = ValueTableData(
      id: 'v1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: 'Value 1',
    );
  });

  blocTest<ValueDetailBloc, ValueDetailState>(
    'get emits loadInProgress then loadSuccess when repository returns a value',
    setUp: () {
      when(
        () => mockRepository.getValueById('v1'),
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
      when(
        () => mockRepository.getValueById('v1'),
      ).thenAnswer((_) async => null);
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
        () => mockRepository.getValueById('v1'),
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
      when(() => mockRepository.createValue(any())).thenAnswer((_) async => 1);
    },
    build: () => ValueDetailBloc(valueRepository: mockRepository),
    act: (bloc) => bloc.add(const ValueDetailEvent.create(name: 'New')),
    expect: () => <dynamic>[
      const ValueDetailState.operationSuccess(
        message: 'Value created successfully.',
      ),
    ],
  );

  blocTest<ValueDetailBloc, ValueDetailState>(
    'create emits operationFailure when create throws',
    setUp: () {
      when(
        () => mockRepository.createValue(any()),
      ).thenAnswer((_) async => throw Exception('fail'));
    },
    build: () => ValueDetailBloc(valueRepository: mockRepository),
    act: (bloc) => bloc.add(const ValueDetailEvent.create(name: 'New')),
    expect: () => <dynamic>[isA<ValueDetailOperationFailure>()],
  );

  blocTest<ValueDetailBloc, ValueDetailState>(
    'update emits operationSuccess on successful update',
    setUp: () {
      when(() => mockRepository.updateValue(any())).thenAnswer((_) async => 1);
    },
    build: () => ValueDetailBloc(valueRepository: mockRepository),
    act: (bloc) =>
        bloc.add(const ValueDetailEvent.update(id: 'v1', name: 'Updated')),
    expect: () => <dynamic>[
      const ValueDetailState.operationSuccess(
        message: 'Value updated successfully.',
      ),
    ],
  );

  blocTest<ValueDetailBloc, ValueDetailState>(
    'update emits operationFailure when update throws',
    setUp: () {
      when(
        () => mockRepository.updateValue(any()),
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
      when(() => mockRepository.deleteValue(any())).thenAnswer((_) async => 1);
    },
    build: () => ValueDetailBloc(valueRepository: mockRepository),
    act: (bloc) => bloc.add(const ValueDetailEvent.delete(id: 'v1')),
    expect: () => <dynamic>[
      const ValueDetailState.operationSuccess(
        message: 'Value deleted successfully.',
      ),
    ],
  );

  blocTest<ValueDetailBloc, ValueDetailState>(
    'delete emits operationFailure when delete throws',
    setUp: () {
      when(
        () => mockRepository.deleteValue(any()),
      ).thenAnswer((_) async => throw Exception('oh no'));
    },
    build: () => ValueDetailBloc(valueRepository: mockRepository),
    act: (bloc) => bloc.add(const ValueDetailEvent.delete(id: 'v1')),
    expect: () => <dynamic>[isA<ValueDetailOperationFailure>()],
  );
}
