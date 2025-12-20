import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/domain/value.dart';
import 'package:taskly_bloc/data/repositories/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/values/bloc/value_list_bloc.dart';

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

  blocTest<ValueOverviewBloc, ValueOverviewState>(
    'subscription requested emits loading then loaded when repository provides values',
    setUp: () {
      when(
        () => mockRepository.watchAll(),
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
        () => mockRepository.watchAll(),
      ).thenAnswer((_) => Stream<List<ValueModel>>.error(Exception('boom')));
    },
    build: () => ValueOverviewBloc(valueRepository: mockRepository),
    act: (bloc) => bloc.add(ValuesSubscriptionRequested()),
    expect: () => <dynamic>[
      isA<ValueOverviewLoading>(),
      isA<ValueOverviewError>(),
    ],
  );
}
