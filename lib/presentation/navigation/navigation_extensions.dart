import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/label.dart';

/// Extension methods for navigation on entity models
extension TaskNavigation on Task {
  /// Navigate to this task's detail screen
  void navigateTo(BuildContext context) {
    Routing.toTask(context, this);
  }

  /// Get onTap callback for this task
  VoidCallback onTap(BuildContext context) {
    return () => navigateTo(context);
  }
}

/// Extension methods for navigation on Project model
extension ProjectNavigation on Project {
  /// Navigate to this project's detail screen
  void navigateTo(BuildContext context) {
    Routing.toProject(context, this);
  }

  /// Get onTap callback for this project
  VoidCallback onTap(BuildContext context) {
    return () => navigateTo(context);
  }
}

/// Extension methods for navigation on Label model
extension LabelNavigation on Label {
  /// Navigate to this label's detail screen
  void navigateTo(BuildContext context) {
    Routing.toLabel(context, this);
  }

  /// Get onTap callback for this label
  VoidCallback onTap(BuildContext context) {
    return () => navigateTo(context);
  }
}
