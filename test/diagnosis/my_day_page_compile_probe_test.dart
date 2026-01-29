@Tags(['diagnosis'])
library;

import '../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_page.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('my day page compile probe', (tester) async {
    expect(MyDayPage, isNotNull);
  });
}
