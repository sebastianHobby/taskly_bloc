@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/time/clock.dart';

void main() {
  testSafe('SystemClock nowUtc returns a UTC DateTime', () async {
    const clock = SystemClock();

    final now = clock.nowUtc();
    expect(now.isUtc, isTrue);
  });

  testSafe('SystemClock nowLocal returns a non-UTC DateTime', () async {
    const clock = SystemClock();

    final now = clock.nowLocal();
    expect(now.isUtc, isFalse);
  });
}
