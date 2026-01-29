import 'package:integration_test/integration_test.dart';

import '../test/integration_test/powersync_pipeline_test.dart' as pipeline;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  pipeline.main();
}
