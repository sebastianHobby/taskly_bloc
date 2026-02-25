import '../helpers/test_imports.dart';

import 'package:taskly_core/env.dart';
import 'package:taskly_core/logging.dart';

void main() {
  group('Env', () {
    setUpAll(() {
      resetLoggingForTest();
      initializeLoggingForTest();
    });

    testSafe('uses configured values', () async {
      Env.resetForTest();
      Env.config = const EnvConfig(
        name: 'test',
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'pubkey',
        powersyncUrl: 'https://example.powersync.dev',
      );
      await Env.load();

      expect(Env.supabaseUrl, 'https://example.supabase.co');
      expect(Env.supabasePublishableKey, 'pubkey');
      expect(Env.powersyncUrl, 'https://example.powersync.dev');

      Env.validateRequired();
    });

    testSafe(
      'validateRequired throws when required values are missing',
      () async {
        Env.resetForTest();
        await Env.load();

        expect(Env.validateRequired, throwsA(isA<StateError>()));
      },
    );

    testSafe('getters throw when not configured', () async {
      Env.resetForTest();
      expect(() => Env.supabaseUrl, throwsA(isA<StateError>()));
      expect(() => Env.supabasePublishableKey, throwsA(isA<StateError>()));
      expect(() => Env.powersyncUrl, throwsA(isA<StateError>()));
    });

    testSafe('validateRequired also validates auth redirect URL shapes', () async {
      Env.resetForTest();
      Env.config = const EnvConfig(
        name: 'test',
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'pubkey',
        powersyncUrl: 'https://example.powersync.dev',
        authSignUpWebRedirectUrl: 'not-a-url',
      );
      await Env.load();

      expect(Env.validateRequired, throwsA(isA<StateError>()));
    });
  });
}
