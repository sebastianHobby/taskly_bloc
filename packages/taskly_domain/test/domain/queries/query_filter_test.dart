@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/queries/query_filter.dart';

void main() {
  testSafe('QueryFilter.matchAll isMatchAll and has stable toString', () async {
    const f = QueryFilter<int>.matchAll();

    expect(f.isMatchAll, isTrue);
    expect(f.toString(), 'QueryFilter.matchAll()');
  });

  testSafe('QueryFilter.toDnfTerms returns shared when no orGroups', () async {
    const f = QueryFilter<int>(shared: [1, 2]);

    expect(f.toDnfTerms(), [
      <int>[1, 2],
    ]);
  });

  testSafe('QueryFilter.toDnfTerms prepends shared to each orGroup', () async {
    const f = QueryFilter<int>(
      shared: [1],
      orGroups: [
        [2],
        [3, 4],
      ],
    );

    expect(
      f.toDnfTerms(),
      [
        <int>[1, 2],
        <int>[1, 3, 4],
      ],
    );
  });

  testSafe('QueryFilter.toJson/fromJson roundtrips', () async {
    const f = QueryFilter<int>(
      shared: [1, 2],
      orGroups: [
        [3],
      ],
    );

    final json = f.toJson((p) => <String, dynamic>{'v': p});

    final decoded = QueryFilter.fromJson<int>(
      json,
      (m) => m['v'] as int,
    );

    expect(decoded, equals(f));
  });

  testSafe('QueryFilterExtension.merge combines shared and orGroups', () async {
    const a = QueryFilter<int>(
      shared: [1],
      orGroups: [
        [2],
      ],
    );
    const b = QueryFilter<int>(
      shared: [3],
      orGroups: [
        [4, 5],
      ],
    );

    final merged = a.merge(b);
    expect(merged.shared, [1, 3]);
    expect(merged.orGroups, [
      [2],
      [4, 5],
    ]);

    expect(a.merge(null), equals(a));
  });
}
