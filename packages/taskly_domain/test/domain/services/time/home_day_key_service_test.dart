@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'dart:async';

import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/src/interfaces/settings_repository_contract.dart';
import 'package:taskly_domain/src/services/time/home_day_key_service.dart';
import 'package:taskly_domain/src/settings/model/global_settings.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

class _FakeSettingsRepo implements SettingsRepositoryContract {
  _FakeSettingsRepo(this._current);

  GlobalSettings _current;
  final _controller = StreamController<GlobalSettings>.broadcast();

  void emit(GlobalSettings settings) {
    _current = settings;
    _controller.add(settings);
  }

  Future<void> close() => _controller.close();

  @override
  Future<T> load<T>(SettingsKey<T> key) async {
    if (key == SettingsKey.global) return _current as T;
    throw UnsupportedError('Unsupported key: $key');
  }

  @override
  Future<void> save<T>(
    SettingsKey<T> key,
    T value, {
    OperationContext? context,
  }) async {
    if (key == SettingsKey.global) {
      emit(value as GlobalSettings);
      return;
    }
    throw UnsupportedError('Unsupported key: $key');
  }

  @override
  Stream<T> watch<T>(SettingsKey<T> key) {
    if (key == SettingsKey.global) {
      return _controller.stream as Stream<T>;
    }
    throw UnsupportedError('Unsupported key: $key');
  }
}

void main() {
  setUpAll(initializeLoggingForTest);

  testSafe(
    'HomeDayKeyService uses initialized offset for today and next boundary',
    () async {
      final repo = _FakeSettingsRepo(
        const GlobalSettings(homeTimeZoneOffsetMinutes: 60),
      );
      addTearDown(repo.close);

      final service = HomeDayKeyService(settingsRepository: repo);
      await service.ensureInitialized();

      final nowUtc = DateTime.utc(2026, 1, 1, 23, 30);

      expect(
        service.todayDayKeyUtc(nowUtc: nowUtc),
        DateTime.utc(2026, 1, 2),
      );

      expect(
        service.nextHomeDayBoundaryUtc(nowUtc: nowUtc),
        DateTime.utc(2026, 1, 2, 23),
      );
    },
  );

  testSafe(
    'HomeDayKeyService start/stop listens to settings changes',
    () async {
      final repo = _FakeSettingsRepo(
        const GlobalSettings(homeTimeZoneOffsetMinutes: 0),
      );
      addTearDown(repo.close);

      final service = HomeDayKeyService(settingsRepository: repo);
      await service.ensureInitialized();

      final nowUtc = DateTime.utc(2026, 1, 1, 1, 0);
      expect(service.todayDayKeyUtc(nowUtc: nowUtc), DateTime.utc(2026, 1, 1));

      service.start();
      repo.emit(const GlobalSettings(homeTimeZoneOffsetMinutes: -120));
      await Future<void>.delayed(const Duration(milliseconds: 1));

      // Shift back 2h moves the home day to the previous date.
      expect(
        service.todayDayKeyUtc(nowUtc: nowUtc),
        DateTime.utc(2025, 12, 31),
      );

      service.stop();
      repo.emit(const GlobalSettings(homeTimeZoneOffsetMinutes: 600));
      await Future<void>.delayed(const Duration(milliseconds: 1));

      // Offset should not change after stop().
      expect(
        service.todayDayKeyUtc(nowUtc: nowUtc),
        DateTime.utc(2025, 12, 31),
      );

      await service.dispose();
    },
  );
}
