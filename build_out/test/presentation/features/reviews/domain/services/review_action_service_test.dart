import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/entity_type.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_action.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_action_type.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/services/review_action_service.dart';

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

void main() {
  group('ReviewActionService', () {
    late MockTaskRepository mockTaskRepository;
    late ReviewActionService service;
    late Task testTask;

    setUp(() {
      mockTaskRepository = MockTaskRepository();
      service = ReviewActionService(mockTaskRepository);

      final now = DateTime(2025, 12, 26);
      testTask = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
        description: 'Test description',
      );
    });

    setUpAll(() {
      registerFallbackValue(DateTime(2025));
    });

    group('executeTaskAction', () {
      test('skip action performs no operation', () async {
        const action = ReviewAction(type: ReviewActionType.skip);

        await service.executeTaskAction(testTask, action);

        verifyNever(
          () => mockTaskRepository.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            completed: any(named: 'completed'),
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            deadlineDate: any(named: 'deadlineDate'),
            projectId: any(named: 'projectId'),
            repeatIcalRrule: any(named: 'repeatIcalRrule'),
            repeatFromCompletion: any(named: 'repeatFromCompletion'),
            labelIds: any(named: 'labelIds'),
          ),
        );
        verifyNever(() => mockTaskRepository.delete(any()));
      });

      test('complete action marks task as completed', () async {
        const action = ReviewAction(type: ReviewActionType.complete);

        when(
          () => mockTaskRepository.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            completed: any(named: 'completed'),
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            deadlineDate: any(named: 'deadlineDate'),
            projectId: any(named: 'projectId'),
            repeatIcalRrule: any(named: 'repeatIcalRrule'),
            repeatFromCompletion: any(named: 'repeatFromCompletion'),
            labelIds: any(named: 'labelIds'),
          ),
        ).thenAnswer((_) async {});

        await service.executeTaskAction(testTask, action);

        verify(
          () => mockTaskRepository.update(
            id: testTask.id,
            name: testTask.name,
            completed: true,
            description: testTask.description,
            startDate: testTask.startDate,
            deadlineDate: testTask.deadlineDate,
            projectId: testTask.projectId,
            repeatIcalRrule: testTask.repeatIcalRrule,
            repeatFromCompletion: testTask.repeatFromCompletion,
            labelIds: any(named: 'labelIds'),
          ),
        ).called(1);
      });

      test('delete action deletes the task', () async {
        const action = ReviewAction(type: ReviewActionType.delete);

        when(() => mockTaskRepository.delete(any())).thenAnswer((_) async {});

        await service.executeTaskAction(testTask, action);

        verify(() => mockTaskRepository.delete(testTask.id)).called(1);
      });

      test('update action applies updates to task', () async {
        final action = ReviewAction(
          type: ReviewActionType.update,
          updateData: {
            'name': 'Updated Task Name',
            'description': 'Updated description',
          },
        );

        when(
          () => mockTaskRepository.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            completed: any(named: 'completed'),
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            deadlineDate: any(named: 'deadlineDate'),
            projectId: any(named: 'projectId'),
            repeatIcalRrule: any(named: 'repeatIcalRrule'),
            repeatFromCompletion: any(named: 'repeatFromCompletion'),
            labelIds: any(named: 'labelIds'),
          ),
        ).thenAnswer((_) async {});

        await service.executeTaskAction(testTask, action);

        verify(
          () => mockTaskRepository.update(
            id: testTask.id,
            name: 'Updated Task Name',
            completed: testTask.completed,
            description: 'Updated description',
            startDate: testTask.startDate,
            deadlineDate: testTask.deadlineDate,
            projectId: any(named: 'projectId'),
            repeatIcalRrule: testTask.repeatIcalRrule,
            repeatFromCompletion: testTask.repeatFromCompletion,
            labelIds: any(named: 'labelIds'),
          ),
        ).called(1);
      });

      test('update action with null updateData does nothing', () async {
        const action = ReviewAction(
          type: ReviewActionType.update,
        );

        await service.executeTaskAction(testTask, action);

        verifyNever(
          () => mockTaskRepository.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            completed: any(named: 'completed'),
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            deadlineDate: any(named: 'deadlineDate'),
            projectId: any(named: 'projectId'),
            repeatIcalRrule: any(named: 'repeatIcalRrule'),
            repeatFromCompletion: any(named: 'repeatFromCompletion'),
            labelIds: any(named: 'labelIds'),
          ),
        );
      });

      test('update action updates deadline date from string', () async {
        final deadline = DateTime(2026, 1, 15);
        final action = ReviewAction(
          type: ReviewActionType.update,
          updateData: {
            'deadlineDate': deadline.toIso8601String(),
          },
        );

        when(
          () => mockTaskRepository.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            completed: any(named: 'completed'),
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            deadlineDate: any(named: 'deadlineDate'),
            projectId: any(named: 'projectId'),
            repeatIcalRrule: any(named: 'repeatIcalRrule'),
            repeatFromCompletion: any(named: 'repeatFromCompletion'),
            labelIds: any(named: 'labelIds'),
          ),
        ).thenAnswer((_) async {});

        await service.executeTaskAction(testTask, action);

        verify(
          () => mockTaskRepository.update(
            id: testTask.id,
            name: testTask.name,
            completed: testTask.completed,
            description: any(named: 'description'),
            startDate: testTask.startDate,
            deadlineDate: deadline,
            projectId: any(named: 'projectId'),
            repeatIcalRrule: testTask.repeatIcalRrule,
            repeatFromCompletion: testTask.repeatFromCompletion,
            labelIds: any(named: 'labelIds'),
          ),
        ).called(1);
      });

      test('update action updates project ID', () async {
        final action = ReviewAction(
          type: ReviewActionType.update,
          updateData: {
            'projectId': 'new-project-1',
          },
        );

        when(
          () => mockTaskRepository.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            completed: any(named: 'completed'),
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            deadlineDate: any(named: 'deadlineDate'),
            projectId: any(named: 'projectId'),
            repeatIcalRrule: any(named: 'repeatIcalRrule'),
            repeatFromCompletion: any(named: 'repeatFromCompletion'),
            labelIds: any(named: 'labelIds'),
          ),
        ).thenAnswer((_) async {});

        await service.executeTaskAction(testTask, action);

        verify(
          () => mockTaskRepository.update(
            id: testTask.id,
            name: testTask.name,
            completed: testTask.completed,
            description: any(named: 'description'),
            startDate: testTask.startDate,
            deadlineDate: testTask.deadlineDate,
            projectId: 'new-project-1',
            repeatIcalRrule: testTask.repeatIcalRrule,
            repeatFromCompletion: testTask.repeatFromCompletion,
            labelIds: any(named: 'labelIds'),
          ),
        ).called(1);
      });

      test('archive action does nothing (not yet implemented)', () async {
        const action = ReviewAction(type: ReviewActionType.archive);

        await service.executeTaskAction(testTask, action);

        verifyNever(
          () => mockTaskRepository.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            completed: any(named: 'completed'),
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            deadlineDate: any(named: 'deadlineDate'),
            projectId: any(named: 'projectId'),
            repeatIcalRrule: any(named: 'repeatIcalRrule'),
            repeatFromCompletion: any(named: 'repeatFromCompletion'),
            labelIds: any(named: 'labelIds'),
          ),
        );
        verifyNever(() => mockTaskRepository.delete(any()));
      });
    });

    group('getRecommendedActions', () {
      test('returns empty list (not yet implemented)', () async {
        final actions = await service.getRecommendedActions(
          entityType: EntityType.task,
          entityId: 'task-1',
        );

        expect(actions, isEmpty);
      });
    });
  });
}
