import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/telemetry.dart';

import 'package:taskly_data/src/errors/app_failure_mapper.dart';

/// Runs an operation and ensures any thrown error is converted into an
/// [AppFailure] via [AppFailureMapper].
///
/// This prevents raw implementation exceptions from leaking into presentation.
abstract final class FailureGuard {
  static Future<T> run<T>(
    Future<T> Function() operation, {
    required String area,
    required String opName,
    OperationContext? context,
  }) async {
    try {
      return await operation();
    } catch (e, st) {
      final failure = AppFailureMapper.fromException(e);
      AppLog.handleStructured(
        area,
        '$opName failed',
        failure,
        st,
        context?.toLogFields() ?? const <String, Object?>{},
      );
      throw failure;
    }
  }
}
