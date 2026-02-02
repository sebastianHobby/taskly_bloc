import 'package:taskly_core/logging.dart';

typedef AppRestartCallback = Future<void> Function(String reason);

final AppRestartService appRestartService = AppRestartService();

class AppRestartService {
  AppRestartCallback? callback;

  Future<bool> restart({required String reason}) async {
    final callback = this.callback;
    if (callback == null) {
      talker.warning(
        '[app_restart] Restart requested before callback is attached',
      );
      return false;
    }

    await callback(reason);
    return true;
  }
}
