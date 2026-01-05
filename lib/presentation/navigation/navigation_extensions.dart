import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/value.dart';

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

/// Extension methods for navigation on Value model
extension ValueNavigation on Value {
  /// Navigate to this value's detail screen
  void navigateTo(BuildContext context) {
    Routing.toValue(context, this);
  }

  /// Get onTap callback for this value
  VoidCallback onTap(BuildContext context) {
    return () => navigateTo(context);
  }
}
