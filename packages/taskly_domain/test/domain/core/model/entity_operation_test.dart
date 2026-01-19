@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/src/core/model/entity_operation.dart';

void main() {
  testSafe('EntityOperation exposes expected values', () async {
    expect(
      EntityOperation.values,
      containsAllInOrder(const [
        EntityOperation.create,
        EntityOperation.update,
        EntityOperation.delete,
      ]),
    );
  });
}
