import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_specs.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/view/unified_screen_spec_page.dart';

void main() {
  group('Phase 4: typed system screens', () {
    test('SystemScreenSpecs includes key system screens', () {
      expect(SystemScreenSpecs.getByKey('my_day'), isNotNull);
      expect(SystemScreenSpecs.getByKey('scheduled'), isNotNull);
      expect(SystemScreenSpecs.getByKey('someday'), isNotNull);
      expect(SystemScreenSpecs.getByKey('values'), isNotNull);
      expect(SystemScreenSpecs.getByKey('check_in'), isNotNull);
    });

    test('Routing.buildScreen uses typed specs for system screens', () {
      final widget = Routing.buildScreen('my_day');
      expect(widget, isA<UnifiedScreenPageFromSpec>());
    });
  });
}
