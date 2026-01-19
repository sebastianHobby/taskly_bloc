import 'dart:io';

import '../helpers/test_imports.dart';

import 'package:taskly_core/env.dart';

void main() {
  group('Env', () {
    testSafe('loads values from .env in debug mode', () async {
      final tempDir = await Directory.systemTemp.createTemp('taskly_env_');
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final previous = Directory.current;
      addTearDown(() {
        Directory.current = previous;
      });

      Directory.current = tempDir;
      await File('.env').writeAsString('''
SUPABASE_URL=https://example.supabase.co
SUPABASE_PUBLISHABLE_KEY=pubkey
POWERSYNC_URL=https://example.powersync.dev
DEV_USERNAME=user
DEV_PASSWORD=pass
''');

      Env.resetForTest();
      await Env.load();

      expect(Env.supabaseUrl, 'https://example.supabase.co');
      expect(Env.supabasePublishableKey, 'pubkey');
      expect(Env.powersyncUrl, 'https://example.powersync.dev');
      expect(Env.devUsername, 'user');
      expect(Env.devPassword, 'pass');

      // Should not throw when required values exist.
      Env.validateRequired();
    });

    testSafe(
      'validateRequired throws when required values are missing',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('taskly_env_');
        addTearDown(() async {
          await tempDir.delete(recursive: true);
        });

        final previous = Directory.current;
        addTearDown(() {
          Directory.current = previous;
        });

        Directory.current = tempDir;

        Env.resetForTest();
        await Env.load();

        expect(Env.validateRequired, throwsA(isA<StateError>()));
      },
    );

    testSafe(
      'getters fall back to --dart-define when dotenv not initialized',
      () async {
        Env.resetForTest();

        // In unit tests we typically do not provide --dart-define values.
        // These getters should still be safe and return empty strings.
        expect(Env.supabaseUrl, isA<String>());
        expect(Env.supabasePublishableKey, isA<String>());
        expect(Env.powersyncUrl, isA<String>());
        expect(Env.devUsername, isA<String>());
        expect(Env.devPassword, isA<String>());
      },
    );

    testSafe(
      'load() is idempotent and does not re-read changed .env',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('taskly_env_');
        addTearDown(() async {
          await tempDir.delete(recursive: true);
        });

        final previous = Directory.current;
        addTearDown(() {
          Directory.current = previous;
        });

        Directory.current = tempDir;

        await File('.env').writeAsString(
          'SUPABASE_URL=https://first.example\n'
          'SUPABASE_PUBLISHABLE_KEY=key1\n'
          'POWERSYNC_URL=https://p1.example\n'
          'DEV_USERNAME=user1\n'
          'DEV_PASSWORD=pass1\n',
        );

        Env.resetForTest();
        await Env.load();
        expect(Env.supabaseUrl, 'https://first.example');

        // Change the file after initialization.
        await File('.env').writeAsString(
          'SUPABASE_URL=https://second.example\n'
          'SUPABASE_PUBLISHABLE_KEY=key2\n'
          'POWERSYNC_URL=https://p2.example\n'
          'DEV_USERNAME=user2\n'
          'DEV_PASSWORD=pass2\n',
        );

        await Env.load();
        // Still uses the values already loaded into dotenv.
        expect(Env.supabaseUrl, 'https://first.example');
      },
    );
  });
}
