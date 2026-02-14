import 'package:taskly_domain/src/checklists/model/checklist_item.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

abstract class TaskChecklistRepositoryContract {
  Stream<List<ChecklistItem>> watchItems(String taskId);

  Future<List<ChecklistItem>> getItems(String taskId);

  Future<void> replaceItems({
    required String taskId,
    required List<String> titlesInOrder,
    OperationContext? context,
  });

  Stream<List<ChecklistItemState>> watchState({
    required String taskId,
    required DateTime? occurrenceDate,
  });

  Future<List<ChecklistItemState>> getState({
    required String taskId,
    required DateTime? occurrenceDate,
  });

  Future<void> setChecked({
    required String taskId,
    required String itemId,
    required bool isChecked,
    required DateTime? occurrenceDate,
    OperationContext? context,
  });
}
