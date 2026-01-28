@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_domain/taskly_domain.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  blocTestSafe<SelectionBloc, SelectionState>(
    'enters selection mode and selects initial item',
    build: SelectionBloc.new,
    act: (bloc) => bloc.add(
      const SelectionToggleRequested(
        key: SelectionKey(entityType: EntityType.task, entityId: 'task-1'),
        extendRange: false,
      ),
    ),
    expect: () => [
      isA<SelectionState>()
          .having((s) => s.isSelectionMode, 'mode', true)
          .having((s) => s.selected.length, 'selected', 1),
    ],
  );

  blocTestSafe<SelectionBloc, SelectionState>(
    'exits selection mode when selection cleared',
    build: SelectionBloc.new,
    act: (bloc) async {
      bloc.add(
        const SelectionEnterRequested(
          initialSelection: SelectionKey(
            entityType: EntityType.task,
            entityId: 'task-1',
          ),
        ),
      );
      bloc.add(
        const SelectionToggleRequested(
          key: SelectionKey(entityType: EntityType.task, entityId: 'task-1'),
          extendRange: false,
        ),
      );
    },
    expect: () => [
      isA<SelectionState>().having((s) => s.isSelectionMode, 'mode', true),
      isA<SelectionState>().having((s) => s.selected.isEmpty, 'empty', true),
      SelectionState.empty,
    ],
  );
}
