@Tags(['unit', 'auth'])
library;

import '../../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/auth/services/auth_callback_link_mapper.dart';
import 'package:taskly_bloc/presentation/routing/session_entry_policy.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  const mapper = AuthCallbackLinkMapper();

  testSafe(
    'maps native taskly callback host to canonical callback path',
    () async {
      final mapped = mapper.map(
        Uri.parse('taskly://auth-callback#type=recovery&token=abc'),
      );

      expect(mapped, isNotNull);
      expect(mapped!.path, authCallbackPath);
      expect(mapped.fragment, 'type=recovery&token=abc');
    },
  );

  testSafe('maps hosted callback paths to canonical callback path', () async {
    final mapped = mapper.map(
      Uri.parse(
        'https://sebastianhobby.github.io/taskly_bloc/auth/callback?type=recovery',
      ),
    );

    expect(mapped, isNotNull);
    expect(mapped!.path, authCallbackPath);
    expect(mapped.queryParameters['type'], 'recovery');
  });

  testSafe(
    'maps hash-route callback paths to canonical callback path',
    () async {
      final mapped = mapper.map(
        Uri.parse('https://example.com/#/auth/callback?type=recovery'),
      );

      expect(mapped, isNotNull);
      expect(mapped!.path, authCallbackPath);
      expect(mapped.fragment, '/auth/callback?type=recovery');
    },
  );

  testSafe('ignores non-callback links', () async {
    final mapped = mapper.map(
      Uri.parse('https://example.com/projects?tab=today'),
    );

    expect(mapped, isNull);
  });
}
