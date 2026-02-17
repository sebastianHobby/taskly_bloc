import '../helpers/test_imports.dart';

import 'package:flutter/material.dart';
import 'package:taskly_core/logging.dart';

void main() {
  group('AppRouteObserver', () {
    testSafe('captures route name on push/replace/pop', () async {
      final observer = AppRouteObserver();

      final route1 = MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/one', arguments: 'arg1'),
        builder: (_) => const SizedBox.shrink(),
      );

      final route2 = MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/two', arguments: 'arg2'),
        builder: (_) => const SizedBox.shrink(),
      );

      observer.didPush(route1, null);
      expect(observer.currentRouteSummary, '/one');
      expect(observer.currentRouteSummary, isNot(contains('args=')));

      observer.didReplace(newRoute: route2, oldRoute: route1);
      expect(observer.currentRouteSummary, '/two');
      expect(observer.currentRouteSummary, isNot(contains('args=')));

      observer.didPop(route2, route1);
      expect(observer.currentRouteSummary, '/one');
    });

    testSafe('falls back to route type when route name is missing', () async {
      final observer = AppRouteObserver();
      observer.didPush(
        MaterialPageRoute<void>(
          settings: const RouteSettings(),
          builder: (_) => const SizedBox.shrink(),
        ),
        null,
      );

      expect(observer.currentRouteSummary, contains('MaterialPageRoute'));
    });

    testSafe('does not include args by default', () async {
      final observer = AppRouteObserver();
      observer.didPush(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/x'),
          builder: (_) => const SizedBox.shrink(),
        ),
        null,
      );

      expect(observer.currentRouteSummary, '/x');
      expect(observer.currentRouteSummary, isNot(contains('args=')));
    });

    testSafe('describes missing route as <null>', () async {
      final observer = AppRouteObserver();
      observer.didPop(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/gone'),
          builder: (_) => const SizedBox.shrink(),
        ),
        null,
      );

      expect(observer.currentRouteSummary, contains('<null>'));
    });
  });
}
