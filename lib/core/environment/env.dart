import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', useConstantCase: true, requireEnvFile: true)
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL', obfuscate: true)
  static final String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_PUBLISHABLE_KEY', obfuscate: true)
  static final String supabasePublishableKey = _Env.supabasePublishableKey;

  @EnviedField(varName: 'POWERSYNC_URL', obfuscate: true)
  static final String powersyncUrl = _Env.powersyncUrl;

  @EnviedField(varName: 'DEV_USERNAME', obfuscate: true)
  static final String devUsername = _Env.devUsername;

  @EnviedField(varName: 'DEV_PASSWORD', obfuscate: true)
  static final String devPassword = _Env.devPassword;
}
