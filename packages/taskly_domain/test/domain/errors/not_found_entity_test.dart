@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/errors/not_found_entity.dart';

void main() {
  testSafe('NotFoundEntity exposes stable names', () async {
    expect(NotFoundEntity.task.name, equals('task'));
    expect(NotFoundEntity.project.name, equals('project'));
    expect(NotFoundEntity.value.name, equals('value'));
  });
}
