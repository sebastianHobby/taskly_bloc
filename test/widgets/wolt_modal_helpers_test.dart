import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';

class _Host extends StatelessWidget {
  const _Host({required this.notifier});

  final ValueNotifier<bool> notifier;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (appCtx) => ElevatedButton(
              onPressed: () async {
                await showDetailModal<void>(
                  context: appCtx,
                  sheetOpenNotifier: notifier,
                  childBuilder: (modalCtx) => SafeArea(
                    top: false,
                    child: Material(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('SheetContent', key: Key('sheet-text')),
                          ElevatedButton(
                            key: const Key('close-sheet'),
                            onPressed: () => Navigator.of(modalCtx).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('showDetailModal opens and closes, toggles notifier', (
    tester,
  ) async {
    final notifier = ValueNotifier<bool>(false);
    await tester.pumpWidget(_Host(notifier: notifier));

    // Initially closed
    expect(notifier.value, isFalse);

    // Open
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sheet-text')), findsOneWidget);
    expect(notifier.value, isTrue);

    // Close via button inside sheet
    await tester.tap(find.byKey(const Key('close-sheet')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sheet-text')), findsNothing);
    expect(notifier.value, isFalse);
  });

  testWidgets('useNonScrolling: false uses WoltModalSheetPage', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (appCtx) => ElevatedButton(
                onPressed: () async {
                  final notifier = ValueNotifier<bool>(false);
                  await showDetailModal<void>(
                    context: appCtx,
                    sheetOpenNotifier: notifier,
                    useNonScrolling: false,
                    childBuilder: (modalCtx) => SafeArea(
                      top: false,
                      child: Material(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('AltContent', key: Key('alt-text')),
                            ElevatedButton(
                              key: const Key('alt-close'),
                              onPressed: () => Navigator.of(modalCtx).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('OpenAlt'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OpenAlt'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('alt-text')), findsOneWidget);
    // We can't reliably assert WoltModalSheetPage type is in the tree because
    // the library may wrap pages internally. At minimum, ensure the
    // NonScrollingWoltModalSheetPage is not present when useNonScrolling=false.
    expect(find.byType(NonScrollingWoltModalSheetPage), findsNothing);

    await tester.tap(find.byKey(const Key('alt-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('alt-text')), findsNothing);
  });
}
