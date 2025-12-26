class Constants {
  Constants._();

  static const String tag = 'FMR';

  static const String supabaseLoginCallback =
      'com.areser.flutter_mvvm_riverpod://login-callback/';
  static const String supabaseProfileTable = 'profile';
  static const String googleEmailScope = 'email';
  static const String googleUserInfoScope =
      'https://www.googleapis.com/auth/userinfo.profile';

  static const String premium = 'premium';
  static const String premiumMonthly = r'$rc_monthly';
  static const String premiumYearly = r'$rc_annual';
  static const String premiumLifeTime = r'$rc_lifetime';

  static const String defaultName = 'Sebastian';
  static const String defaultEmail = 'sebas.home1@gmail.com';
  static const String aboutUs = 'https://google.com';
  static const String appStore = 'https://google.com';
  static const String playStore = 'https://google.com';
  static const String facebookPage = 'https://google.com';

  static const String termOfService = 'https://google.com';
  static const String privacyPolicy = 'https://google.com';
  // SharedPreferences key
  static const String themeModeKey = 'theme_mode_key';
  static const String profileKey = 'profile_key';
  static const String isLoginKey = 'is_login_key';
  static const String isExistAccountKey = 'is_exist_account_key';
  static const String lastDayShowPremiumKey = 'last_day_show_premium_key';
}
