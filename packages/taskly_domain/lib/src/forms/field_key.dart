/// Typed IDs for form fields.
///
/// Keys live in domain so domain-first validation can return field-addressable
/// errors without duplicating strings in UI.
library;

part '../core/forms/task_field_keys.dart';
part '../core/forms/project_field_keys.dart';
part '../core/forms/value_field_keys.dart';
part '../core/forms/routine_field_keys.dart';

final class FieldKey {
  const FieldKey(this.id);

  /// Stable field ID used by forms and validation.
  final String id;
}
