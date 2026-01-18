@Tags(['unit'])
library;

import 'package:taskly_bloc/presentation/theme/app_colors.dart';

import '../../helpers/test_environment.dart';
import '../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe('AppColors exposes stable palette values', () async {
    expect(AppColors.tasklyNeonGreen.value, 0xFF13EC5B);
    expect(AppColors.mono100.value, 0xFF222222);
    expect(AppColors.blueberry100.value, 0xFF0093FF);
  });
}
