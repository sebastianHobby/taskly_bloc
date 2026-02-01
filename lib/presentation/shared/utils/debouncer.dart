import 'dart:async';

/// Simple debouncer for high-frequency UI input.
class Debouncer {
  Debouncer(this.duration);

  final Duration duration;
  Timer? _timer;

  void schedule(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() => _timer?.cancel();
}
