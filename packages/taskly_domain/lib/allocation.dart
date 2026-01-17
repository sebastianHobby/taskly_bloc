/// Allocation bounded-context types.
library;

export 'src/allocation/contracts/allocation_snapshot_repository_contract.dart';

export 'src/allocation/engine/allocation_day_stats_service.dart';
export 'src/allocation/engine/allocation_orchestrator.dart';
export 'src/allocation/engine/allocation_strategy.dart';
export 'src/allocation/engine/allocation_snapshot_auto_refresh_service.dart';
export 'src/allocation/engine/allocation_snapshot_coordinator.dart';
export 'src/allocation/engine/neglect_based_allocator.dart';
export 'src/allocation/engine/urgency_weighted_allocator.dart';

export 'src/allocation/model/allocation_config.dart';
export 'src/allocation/model/allocation_day_stats.dart';
export 'src/allocation/model/allocation_exception_rule.dart';
export 'src/allocation/model/allocation_project_history_window.dart';
export 'src/allocation/model/allocation_result.dart';
export 'src/allocation/model/allocation_snapshot.dart';
export 'src/allocation/model/focus_mode.dart';

export 'src/priority/model/allocation_preference.dart';
