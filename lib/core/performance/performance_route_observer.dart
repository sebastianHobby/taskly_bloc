import 'package:flutter/widgets.dart';

import 'package:taskly_bloc/core/performance/performance_trace_context.dart';

/// Navigator observer that starts a new navigation trace on route changes.
///
/// Attach via GoRouter's `observers` list.
class PerformanceRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    PerformanceTraceContext.instance.onRouteChanged(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    PerformanceTraceContext.instance.onRouteChanged(newRoute ?? oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    PerformanceTraceContext.instance.onRouteChanged(previousRoute);
  }
}
