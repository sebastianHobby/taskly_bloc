@Tags(['unit', 'auth'])
library;

import '../../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/auth/services/auth_callback_uri_parser.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  const parser = AuthCallbackUriParser();

  testSafe('parses error fields from query parameters', () async {
    final payload = parser.parse(
      Uri.parse(
        'https://example.com/#/auth/callback?error=access_denied&error_description=Link%20expired',
      ),
    );

    expect(payload.hasError, isTrue);
    expect(payload.error, 'access_denied');
    expect(payload.errorDescription, 'Link expired');
  });

  testSafe('parses recovery type from query parameters', () async {
    final payload = parser.parse(
      Uri.parse('https://example.com/auth/callback?type=recovery'),
    );

    expect(payload.isRecoveryFlow, isTrue);
    expect(payload.type, 'recovery');
  });

  testSafe('parses fragment query payload', () async {
    final payload = parser.parse(
      Uri.parse('taskly://auth-callback#type=recovery&foo=bar'),
    );

    expect(payload.isRecoveryFlow, isTrue);
    expect(payload.type, 'recovery');
  });

  testSafe('parses native callback query payload', () async {
    final payload = parser.parse(
      Uri.parse('taskly://auth-callback?type=recovery'),
    );

    expect(payload.isRecoveryFlow, isTrue);
    expect(payload.type, 'recovery');
  });

  testSafe('handles plain hash route fragments without params', () async {
    final payload = parser.parse(
      Uri.parse('https://example.com/#/auth/callback'),
    );

    expect(payload.hasError, isFalse);
    expect(payload.isRecoveryFlow, isFalse);
    expect(payload.type, isNull);
  });
}
