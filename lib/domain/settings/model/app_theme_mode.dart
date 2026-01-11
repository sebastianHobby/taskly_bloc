/// Theme mode preference stored in settings.
///
/// This is a domain-pure representation (no Flutter dependency). Presentation
/// code can map this to Flutter's `ThemeMode`.
enum AppThemeMode {
  system,
  light,
  dark;

  static AppThemeMode fromName(String? name) {
    return AppThemeMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppThemeMode.system,
    );
  }
}
