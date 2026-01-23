import 'package:taskly_bloc/bootstrap/local_dev_host_impl.dart';

/// Returns the best host to reach a service running on the developer machine.
///
/// - Android emulator: use 10.0.2.2 (host loopback)
/// - Other platforms: use 127.0.0.1
String localDevHost() => localDevHostImpl();
