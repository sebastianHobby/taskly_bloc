import 'dart:async';

import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings/global_settings.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';

/// Computes the app's "today" day-key based on a fixed home timezone offset.
///
/// The returned value is a UTC-midnight [DateTime] that represents the *home*
/// calendar day. It is safe to persist and compare as a date-only key.
///
/// This intentionally uses a fixed offset (minutes) and does not model DST.
class HomeDayKeyService {
  HomeDayKeyService({required SettingsRepositoryContract settingsRepository})
    : _settingsRepository = settingsRepository;

  final SettingsRepositoryContract _settingsRepository;

  StreamSubscription<GlobalSettings>? _subscription;
  int _offsetMinutes = 0;

  bool _started = false;

  /// Ensures a home timezone offset exists in settings.
  Future<void> ensureInitialized() async {
    final current = await _settingsRepository.load(SettingsKey.global);
    _offsetMinutes = current.homeTimeZoneOffsetMinutes;
    talker.debug(
      '[HomeDayKeyService] homeTimeZoneOffsetMinutes=$_offsetMinutes',
    );
  }

  void start() {
    if (_started) return;
    _started = true;

    _subscription = _settingsRepository.watch(SettingsKey.global).listen((
      settings,
    ) {
      _offsetMinutes = settings.homeTimeZoneOffsetMinutes;
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Returns today's home-day key as a UTC-midnight date-only key.
  DateTime todayDayKeyUtc({DateTime? nowUtc}) {
    final utc = nowUtc ?? DateTime.now().toUtc();
    final shifted = utc.add(Duration(minutes: _offsetMinutes));
    return dateOnly(shifted);
  }
}
