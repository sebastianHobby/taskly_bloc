import 'package:taskly_bloc/domain/settings.dart';

abstract class SettingsRepositoryContract {
  Stream<AppSettings> watch();
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}
