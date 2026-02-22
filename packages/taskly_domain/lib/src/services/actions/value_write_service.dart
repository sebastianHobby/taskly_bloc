import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/telemetry.dart';

/// Write facade for value mutations.
///
/// Centralizes validation and side-effects for value edits and actions.
final class ValueWriteService {
  ValueWriteService({required ValueRepositoryContract valueRepository})
    : _valueRepository = valueRepository,
      _commandHandler = ValueCommandHandler(valueRepository: valueRepository);

  final ValueRepositoryContract _valueRepository;
  final ValueCommandHandler _commandHandler;

  Future<CommandResult> create(
    CreateValueCommand command, {
    OperationContext? context,
  }) {
    return _commandHandler.handleCreate(command, context: context);
  }

  Future<CommandResult> update(
    UpdateValueCommand command, {
    OperationContext? context,
  }) {
    return _commandHandler.handleUpdate(command, context: context);
  }

  Future<void> delete(String valueId, {OperationContext? context}) {
    return _valueRepository.delete(valueId, context: context);
  }

  Future<int> reassignProjectsAndDelete({
    required String valueId,
    required String replacementValueId,
    OperationContext? context,
  }) {
    return _valueRepository.reassignProjectsAndDelete(
      valueId: valueId,
      replacementValueId: replacementValueId,
      context: context,
    );
  }
}
