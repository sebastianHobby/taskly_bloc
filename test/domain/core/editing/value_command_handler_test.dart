@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/telemetry.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('ValueCommandHandler', () {
    late MockValueRepositoryContract repo;
    late ValueCommandHandler handler;

    setUp(() {
      repo = MockValueRepositoryContract();
      when(() => repo.getCount()).thenAnswer((_) async => 0);
      handler = ValueCommandHandler(valueRepository: repo);
      when(() => repo.create(
            name: any(named: 'name'),
            color: any(named: 'color'),
            priority: any(named: 'priority'),
            iconName: any(named: 'iconName'),
            context: any(named: 'context'),
          ))
          .thenAnswer((_) async {});
      when(() => repo.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            color: any(named: 'color'),
            priority: any(named: 'priority'),
            iconName: any(named: 'iconName'),
            context: any(named: 'context'),
          ))
          .thenAnswer((_) async {});
    });

    testSafe('handleCreate trims name and forwards context', () async {
      const context = OperationContext(
        correlationId: 'c1',
        feature: 'values',
        intent: 'value_create',
        operation: 'value.create',
      );

      final result = await handler.handleCreate(
        const CreateValueCommand(
          name: '  Focus  ',
          color: '#FF0000',
          priority: ValuePriority.high,
          iconName: 'star',
        ),
        context: context,
      );

      expect(result, isA<CommandSuccess>());
      verify(
        () => repo.create(
          name: 'Focus',
          color: '#FF0000',
          priority: ValuePriority.high,
          iconName: 'star',
          context: context,
        ),
      ).called(1);
    });

    testSafe('handleUpdate rejects empty name', () async {
      final result = await handler.handleUpdate(
        const UpdateValueCommand(
          id: 'v1',
          name: ' ',
          color: '#FFFFFF',
          priority: ValuePriority.medium,
        ),
      );

      expect(result, isA<CommandValidationFailure>());
      verifyNever(
        () => repo.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          color: any(named: 'color'),
          priority: any(named: 'priority'),
          iconName: any(named: 'iconName'),
          context: any(named: 'context'),
        ),
      );
    });

    testSafe('handleCreate rejects empty color', () async {
      final result = await handler.handleCreate(
        const CreateValueCommand(
          name: 'Value',
          color: '  ',
          priority: ValuePriority.low,
        ),
      );

      expect(result, isA<CommandValidationFailure>());
      verifyNever(
        () => repo.create(
          name: any(named: 'name'),
          color: any(named: 'color'),
          priority: any(named: 'priority'),
          iconName: any(named: 'iconName'),
          context: any(named: 'context'),
        ),
      );
    });

    testSafe('handleUpdate rejects empty iconName', () async {
      final result = await handler.handleUpdate(
        const UpdateValueCommand(
          id: 'v1',
          name: 'Value',
          color: '#FFFFFF',
          priority: ValuePriority.medium,
          iconName: ' ',
        ),
      );

      expect(result, isA<CommandValidationFailure>());
      verifyNever(
        () => repo.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          color: any(named: 'color'),
          priority: any(named: 'priority'),
          iconName: any(named: 'iconName'),
          context: any(named: 'context'),
        ),
      );
    });

    testSafe('handleCreate rejects name over 120 chars', () async {
      final longName = List.filled(121, 'a').join();

      final result = await handler.handleCreate(
        CreateValueCommand(
          name: longName,
          color: '#FFFFFF',
          priority: ValuePriority.medium,
        ),
      );

      expect(result, isA<CommandValidationFailure>());
    });
  });
}
