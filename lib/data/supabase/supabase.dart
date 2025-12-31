import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_bloc/core/environment/env.dart';

Future<void> loadSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabasePublishableKey,
  );
}
