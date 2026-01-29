@Tags(['widget', 'app'])
library;

import '../../../helpers/test_imports.dart';
import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/app/view/splash_screen.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('splash screen shows app branding and loader', (
    tester,
  ) async {
    await tester.pumpApp(const SplashScreen());

    expect(find.text('Taskly'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
