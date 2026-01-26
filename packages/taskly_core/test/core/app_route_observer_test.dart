import '../helpers/test_imports.dart';

import 'package:flutter/material.dart';
import 'package:taskly_core/logging.dart';

class _LongArgs {
  _LongArgs(this.value);
  final String value;

  @override
  String toString() => value;
}

void main() {
  group('AppRouteObserver', () {
    testSafe('captures route name and args on push/replace/pop', () async {
      final observer = AppRouteObserver();

      final route1 = MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/one', arguments: 'arg1'),
        builder: (_) => const SizedBox.shrink(),
      );

      final route2 = MaterialPageRoute<void>(
        settings: RouteSettings(name: '/two', arguments: _LongArgs('x' * 1000)),
        builder: (_) => const SizedBox.shrink(),
      );

      observer.didPush(route1, null);
      expect(observer.currentRouteSummary, contains('name=/one'));
      expect(observer.currentRouteSummary, contains('args=String:arg1'));

      observer.didReplace(newRoute: route2, oldRoute: route1);
      expect(observer.currentRouteSummary, contains('name=/two'));
      expect(observer.currentRouteSummary, contains('args=_LongArgs:'));

      observer.didPop(route2, route1);
      expect(observer.currentRouteSummary, contains('name=/one'));
    });

    testSafe('formats null route values as <null>', () async {
      final observer = AppRouteObserver();
      observer.didPush(
        MaterialPageRoute<void>(
          settings: const RouteSettings(),
          builder: (_) => const SizedBox.shrink(),
        ),
        null,
      );

      expect(observer.currentRouteSummary, contains('name=<null>'));
    });

    testSafe('formats null args as <null>', () async {
      final observer = AppRouteObserver();
      observer.didPush(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/x'),
          builder: (_) => const SizedBox.shrink(),
        ),
        null,
      );

      expect(observer.currentRouteSummary, contains('args=<null>'));
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
