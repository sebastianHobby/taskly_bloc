@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../helpers/test_imports.dart';
import 'package:taskly_data/src/repositories/auth_repository.dart';
import 'package:taskly_domain/auth.dart';

class _MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class _MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late _MockSupabaseClient client;
  late _MockGoTrueClient authClient;

  setUp(() {
    client = _MockSupabaseClient();
    authClient = _MockGoTrueClient();
    when(() => client.auth).thenReturn(authClient);
  });

  testSafe('signInWithPassword maps auth response', () async {
    when(
      () => authClient.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => supabase.AuthResponse());

    final repo = AuthRepository(client: client);
    final response = await repo.signInWithPassword(
      email: 'user@test.com',
      password: 'secret',
    );

    expect(response, isA<AuthResponse>());
    expect(response.session, isNull);
  });

  testSafe('updateUserProfile maps user response', () async {
    when(
      () => authClient.updateUser(any(that: isA<supabase.UserAttributes>())),
    ).thenAnswer(
      (_) async => supabase.UserResponse.fromJson({
        'id': 'user-1',
        'aud': 'authenticated',
        'created_at': '2025-01-01T00:00:00Z',
      }),
    );

    final repo = AuthRepository(client: client);
    final response = await repo.updateUserProfile(displayName: 'Alex');

    expect(response.user?.id, 'user-1');
  });
}
