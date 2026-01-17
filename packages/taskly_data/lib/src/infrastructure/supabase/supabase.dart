import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_core/env.dart';

Future<void> loadSupabase() async {
  final supabaseUrl = Env.supabaseUrl.trim();
  final supabaseAnonKey = Env.supabasePublishableKey.trim();

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    const hint = kIsWeb
        ? 'On web, pass values via --dart-define (recommended: --dart-define-from-file=dart_defines.json).'
        : 'Create a .env file (see ENVIRONMENT_SETUP.md) or pass values via --dart-define.';

    throw StateError(
      'Supabase configuration is missing. '
      'SUPABASE_URL empty=${supabaseUrl.isEmpty}, '
      'SUPABASE_PUBLISHABLE_KEY empty=${supabaseAnonKey.isEmpty}. '
      '$hint',
    );
  }

  final parsed = Uri.tryParse(supabaseUrl);
  if (parsed == null || !parsed.hasScheme) {
    throw StateError(
      'Invalid SUPABASE_URL "$supabaseUrl". Expected a full URL like '
      'https://<project>.supabase.co',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}
