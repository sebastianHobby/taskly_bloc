import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_detail_bloc.dart';

import '../helpers/base_repository_helpers.dart';
import '../mocks/fake_id_generator.dart';

void main() {
  group('ValueDetailBloc (integration)', () {
    late RepositoryTestContext ctx;
    late FakeIdGenerator idGenerator;

    late ValueRepository valueRepository;

    setUp(() {
      ctx = RepositoryTestContext();
      idGenerator = FakeIdGenerator();
      valueRepository = ValueRepository(
        driftDb: ctx.db,
        idGenerator: idGenerator,
      );
    });

    tearDown(() async {
      await ctx.dispose();
    });

    blocTest<ValueDetailBloc, ValueDetailState>(
      'loadById loads value from Drift',
      tags: 'integration',
      setUp: () async {
        await valueRepository.create(
          name: 'Health',
          color: '#00FF00',
          priority: ValuePriority.medium,
        );
      },
      build: () => ValueDetailBloc(valueRepository: valueRepository),
      act: (bloc) =>
          bloc.add(const ValueDetailEvent.loadById(valueId: 'value-health')),
      expect: () => [
        const ValueDetailLoadInProgress(),
        isA<ValueDetailLoadSuccess>()
            .having((s) => s.value.id, 'value.id', 'value-health')
            .having((s) => s.value.name, 'value.name', 'Health')
            .having((s) => s.value.color, 'value.color', '#00FF00')
            .having(
              (s) => s.value.priority,
              'value.priority',
              ValuePriority.medium,
            ),
      ],
    );
  });
}
