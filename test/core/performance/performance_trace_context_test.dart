import '../../helpers/test_imports.dart';

import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/performance/performance_trace_context.dart';

void main() {
  group('PerformanceTraceContext', () {
    tearDown(() {
      PerformanceTraceContext.instance.currentScreenTraceId = null;
      PerformanceTraceContext.instance.onRouteChanged(null);
    });

    testSafe('newTraceId includes prefix and is unique', () async {
      final ctx = PerformanceTraceContext.instance;

      final a = ctx.newTraceId('nav');
      final b = ctx.newTraceId('nav');

      expect(a, startsWith('nav-'));
      expect(b, startsWith('nav-'));
      expect(a, isNot(equals(b)));
    });

    testSafe(
      'onRouteChanged updates navigation context and clears screen trace',
      () async {
        final ctx = PerformanceTraceContext.instance;
        ctx.currentScreenTraceId = 'screen-1';

        final route = MaterialPageRoute<void>(
          settings: RouteSettings(
            name: '/inbox',
            arguments: 'x' * 400,
          ),
          builder: (_) => const SizedBox.shrink(),
        );

        ctx.onRouteChanged(route);

        expect(ctx.currentNavigationTraceId, isNotNull);
        expect(ctx.currentScreenTraceId, isNull);

        final summary = ctx.currentRouteSummary;
        expect(summary, contains('MaterialPageRoute'));
        expect(summary, contains('name=/inbox'));
        expect(summary, contains('String:'));
        expect(summary, contains('…'));
      },
    );

    testSafe('scheduleMicrotask runs callback', () async {
      var ran = false;
      await scheduleMicrotask(() {
        ran = true;
      });
      expect(ran, isTrue);
    });
  });
}
