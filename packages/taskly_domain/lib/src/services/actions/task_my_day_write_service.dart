import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

/// Write facade for creating a task and immediately adding it to My Day.
final class TaskMyDayWriteService {
  TaskMyDayWriteService({
    required TaskWriteService taskWriteService,
    required MyDayRepositoryContract myDayRepository,
    required HomeDayKeyService dayKeyService,
  }) : _taskWriteService = taskWriteService,
       _myDayRepository = myDayRepository,
       _dayKeyService = dayKeyService;

  final TaskWriteService _taskWriteService;
  final MyDayRepositoryContract _myDayRepository;
  final HomeDayKeyService _dayKeyService;

  Future<CommandResult> createAndPickForToday(
    CreateTaskCommand command, {
    required OperationContext context,
    MyDayPickBucket bucket = MyDayPickBucket.manual,
  }) async {
    final result = await _taskWriteService.createReturningId(
      command,
      context: context,
    );

    switch (result) {
      case CommandSuccess(:final entityId?):
        await _myDayRepository.appendPick(
          dayKeyUtc: _dayKeyService.todayDayKeyUtc(),
          taskId: entityId,
          bucket: bucket,
          context: context,
        );
        return result;
      case CommandSuccess():
        throw StateError('Task create succeeded without a task id.');
      case CommandValidationFailure():
        return result;
    }
  }
}
