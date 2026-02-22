@Tags(['unit'])
library;

import '../../../../helpers/test_imports.dart';

import 'package:taskly_domain/src/core/editing/command_result.dart';
import 'package:taskly_domain/src/core/editing/value/value_command_handler.dart';
import 'package:taskly_domain/src/core/editing/value/value_commands.dart';
import 'package:taskly_domain/core/model/value_priority.dart';
import 'package:taskly_domain/src/forms/field_key.dart';
import 'package:taskly_domain/src/interfaces/value_repository_contract.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

void main() {
  testSafe(
    'handleCreate validates name/color/iconName and does not call repo',
    () async {
      final repo = _RecordingValueRepository();
      final handler = ValueCommandHandler(valueRepository: repo);

      const cmd = CreateValueCommand(
        name: '   ',
        color: '   ',
        priority: ValuePriority.medium,
        iconName: '   ',
      );

      final result = await handler.handleCreate(cmd);

      expect(result, isA<CommandValidationFailure>());
      final failure = (result as CommandValidationFailure).failure;

      expect(failure.fieldErrors.keys, contains(ValueFieldKeys.name));
      expect(failure.fieldErrors.keys, contains(ValueFieldKeys.colour));
      expect(failure.fieldErrors.keys, contains(ValueFieldKeys.iconName));
      expect(repo.createCalls, 0);
    },
  );

  testSafe('handleCreate trims name and forwards args to repository', () async {
    final repo = _RecordingValueRepository();
    final handler = ValueCommandHandler(valueRepository: repo);

    final ctx = OperationContext(
      correlationId: 'c_create',
      feature: 'test',
      intent: 'create_value',
      operation: 'value.create',
    );

    const cmd = CreateValueCommand(
      name: '  Name  ',
      color: '#fff',
      priority: ValuePriority.high,
      iconName: 'star',
    );

    final result = await handler.handleCreate(cmd, context: ctx);

    expect(result, isA<CommandSuccess>());
    expect(repo.createCalls, 1);
    expect(repo.lastCreatedName, 'Name');
    expect(repo.lastCreatedColor, '#fff');
    expect(repo.lastCreatedIconName, 'star');
    expect(repo.lastCreatedPriority, ValuePriority.high);
    expect(repo.lastCreatedContext, ctx);
  });

  testSafe('handleCreate validates max length for name', () async {
    final repo = _RecordingValueRepository();
    final handler = ValueCommandHandler(valueRepository: repo);

    final cmd = CreateValueCommand(
      name: List.filled(121, 'a').join(),
      color: '#fff',
      priority: ValuePriority.medium,
      iconName: 'star',
    );

    final result = await handler.handleCreate(cmd);

    expect(result, isA<CommandValidationFailure>());
    final failure = (result as CommandValidationFailure).failure;
    expect(failure.fieldErrors.keys, contains(ValueFieldKeys.name));
    expect(repo.createCalls, 0);
  });

  testSafe('handleUpdate trims name and forwards args to repository', () async {
    final repo = _RecordingValueRepository();
    final handler = ValueCommandHandler(valueRepository: repo);

    final ctx = OperationContext(
      correlationId: 'c1',
      feature: 'test',
      intent: 'update_value',
      operation: 'value.update',
    );

    const cmd = UpdateValueCommand(
      id: 'v1',
      name: '  Name  ',
      color: '#fff',
      priority: ValuePriority.high,
      iconName: 'star',
    );

    final result = await handler.handleUpdate(cmd, context: ctx);

    expect(result, isA<CommandSuccess>());
    expect(repo.updateCalls, 1);
    expect(repo.lastUpdatedId, 'v1');
    expect(repo.lastUpdatedName, 'Name');
    expect(repo.lastUpdatedColor, '#fff');
    expect(repo.lastUpdatedIconName, 'star');
    expect(repo.lastUpdatedPriority, ValuePriority.high);
    expect(repo.lastUpdatedContext, ctx);
  });
}

final class _RecordingValueRepository implements ValueRepositoryContract {
  int count = 0;
  int createCalls = 0;
  int updateCalls = 0;

  String? lastCreatedName;
  String? lastCreatedColor;
  String? lastCreatedIconName;
  ValuePriority? lastCreatedPriority;
  OperationContext? lastCreatedContext;

  String? lastUpdatedId;
  String? lastUpdatedName;
  String? lastUpdatedColor;
  String? lastUpdatedIconName;
  ValuePriority? lastUpdatedPriority;
  OperationContext? lastUpdatedContext;

  @override
  Future<int> getCount() async => count;

  @override
  Future<void> create({
    required String name,
    required String color,
    String? iconName,
    ValuePriority priority = ValuePriority.medium,
    OperationContext? context,
  }) async {
    createCalls++;
    lastCreatedName = name;
    lastCreatedColor = color;
    lastCreatedIconName = iconName;
    lastCreatedPriority = priority;
    lastCreatedContext = context;
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required String color,
    String? iconName,
    ValuePriority? priority,
    OperationContext? context,
  }) async {
    updateCalls++;
    lastUpdatedId = id;
    lastUpdatedName = name;
    lastUpdatedColor = color;
    lastUpdatedIconName = iconName;
    lastUpdatedPriority = priority;
    lastUpdatedContext = context;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
