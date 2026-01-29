import 'package:rxdart/rxdart.dart';

/// Session-scoped demo mode toggle for guided tour/demo data.
final class DemoModeService {
  DemoModeService() : _enabled = BehaviorSubject<bool>.seeded(false);

  final BehaviorSubject<bool> _enabled;

  ValueStream<bool> get enabled => _enabled.stream;

  bool get isEnabled => _enabled.value;

  void enable() => _enabled.add(true);

  void disable() => _enabled.add(false);

  Future<void> dispose() => _enabled.close();
}
