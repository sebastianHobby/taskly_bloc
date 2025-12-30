part of 'workflow_run_bloc.dart';

enum WorkflowRunStatus {
  initial,
  loading,
  running,
  completed,
  error,
}

@immutable
class WorkflowRunState<T> {
  const WorkflowRunState({
    this.status = WorkflowRunStatus.initial,
    this.items = const [],
    this.currentIndex = 0,
    this.progress,
    this.problems = const [],
    this.error,
    this.stackTrace,
  });

  final WorkflowRunStatus status;
  final List<WorkflowItem<T>> items;
  final int currentIndex;
  final WorkflowProgress? progress;
  final List<DetectedProblem> problems;
  final Object? error;
  final StackTrace? stackTrace;

  WorkflowRunState<T> copyWith({
    WorkflowRunStatus? status,
    List<WorkflowItem<T>>? items,
    int? currentIndex,
    WorkflowProgress? progress,
    List<DetectedProblem>? problems,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return WorkflowRunState<T>(
      status: status ?? this.status,
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      progress: progress ?? this.progress,
      problems: problems ?? this.problems,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  /// Current item being reviewed
  WorkflowItem<T>? get currentItem =>
      currentIndex < items.length ? items[currentIndex] : null;

  /// Whether there's a next item
  bool get hasNext => currentIndex < items.length - 1;

  /// Whether there's a previous item
  bool get hasPrevious => currentIndex > 0;

  /// Whether workflow is complete
  bool get isComplete =>
      status == WorkflowRunStatus.completed || (progress?.isComplete ?? false);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkflowRunState<T> &&
        other.status == status &&
        other.currentIndex == currentIndex &&
        other.progress == progress &&
        _listEquals(other.problems, problems) &&
        other.error == error &&
        other.stackTrace == stackTrace &&
        _listEquals(other.items, items);
  }

  @override
  int get hashCode => Object.hash(
    status,
    Object.hashAll(items),
    currentIndex,
    progress,
    Object.hashAll(problems),
    error,
    stackTrace,
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
