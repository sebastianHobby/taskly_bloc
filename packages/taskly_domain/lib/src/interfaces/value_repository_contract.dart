import 'package:taskly_domain/src/domain.dart';
import 'package:taskly_domain/src/queries/value_query.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

abstract class ValueRepositoryContract {
  /// Watch values with optional filtering.
  ///
  /// If [query] is null, returns all values.
  Stream<List<Value>> watchAll([ValueQuery? query]);

  /// Get values with optional filtering.
  ///
  /// If [query] is null, returns all values.
  Future<List<Value>> getAll([ValueQuery? query]);

  Stream<Value?> watchById(String id);
  Future<Value?> getById(String id);

  /// Get values by IDs.
  Future<List<Value>> getValuesByIds(List<String> ids);

  Future<void> create({
    required String name,
    required String color,
    String? iconName,
    ValuePriority priority = ValuePriority.medium,
    OperationContext? context,
  });
  Future<void> update({
    required String id,
    required String name,
    required String color,
    String? iconName,
    ValuePriority? priority,
    OperationContext? context,
  });
  Future<void> delete(String id, {OperationContext? context});
}
