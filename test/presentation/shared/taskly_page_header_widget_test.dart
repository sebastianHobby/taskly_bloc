@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_ui/taskly_ui_chrome.dart';

import '../../helpers/test_environment.dart';
import '../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('TasklyPageHeader renders title and footer content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: const Scaffold(
          body: TasklyPageHeader(
            icon: Icons.folder_open_outlined,
            title: 'Projects',
            subtitle: 'Portfolio overview',
            footer: Wrap(
              children: [
                TasklyHeaderChip(label: '12 active'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpForStream();

    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Portfolio overview'), findsOneWidget);
    expect(find.text('12 active'), findsOneWidget);
  });
}
