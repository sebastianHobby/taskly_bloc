@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/view/guided_tour_targets.dart';
import '../../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('unregisters without ancestor lookup on dispose', (
    tester,
  ) async {
    final registry = GuidedTourTargetRegistry();

    await tester.pumpApp(
      GuidedTourTargetScope(
        registry: registry,
        child: const GuidedTourTarget(
          id: 'target',
          child: SizedBox(width: 8, height: 8),
        ),
      ),
    );

    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
