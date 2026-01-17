/// Dependency injection module entrypoint for `taskly_data`.
///
/// The app composition root should call [registerTasklyData] to bind
/// `taskly_domain` contracts to `taskly_data` implementations.
library;

export 'src/di/taskly_data_module.dart' show registerTasklyData;
