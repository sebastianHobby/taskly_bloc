@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/forms/field_key.dart';

void main() {
  testSafe('FieldKey exposes the id value', () async {
    const key = FieldKey('task.name');

    expect(key.id, 'task.name');
  });

  testSafe('FieldKey constants expose expected ids', () async {
    expect(TaskFieldKeys.name.id, 'task.name');
    expect(TaskFieldKeys.deadlineDate.id, 'task.deadlineDate');

    expect(ProjectFieldKeys.name.id, 'project.name');
    expect(ProjectFieldKeys.repeatIcalRrule.id, 'project.repeatIcalRrule');

    expect(ValueFieldKeys.name.id, 'value.name');
    expect(ValueFieldKeys.iconName.id, 'value.iconName');
  });
}
