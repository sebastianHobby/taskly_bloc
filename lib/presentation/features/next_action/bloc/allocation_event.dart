part of 'allocation_bloc.dart';

/// Events for allocation management
sealed class AllocationEvent {
  const AllocationEvent();
}

/// Subscribe to allocation stream
class AllocationSubscriptionRequested extends AllocationEvent {
  const AllocationSubscriptionRequested();
}

/// Pin a task to focus list
class AllocationTaskPinned extends AllocationEvent {
  const AllocationTaskPinned(this.taskId);
  final String taskId;
}

/// Unpin a task from focus list
class AllocationTaskUnpinned extends AllocationEvent {
  const AllocationTaskUnpinned(this.taskId);
  final String taskId;
}

/// Manually refresh allocation
class AllocationRefreshRequested extends AllocationEvent {
  const AllocationRefreshRequested();
}

/// Dismiss excluded urgent tasks warning
class AllocationExcludedDismissed extends AllocationEvent {
  const AllocationExcludedDismissed();
}

/// Bulk pin tasks
class AllocationBulkTasksPinned extends AllocationEvent {
  const AllocationBulkTasksPinned(this.taskIds);
  final List<String> taskIds;
}

/// Toggle task completion
class AllocationTaskCompletionToggled extends AllocationEvent {
  const AllocationTaskCompletionToggled(this.taskId);
  final String taskId;
}
