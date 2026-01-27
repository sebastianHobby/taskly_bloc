@Tags(['widget', 'tasks'])
library;

import 'package:provider/provider.dart';

import '../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/core.dart';

class FakeNowService implements NowService {
  FakeNowService(this.now);

  final DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('marks task due today in tile data', (tester) async {
    final now = DateTime(2025, 1, 15, 9);
    final task = TestData.task(deadlineDate: DateTime(2025, 1, 15, 12));
    TasklyTaskRowData? data;

    await tester.pumpApp(
      Provider<NowService>.value(
        value: FakeNowService(now),
        child: Builder(
          builder: (context) {
            data = buildTaskRowData(
              context,
              task: task,
              tileCapabilities: const EntityTileCapabilities(),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(data, isNotNull);
    expect(data!.meta.isDueToday, isTrue);
    expect(data!.meta.isOverdue, isFalse);
  });
}
