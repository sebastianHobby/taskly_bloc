import 'package:taskly_bloc/presentation/features/analytics/domain/models/entity_type.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_query.dart';

class ReviewTemplates {
  /// Template for reviewing project health
  static Review projectHealthTemplate({
    required String rrule,
  }) {
    return Review(
      id: '',
      name: 'Project Health Check',
      description: 'Review projects with low completion rates',
      query: const ReviewQuery(
        entityType: EntityType.project,
        includeCompleted: false,
      ),
      rrule: rrule,
      nextDueDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Template for weekly values review
  static Review weeklyValuesTemplate({
    required String rrule,
  }) {
    return Review(
      id: '',
      name: 'Weekly Values Review',
      description: 'Review tasks aligned with your values',
      query: const ReviewQuery(
        entityType: EntityType.task,
        includeCompleted: false,
      ),
      rrule: rrule,
      nextDueDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Template for stale tasks review
  static Review staleTasksTemplate({
    required String rrule,
  }) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return Review(
      id: '',
      name: 'Stale Tasks Review',
      description: 'Review tasks not completed in 30+ days',
      query: ReviewQuery(
        entityType: EntityType.task,
        includeCompleted: false,
        createdBefore: thirtyDaysAgo,
      ),
      rrule: rrule,
      nextDueDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Template for completed items retrospective
  static Review completedRetrospectiveTemplate({
    required String rrule,
  }) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return Review(
      id: '',
      name: 'Weekly Retrospective',
      description: 'Review what you completed this week',
      query: ReviewQuery(
        entityType: EntityType.task,
        includeCompleted: true,
        completedAfter: sevenDaysAgo,
      ),
      rrule: rrule,
      nextDueDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Get all available templates
  static List<Review Function({required String rrule})> allTemplates() {
    return [
      projectHealthTemplate,
      weeklyValuesTemplate,
      staleTasksTemplate,
      completedRetrospectiveTemplate,
    ];
  }
}
