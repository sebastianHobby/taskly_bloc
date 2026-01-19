@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/src/core/model/value_priority.dart';

void main() {
  testSafe('ValuePriority values expose expected weights', () async {
    expect(ValuePriority.low.weight, 1);
    expect(ValuePriority.medium.weight, 3);
    expect(ValuePriority.high.weight, 5);
  });
}
