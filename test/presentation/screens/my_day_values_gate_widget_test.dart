@Tags(['widget', 'my_day'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_values_gate.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('my day values gate shows setup copy', (tester) async {
    await tester.pumpApp(const MyDayValuesGate());

    expect(find.text('Unlock suggestions'), findsOneWidget);
    expect(find.text('Start setup'), findsOneWidget);
  });
}
