import '../helpers/test_imports.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_list_bloc.dart';

import '../helpers/base_repository_helpers.dart';
import '../mocks/fake_id_generator.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('ValueListBloc (integration)', () {
    late RepositoryTestContext ctx;
    late FakeIdGenerator idGenerator;
    late ValueRepository valueRepository;

    setUp(() {
      ctx = RepositoryTestContext();
      addTearDown(ctx.dispose);
      idGenerator = FakeIdGenerator();
      valueRepository = ValueRepository(
        driftDb: ctx.db,
        idGenerator: idGenerator,
      );
    });

    blocTest<ValueListBloc, ValueListState>(
      'subscriptionRequested streams values from Drift and sorts by name',
      tags: 'integration',
      setUp: () async {
        await valueRepository.create(
          name: 'Beta',
          color: '#111111',
        );
        await valueRepository.create(
          name: 'alpha',
          color: '#222222',
        );
      },
      build: () => ValueListBloc(valueRepository: valueRepository),
      act: (bloc) => bloc.add(const ValueListEvent.subscriptionRequested()),
      expect: () => [
        const ValueListLoading(),
        isA<ValueListLoaded>().having(
          (s) => s.values.map((v) => v.name).toList(growable: false),
          'names',
          ['alpha', 'Beta'],
        ),
      ],
    );

    blocTest<ValueListBloc, ValueListState>(
      'deleteValue updates list via subscription stream',
      tags: 'integration',
      setUp: () async {
        await valueRepository.create(
          name: 'Delete Me',
          color: '#FF0000',
          priority: ValuePriority.high,
        );
        await valueRepository.create(
          name: 'Keep Me',
          color: '#00FF00',
          priority: ValuePriority.medium,
        );
      },
      build: () => ValueListBloc(valueRepository: valueRepository),
      act: (bloc) async {
        bloc.add(const ValueListEvent.subscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final state = bloc.state;
        final values = state is ValueListLoaded
            ? state.values
            : const <Value>[];
        final toDelete = values.firstWhere((v) => v.name == 'Delete Me');
        bloc.add(ValueListEvent.deleteValue(value: toDelete));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        const ValueListLoading(),
        isA<ValueListLoaded>(),
        isA<ValueListLoaded>().having(
          (s) => s.values.map((v) => v.name).toList(growable: false),
          'names',
          ['Keep Me'],
        ),
      ],
    );
  });
}
