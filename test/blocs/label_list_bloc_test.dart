import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/features/labels/bloc/label_list_bloc.dart';

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

  blocTest<LabelOverviewBloc, LabelOverviewState>(
    'subscription requested emits loading then loaded when repository provides labels',
    setUp: () {
      when(
        () => mockRepository.watchAll(),
      ).thenAnswer((_) => Stream.value([sampleLabel]));
    },
    build: () => LabelOverviewBloc(labelRepository: mockRepository),
    act: (bloc) =>
        bloc.add(const LabelOverviewEvent.labelsSubscriptionRequested()),
    expect: () => <dynamic>[
      isA<LabelOverviewLoading>(),
      isA<LabelOverviewLoaded>(),
    ],
  );

  blocTest<LabelOverviewBloc, LabelOverviewState>(
    'subscription requested emits loading then error when repository stream errors',
    setUp: () {
      when(
        () => mockRepository.watchAll(),
      ).thenAnswer((_) => Stream<List<Label>>.error(Exception('boom')));
    },
    build: () => LabelOverviewBloc(labelRepository: mockRepository),
    act: (bloc) =>
        bloc.add(const LabelOverviewEvent.labelsSubscriptionRequested()),
    expect: () => <dynamic>[
      isA<LabelOverviewLoading>(),
      isA<LabelOverviewError>(),
    ],
  );
}
