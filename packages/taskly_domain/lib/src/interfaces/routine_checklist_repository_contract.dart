import 'package:taskly_domain/src/checklists/model/checklist_item.dart';
import 'package:taskly_domain/src/routines/model/routine_period_type.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

abstract class RoutineChecklistRepositoryContract {
  Stream<List<ChecklistItem>> watchItems(String routineId);

  Future<List<ChecklistItem>> getItems(String routineId);

  Future<void> replaceItems({
    required String routineId,
    required List<String> titlesInOrder,
    OperationContext? context,
  });

  Stream<List<ChecklistItemState>> watchState({
    required String routineId,
    required RoutinePeriodType periodType,
    required DateTime windowKey,
  });

  Future<List<ChecklistItemState>> getState({
    required String routineId,
    required RoutinePeriodType periodType,
    required DateTime windowKey,
  });

  Future<void> setChecked({
    required String routineId,
    required String itemId,
    required bool isChecked,
    required RoutinePeriodType periodType,
    required DateTime windowKey,
    OperationContext? context,
  });
}
