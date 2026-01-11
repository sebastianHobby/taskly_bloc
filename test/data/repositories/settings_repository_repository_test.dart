import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/presentation/theme/app_theme_mode.dart';
import 'package:taskly_bloc/domain/settings/model/global_settings.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';

import '../../helpers/base_repository_helpers.dart';

void main() {
  group('SettingsRepository (repository)', () {
    late RepositoryTestContext ctx;
    late SettingsRepository repo;

    setUp(() {
      ctx = RepositoryTestContext();
      repo = SettingsRepository(driftDb: ctx.db);
    });

    tearDown(() async {
      await ctx.dispose();
    });

    test(
      'load returns defaults when profile missing',
      tags: 'repository',
      () async {
        final global = await repo.load(SettingsKey.global);
        expect(global, const GlobalSettings());
      },
    );

    test(
      'save + load round-trips GlobalSettings JSON',
      tags: 'repository',
      () async {
        const updated = GlobalSettings(
          themeMode: AppThemeMode.dark,
          onboardingCompleted: true,
        );

        await repo.save(SettingsKey.global, updated);
        final loaded = await repo.load(SettingsKey.global);
        expect(loaded, updated);
      },
    );
  });
}
