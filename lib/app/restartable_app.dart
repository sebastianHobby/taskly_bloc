import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/core/startup/app_restart_service.dart';
import 'package:taskly_core/logging.dart';

final class RestartableApp extends StatefulWidget {
  const RestartableApp({required this.builder, super.key});

  final FutureOr<Widget> Function() builder;

  @override
  State<RestartableApp> createState() => _RestartableAppState();
}

class _RestartableAppState extends State<RestartableApp> {
  Key _restartKey = UniqueKey();
  bool _restartInFlight = false;

  @override
  void initState() {
    super.initState();
    appRestartService.callback = _handleRestart;
  }

  @override
  void dispose() {
    appRestartService.callback = null;
    super.dispose();
  }

  Future<void> _handleRestart(String reason) async {
    if (_restartInFlight) return;
    _restartInFlight = true;

    talker.warning('[app_restart] Restarting app: $reason');

    await resetDependencies(reason: reason);
    await setupDependencies();

    if (!mounted) return;
    setState(() {
      _restartKey = UniqueKey();
    });
    _restartInFlight = false;
  }

  @override
  Widget build(BuildContext context) {
    final built = widget.builder();
    if (built is Widget) {
      return KeyedSubtree(key: _restartKey, child: built);
    }

    return FutureBuilder<Widget>(
      future: built,
      builder: (context, snapshot) {
        final child = snapshot.data;
        if (child == null) return const SizedBox.shrink();
        return KeyedSubtree(key: _restartKey, child: child);
      },
    );
  }
}
