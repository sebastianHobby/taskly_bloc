@Tags(['widget', 'settings'])
library;

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_developer_page.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('settings developer page renders items', (tester) async {
    await tester.pumpApp(const SettingsDeveloperPage());

    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('View App Logs'), findsOneWidget);
    expect(find.text('Tile Catalog'), findsNothing);
    expect(find.text('Generate Template Data'), findsNothing);
    expect(find.text('Wipe account data and reset onboarding'), findsNothing);
  });
}
