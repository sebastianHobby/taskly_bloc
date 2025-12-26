import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/entity_type.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_action.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_action_type.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_query.dart';

void main() {
  group('Review', () {
    final now = DateTime(2025, 12, 26);
    final nextDue = DateTime(2026, 1, 2);

    test('creates instance with required fields', () {
      const reviewQuery = ReviewQuery(entityType: EntityType.task);
      final review = Review(
        id: 'review-1',
        userId: 'user-1',
        name: 'Weekly Review',
        query: reviewQuery,
        rrule: 'FREQ=WEEKLY',
        nextDueDate: nextDue,
        createdAt: now,
        updatedAt: now,
      );

      expect(review.id, 'review-1');
      expect(review.userId, 'user-1');
      expect(review.name, 'Weekly Review');
      expect(review.query, reviewQuery);
      expect(review.rrule, 'FREQ=WEEKLY');
      expect(review.nextDueDate, nextDue);
      expect(review.createdAt, now);
      expect(review.updatedAt, now);
      expect(review.description, isNull);
      expect(review.lastCompletedAt, isNull);
      expect(review.deletedAt, isNull);
    });

    test('creates instance with all fields', () {
      const reviewQuery = ReviewQuery(
        entityType: EntityType.task,
        projectIds: ['project-1'],
        includeCompleted: false,
      );
      final lastCompleted = DateTime(2025, 12, 19);

      final review = Review(
        id: 'review-1',
        userId: 'user-1',
        name: 'Weekly Review',
        query: reviewQuery,
        rrule: 'FREQ=WEEKLY',
        nextDueDate: nextDue,
        createdAt: now,
        updatedAt: now,
        description: 'Review all pending tasks',
        lastCompletedAt: lastCompleted,
      );

      expect(review.description, 'Review all pending tasks');
      expect(review.lastCompletedAt, lastCompleted);
    });

    test('toJson serializes correctly', () {
      const reviewQuery = ReviewQuery(entityType: EntityType.task);
      final review = Review(
        id: 'review-1',
        userId: 'user-1',
        name: 'Weekly Review',
        query: reviewQuery,
        rrule: 'FREQ=WEEKLY',
        nextDueDate: nextDue,
        createdAt: now,
        updatedAt: now,
      );

      final json = review.toJson();

      expect(json['id'], 'review-1');
      expect(json['userId'], 'user-1');
      expect(json['name'], 'Weekly Review');
      expect(json['rrule'], 'FREQ=WEEKLY');
      expect(json['query'], isA<Map>());
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'review-1',
        'userId': 'user-1',
        'name': 'Weekly Review',
        'query': {
          'entityType': 'task',
        },
        'rrule': 'FREQ=WEEKLY',
        'nextDueDate': nextDue.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final review = Review.fromJson(json);

      expect(review.id, 'review-1');
      expect(review.userId, 'user-1');
      expect(review.name, 'Weekly Review');
      expect(review.query.entityType, EntityType.task);
      expect(review.rrule, 'FREQ=WEEKLY');
    });

    test('fromJson handles optional fields', () {
      final lastCompleted = DateTime(2025, 12, 19);
      final json = {
        'id': 'review-1',
        'userId': 'user-1',
        'name': 'Weekly Review',
        'query': {
          'entityType': 'task',
        },
        'rrule': 'FREQ=WEEKLY',
        'nextDueDate': nextDue.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'description': 'Test description',
        'lastCompletedAt': lastCompleted.toIso8601String(),
      };

      final review = Review.fromJson(json);

      expect(review.description, 'Test description');
      expect(review.lastCompletedAt, lastCompleted);
    });

    test('copyWith creates new instance with updated fields', () {
      const reviewQuery = ReviewQuery(entityType: EntityType.task);
      final review = Review(
        id: 'review-1',
        userId: 'user-1',
        name: 'Weekly Review',
        query: reviewQuery,
        rrule: 'FREQ=WEEKLY',
        nextDueDate: nextDue,
        createdAt: now,
        updatedAt: now,
      );

      final updated = review.copyWith(
        name: 'Updated Review',
        description: 'New description',
      );

      expect(updated.id, review.id);
      expect(updated.name, 'Updated Review');
      expect(updated.description, 'New description');
      expect(updated.query, review.query);
    });
  });

  group('ReviewQuery', () {
    test('creates instance with required entityType', () {
      const query = ReviewQuery(entityType: EntityType.task);

      expect(query.entityType, EntityType.task);
      expect(query.projectIds, isNull);
      expect(query.labelIds, isNull);
      expect(query.valueIds, isNull);
      expect(query.includeCompleted, isNull);
      expect(query.completedBefore, isNull);
      expect(query.completedAfter, isNull);
      expect(query.createdBefore, isNull);
      expect(query.createdAfter, isNull);
    });

    test('creates instance with all fields', () {
      final completedBefore = DateTime(2025, 12, 31);
      final createdAfter = DateTime(2025);

      final query = ReviewQuery(
        entityType: EntityType.project,
        projectIds: ['project-1', 'project-2'],
        labelIds: ['label-1'],
        valueIds: ['value-1'],
        includeCompleted: false,
        completedBefore: completedBefore,
        createdAfter: createdAfter,
      );

      expect(query.entityType, EntityType.project);
      expect(query.projectIds, ['project-1', 'project-2']);
      expect(query.labelIds, ['label-1']);
      expect(query.valueIds, ['value-1']);
      expect(query.includeCompleted, isFalse);
      expect(query.completedBefore, completedBefore);
      expect(query.createdAfter, createdAfter);
    });

    test('toJson serializes correctly', () {
      const query = ReviewQuery(
        entityType: EntityType.task,
        projectIds: ['project-1'],
        includeCompleted: false,
      );

      final json = query.toJson();

      expect(json['entityType'], 'task');
      expect(json['projectIds'], ['project-1']);
      expect(json['includeCompleted'], isFalse);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'entityType': 'label',
        'labelIds': ['label-1', 'label-2'],
        'includeCompleted': true,
      };

      final query = ReviewQuery.fromJson(json);

      expect(query.entityType, EntityType.label);
      expect(query.labelIds, ['label-1', 'label-2']);
      expect(query.includeCompleted, isTrue);
    });

    test('copyWith creates new instance with updated fields', () {
      const query = ReviewQuery(
        entityType: EntityType.task,
        includeCompleted: false,
      );

      final updated = query.copyWith(
        includeCompleted: true,
      );

      expect(updated.entityType, query.entityType);
      expect(updated.includeCompleted, isTrue);
    });
  });

  group('ReviewAction', () {
    test('creates instance with required type', () {
      const action = ReviewAction(type: ReviewActionType.skip);

      expect(action.type, ReviewActionType.skip);
      expect(action.updateData, isNull);
      expect(action.notes, isNull);
    });

    test('creates instance with all fields', () {
      final updateData = {
        'completed': true,
        'name': 'Updated',
      };

      final action = ReviewAction(
        type: ReviewActionType.update,
        updateData: updateData,
        notes: 'Updated during review',
      );

      expect(action.type, ReviewActionType.update);
      expect(action.updateData, updateData);
      expect(action.notes, 'Updated during review');
    });

    test('toJson serializes correctly', () {
      const action = ReviewAction(
        type: ReviewActionType.complete,
        notes: 'Completed',
      );

      final json = action.toJson();

      expect(json['type'], 'complete');
      expect(json['notes'], 'Completed');
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'type': 'delete',
        'notes': 'No longer needed',
      };

      final action = ReviewAction.fromJson(json);

      expect(action.type, ReviewActionType.delete);
      expect(action.notes, 'No longer needed');
    });

    test('fromJson with updateData', () {
      final json = {
        'type': 'update',
        'updateData': {
          'name': 'New Name',
          'completed': true,
        },
      };

      final action = ReviewAction.fromJson(json);

      expect(action.type, ReviewActionType.update);
      expect(action.updateData, isNotNull);
      expect(action.updateData!['name'], 'New Name');
      expect(action.updateData!['completed'], isTrue);
    });

    test('copyWith creates new instance with updated fields', () {
      const action = ReviewAction(
        type: ReviewActionType.skip,
      );

      final updated = action.copyWith(
        notes: 'Will review later',
      );

      expect(updated.type, action.type);
      expect(updated.notes, 'Will review later');
    });

    test('supports all ReviewActionType values', () {
      final types = [
        ReviewActionType.update,
        ReviewActionType.complete,
        ReviewActionType.archive,
        ReviewActionType.delete,
        ReviewActionType.skip,
      ];

      for (final type in types) {
        final action = ReviewAction(type: type);
        expect(action.type, type);
      }
    });
  });
}
