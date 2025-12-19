import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/features/values/bloc/value_list_bloc.dart';

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

  blocTest<ValueOverviewBloc, ValueOverviewState>(
    'subscription requested emits loading then loaded when repository provides values',
    setUp: () {
      when(
        () => mockRepository.getValues,
      ).thenAnswer((_) => Stream.value([sampleValue]));
    },
    build: () => ValueOverviewBloc(valueRepository: mockRepository),
    act: (bloc) => bloc.add(ValuesSubscriptionRequested()),
    expect: () => <dynamic>[
      isA<ValueOverviewLoading>(),
      isA<ValueOverviewLoaded>(),
    ],
  );

  blocTest<ValueOverviewBloc, ValueOverviewState>(
    'subscription requested emits loading then error when repository stream errors',
    setUp: () {
      when(
        () => mockRepository.getValues,
      ).thenAnswer((_) => Stream.error(Exception('boom')));
    },
    build: () => ValueOverviewBloc(valueRepository: mockRepository),
    act: (bloc) => bloc.add(ValuesSubscriptionRequested()),
    expect: () => <dynamic>[
      isA<ValueOverviewLoading>(),
      isA<ValueOverviewError>(),
    ],
  );
}
