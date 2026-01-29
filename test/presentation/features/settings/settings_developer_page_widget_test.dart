@Tags(['widget', 'settings'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_developer_page.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';

class MockTemplateDataService extends Mock implements TemplateDataService {}

class MockUserDataWipeService extends Mock implements UserDataWipeService {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockTemplateDataService templateDataService;
  late MockUserDataWipeService userDataWipeService;
  late MockAuthRepositoryContract authRepository;

  setUp(() {
    templateDataService = MockTemplateDataService();
    userDataWipeService = MockUserDataWipeService();
    authRepository = MockAuthRepositoryContract();
  });

  testWidgetsSafe('settings developer page renders items', (tester) async {
    await tester.pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<TemplateDataService>.value(
            value: templateDataService,
          ),
          RepositoryProvider<UserDataWipeService>.value(
            value: userDataWipeService,
          ),
          RepositoryProvider<AuthRepositoryContract>.value(
            value: authRepository,
          ),
        ],
        child: const SettingsDeveloperPage(),
      ),
    );

    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('View App Logs'), findsOneWidget);
    expect(find.text('Tile Catalog'), findsOneWidget);
    expect(find.text('Generate Template Data'), findsOneWidget);
    if (kDebugMode) {
      expect(
        find.text('Wipe account data and reset onboarding'),
        findsOneWidget,
      );
    }
  });
}
