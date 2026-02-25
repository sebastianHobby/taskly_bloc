import 'package:taskly_bloc/bootstrap.dart';
import 'package:taskly_bloc/presentation/features/app/app.dart';
import 'package:taskly_core/env.dart';

Future<void> main() async {
  Env.config = const EnvConfig(
    name: 'prod',
    supabaseUrl: 'https://vhjyhzpymfjxafmwrjwn.supabase.co',
    supabasePublishableKey: 'sb_publishable_oeGIlYC2z1w7OYMm1RD8UA_Y-F0hW8D',
    powersyncUrl: 'https://69366a86af0dc7f759788260.powersync.journeyapps.com',
    authWebRedirectUrl:
        'https://sebastianhobby.github.io/taskly_bloc/auth/callback',
    authAppRedirectUrl: 'taskly://auth-callback',
    appVersion: String.fromEnvironment('APP_VERSION', defaultValue: 'unknown'),
    buildSha: String.fromEnvironment('BUILD_SHA', defaultValue: 'unknown'),
  );

  await bootstrap(() => const App());
}
