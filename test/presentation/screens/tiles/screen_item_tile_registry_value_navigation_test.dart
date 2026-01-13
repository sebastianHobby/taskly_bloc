import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/presentation/screens/tiles/screen_item_tile_registry.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets(
    'tapping a ScreenItemValue tile navigates to /value/:id by default',
    (tester) async {
      const valueId = 'value-123';
      final value = Value(
        id: valueId,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        name: 'Health',
        color: '#00FF00',
      );

      final router = GoRouter(
        initialLocation: '/list',
        routes: [
          GoRoute(
            path: '/list',
            builder: (context, state) {
              const registry = ScreenItemTileRegistry();
              return Scaffold(
                body: Center(
                  child: registry.build(
                    context,
                    item: ScreenItem.value(value),
                  ),
                ),
              );
            },
          ),
          GoRoute(
            path: '/value/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return Scaffold(body: Text('Value Detail $id'));
            },
          ),
        ],
      );

      await pumpLocalizedRouterApp(tester, router: router);
      await tester.pumpAndSettle();

      expect(find.text('Health'), findsOneWidget);

      await tester.tap(find.text('Health'));
      await tester.pumpAndSettle();

      expect(find.text('Value Detail $valueId'), findsOneWidget);
    },
  );
}
