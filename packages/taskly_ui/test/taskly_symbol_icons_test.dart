@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_ui/src/foundations/icons/taskly_symbol_icons.dart';

import 'helpers/test_helpers.dart';

void main() {
  testSafe('tasklySymbolIcons exposes generated catalog', () async {
    expect(tasklySymbolIcons, isNotEmpty);
    expect(tasklySymbolIcons.first.name, isNotEmpty);
    expect(tasklySymbolIcons.first.popularity, greaterThanOrEqualTo(0));
  });

  testSafe(
    'tasklySymbolIconDataFromName handles null and known names',
    () async {
      expect(tasklySymbolIconDataFromName(null), isNull);
      final first = tasklySymbolIcons.first;
      expect(tasklySymbolIconDataFromName(first.name), first.icon);
      expect(tasklySymbolIconDataFromName('missing-icon-name'), isNull);
    },
  );
}
