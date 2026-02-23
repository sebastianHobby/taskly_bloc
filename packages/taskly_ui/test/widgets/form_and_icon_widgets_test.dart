import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';
import 'package:taskly_ui/src/foundations/icons/taskly_symbol_icon.dart';

void main() {
  group('FormShell', () {
    testWidgets('renders header/footer actions and triggers callbacks', (
      tester,
    ) async {
      var submitCalls = 0;
      var closeCalls = 0;
      var deleteCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormShell(
              onSubmit: () => submitCalls++,
              onClose: () => closeCalls++,
              onDelete: () => deleteCalls++,
              submitTooltip: 'Save',
              deleteTooltip: 'Delete',
              closeTooltip: 'Close',
              submitEnabled: true,
              showHeaderSubmit: true,
              centerHeaderTitle: true,
              headerTitle: const Text('Header'),
              floatingAction: const Text('Fab'),
              child: const SizedBox(height: 200, child: Text('Content')),
            ),
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Fab'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete'));
      await tester.pump();
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      await tester.tap(find.byTooltip('Save').first);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();

      expect(deleteCalls, 1);
      expect(closeCalls, 1);
      expect(submitCalls, 2);
    });
  });

  group('IconPickerDialog', () {
    testWidgets('filters icons and returns selected icon name', (tester) async {
      String? selected;
      final categories = [
        const IconCategory(
          name: 'basic',
          label: 'Basic',
          icons: [
            IconItem(name: 'home', label: 'Home', icon: Icons.home),
            IconItem(name: 'star', label: 'Star', icon: Icons.star),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    selected = await IconPickerDialog.show(
                      context,
                      categories: categories,
                      title: 'Pick icon',
                      searchHintText: 'Search',
                      allCategoryLabel: 'All',
                      noIconsFoundLabel: 'None',
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Pick icon'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('None'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'home');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      expect(selected, 'home');
    });
  });

  group('TasklyFormIconGridPicker', () {
    testWidgets('supports category + search filtering and selection', (
      tester,
    ) async {
      String? selected;
      final categories = [
        const IconCategory(
          name: 'work',
          label: 'Work',
          icons: [
            IconItem(name: 'briefcase', label: 'Briefcase', icon: Icons.work),
          ],
        ),
        const IconCategory(
          name: 'health',
          label: 'Health',
          icons: [
            IconItem(name: 'heart', label: 'Heart', icon: Icons.favorite),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TasklyFormIconGridPicker(
              categories: categories,
              searchHintText: 'Search icons',
              allCategoryLabel: 'All',
              noIconsFoundLabel: 'No icons',
              selectedIcon: 'heart',
              onSelected: (value) => selected = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Work'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'brief');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.work));
      await tester.pump();

      expect(selected, 'briefcase');

      await tester.enterText(find.byType(TextField), 'none');
      await tester.pump();
      expect(find.text('No icons'), findsOneWidget);
    });
  });

  group('TasklyFormIconSearchPicker', () {
    testWidgets('filters icons and returns selected name', (tester) async {
      String? selected;
      const icons = [
        TasklySymbolIcon(
          name: 'wallet',
          icon: Icons.account_balance_wallet_outlined,
          searchText: 'wallet money',
          popularity: 1,
        ),
        TasklySymbolIcon(
          name: 'run',
          icon: Icons.directions_run,
          searchText: 'run cardio',
          popularity: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TasklyFormIconSearchPicker(
              icons: icons,
              searchHintText: 'Search',
              noIconsFoundLabel: 'No match',
              selectedIconName: 'run',
              tooltipBuilder: (name) => 'tip:$name',
              onSelected: (value) => selected = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'wallet');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
      await tester.pump();

      expect(selected, 'wallet');

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('No match'), findsOneWidget);
    });
  });
}
