import 'package:flutter/foundation.dart';

@immutable
class ProjectNextActionDraft {
  const ProjectNextActionDraft({
    required this.taskId,
    required this.rank,
  });

  final String taskId;
  final int rank;
}
