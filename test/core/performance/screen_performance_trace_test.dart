import '../../helpers/test_imports.dart';

import 'package:taskly_bloc/core/logging/talker_service.dart'
    show initializeTalkerForTest;
import 'package:taskly_bloc/core/performance/performance_trace_context.dart';
import 'package:taskly_bloc/core/performance/screen_performance_trace.dart';

void main() {
  group('ScreenPerformanceTrace', () {
    setUp(() {
      initializeTalkerForTest();
      PerformanceTraceContext.instance.currentScreenTraceId = null;
    });

    tearDown(() {
      PerformanceTraceContext.instance.currentScreenTraceId = null;
    });

    testSafe('disabled trace is a no-op', () async {
      final trace = ScreenPerformanceTrace.disabled(
        screenName: 'Inbox',
        screenId: 'inbox',
        traceId: 'trace-1',
        routeSummary: '/inbox',
      );

      // Should not throw.
      trace.logStart();
      trace.markLoadingEmitted();
      trace.markFirstData();
      trace.markFirstPaint();
      trace.endSuccess();
      trace.endError('boom');

      expect(PerformanceTraceContext.instance.currentScreenTraceId, isNull);
    });

    testSafe('endSuccess clears trace context when it matches', () async {
      final trace = ScreenPerformanceTrace(
        screenName: 'Inbox',
        screenId: 'inbox',
        traceId: 'trace-1',
        routeSummary: '/inbox',
        enabled: true,
      );

      PerformanceTraceContext.instance.currentScreenTraceId = 'trace-1';

      trace.endSuccess();

      expect(PerformanceTraceContext.instance.currentScreenTraceId, isNull);
    });

    testSafe(
      'endSuccess does not clear trace context when it differs',
      () async {
        final trace = ScreenPerformanceTrace(
          screenName: 'Inbox',
          screenId: 'inbox',
          traceId: 'trace-1',
          routeSummary: '/inbox',
          enabled: true,
        );

        PerformanceTraceContext.instance.currentScreenTraceId = 'trace-2';

        trace.endSuccess();

        expect(
          PerformanceTraceContext.instance.currentScreenTraceId,
          'trace-2',
        );
      },
    );

    testSafe('endSuccess is idempotent', () async {
      final trace = ScreenPerformanceTrace(
        screenName: 'Inbox',
        screenId: 'inbox',
        traceId: 'trace-1',
        routeSummary: '/inbox',
        enabled: true,
      );

      PerformanceTraceContext.instance.currentScreenTraceId = 'trace-1';
      trace.endSuccess();
      expect(PerformanceTraceContext.instance.currentScreenTraceId, isNull);

      // If endSuccess runs again it should not clear a new ID.
      PerformanceTraceContext.instance.currentScreenTraceId = 'trace-1';
      trace.endSuccess();
      expect(
        PerformanceTraceContext.instance.currentScreenTraceId,
        'trace-1',
      );
    });

    testSafe('endError clears trace context when it matches', () async {
      final trace = ScreenPerformanceTrace(
        screenName: 'Inbox',
        screenId: 'inbox',
        traceId: 'trace-1',
        routeSummary: '/inbox',
        enabled: true,
      );

      PerformanceTraceContext.instance.currentScreenTraceId = 'trace-1';

      trace.endError('failed');

      expect(PerformanceTraceContext.instance.currentScreenTraceId, isNull);
    });

    testSafe('endError is idempotent', () async {
      final trace = ScreenPerformanceTrace(
        screenName: 'Inbox',
        screenId: 'inbox',
        traceId: 'trace-1',
        routeSummary: '/inbox',
        enabled: true,
      );

      PerformanceTraceContext.instance.currentScreenTraceId = 'trace-1';
      trace.endError('failed');
      expect(PerformanceTraceContext.instance.currentScreenTraceId, isNull);

      PerformanceTraceContext.instance.currentScreenTraceId = 'trace-1';
      trace.endError('failed again');
      expect(
        PerformanceTraceContext.instance.currentScreenTraceId,
        'trace-1',
      );
    });
  });
}
