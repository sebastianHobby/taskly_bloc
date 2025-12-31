import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_session.dart';
import 'package:taskly_bloc/domain/interfaces/workflow_item_reviews_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/workflow_sessions_repository_contract.dart';
import 'package:taskly_bloc/domain/services/screens/screen_query_builder.dart';

part 'workflow_run_bloc.freezed.dart';

@freezed
sealed class WorkflowRunEvent with _$WorkflowRunEvent {
  const factory WorkflowRunEvent.started() = _Started;

  const factory WorkflowRunEvent.itemActionRequested({
    required String entityId,
    required EntityType entityType,
    required WorkflowAction action,
  }) = _ItemActionRequested;

  const factory WorkflowRunEvent.completeRequested() = _CompleteRequested;

  const factory WorkflowRunEvent.abandonRequested() = _AbandonRequested;

  const factory WorkflowRunEvent.sessionUpdated({WorkflowSession? session}) =
      _SessionUpdated;

  const factory WorkflowRunEvent.reviewsUpdated({
    required List<WorkflowItemReview> reviews,
  }) = _ReviewsUpdated;
}

@freezed
sealed class WorkflowRunState with _$WorkflowRunState {
  const factory WorkflowRunState.loading() = _Loading;

  const factory WorkflowRunState.running({
    required WorkflowScreen screen,
    required WorkflowSession session,
    required List<WorkflowItemVm> items,
    required Map<String, WorkflowAction> actionByEntityId,
  }) = _Running;

  const factory WorkflowRunState.completed({
    required WorkflowScreen screen,
    required WorkflowSession session,
  }) = _Completed;

  const factory WorkflowRunState.abandoned({
    required WorkflowScreen screen,
    required WorkflowSession session,
  }) = _Abandoned;

  const factory WorkflowRunState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = _Error;
}

@freezed
abstract class WorkflowItemVm with _$WorkflowItemVm {
  const factory WorkflowItemVm({
    required String entityId,
    required EntityType entityType,
    required String title,
  }) = _WorkflowItemVm;
}

class WorkflowRunBloc extends Bloc<WorkflowRunEvent, WorkflowRunState> {
  WorkflowRunBloc({
    required WorkflowScreen screen,
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required WorkflowSessionsRepositoryContract sessionsRepository,
    required WorkflowItemReviewsRepositoryContract itemReviewsRepository,
    required ScreenQueryBuilder queryBuilder,
  }) : _screen = screen,
       _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _sessionsRepository = sessionsRepository,
       _itemReviewsRepository = itemReviewsRepository,
       _queryBuilder = queryBuilder,
       super(const WorkflowRunState.loading()) {
    on<_Started>(_onStarted);
    on<_ItemActionRequested>(_onItemActionRequested);
    on<_CompleteRequested>(_onCompleteRequested);
    on<_AbandonRequested>(_onAbandonRequested);
    on<_SessionUpdated>(_onSessionUpdated);
    on<_ReviewsUpdated>(_onReviewsUpdated);
  }

  final WorkflowScreen _screen;
  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final WorkflowSessionsRepositoryContract _sessionsRepository;
  final WorkflowItemReviewsRepositoryContract _itemReviewsRepository;
  final ScreenQueryBuilder _queryBuilder;

  StreamSubscription<WorkflowSession?>? _sessionSub;
  StreamSubscription<List<WorkflowItemReview>>? _reviewsSub;

  List<WorkflowItemVm> _items = const [];
  String? _sessionId;

  @override
  Future<void> close() async {
    await _sessionSub?.cancel();
    await _reviewsSub?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    _Started event,
    Emitter<WorkflowRunState> emit,
  ) async {
    emit(const WorkflowRunState.loading());

    try {
      final items = await _loadItemsSnapshot(_screen);
      _items = items;

      final sessionId = await _sessionsRepository.startSession(
        screenId: _screen.id,
        totalItems: items.length,
      );
      _sessionId = sessionId;

      await _sessionSub?.cancel();
      _sessionSub = _sessionsRepository
          .watchSession(sessionId)
          .listen(
            (session) => add(WorkflowRunEvent.sessionUpdated(session: session)),
            onError: addError,
          );

      await _reviewsSub?.cancel();
      _reviewsSub = _itemReviewsRepository
          .watchSessionItemReviews(sessionId)
          .listen(
            (reviews) => add(WorkflowRunEvent.reviewsUpdated(reviews: reviews)),
            onError: addError,
          );
    } catch (e, s) {
      emit(WorkflowRunState.error(error: e, stackTrace: s));
    }
  }

  Future<void> _onItemActionRequested(
    _ItemActionRequested event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    try {
      await _itemReviewsRepository.addItemReview(
        sessionId: sessionId,
        entityType: event.entityType,
        entityId: event.entityId,
        action: event.action,
      );
    } catch (e, s) {
      emit(WorkflowRunState.error(error: e, stackTrace: s));
    }
  }

  Future<void> _onCompleteRequested(
    _CompleteRequested event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    try {
      await _sessionsRepository.completeSession(sessionId: sessionId);
    } catch (e, s) {
      emit(WorkflowRunState.error(error: e, stackTrace: s));
    }
  }

  Future<void> _onAbandonRequested(
    _AbandonRequested event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    try {
      await _sessionsRepository.abandonSession(sessionId: sessionId);
    } catch (e, s) {
      emit(WorkflowRunState.error(error: e, stackTrace: s));
    }
  }

  void _onSessionUpdated(
    _SessionUpdated event,
    Emitter<WorkflowRunState> emit,
  ) {
    final session = event.session;
    if (session == null) return;

    final actionByEntityId = state.maybeWhen(
      running: (screen, session, items, actionByEntityId) => actionByEntityId,
      orElse: () => const <String, WorkflowAction>{},
    );

    switch (session.status) {
      case WorkflowStatus.inProgress:
        emit(
          WorkflowRunState.running(
            screen: _screen,
            session: session,
            items: _items,
            actionByEntityId: actionByEntityId,
          ),
        );
        return;
      case WorkflowStatus.completed:
        emit(WorkflowRunState.completed(screen: _screen, session: session));
        return;
      case WorkflowStatus.abandoned:
        emit(WorkflowRunState.abandoned(screen: _screen, session: session));
        return;
    }
  }

  void _onReviewsUpdated(
    _ReviewsUpdated event,
    Emitter<WorkflowRunState> emit,
  ) {
    final actionByEntityId = <String, WorkflowAction>{
      for (final review in event.reviews) review.entityId: review.action,
    };

    final session = state.maybeWhen(
      running: (screen, session, items, actionByEntityId) => session,
      completed: (screen, session) => session,
      abandoned: (screen, session) => session,
      orElse: () => null,
    );

    if (session == null) return;

    emit(
      WorkflowRunState.running(
        screen: _screen,
        session: session,
        items: _items,
        actionByEntityId: actionByEntityId,
      ),
    );
  }

  Future<List<WorkflowItemVm>> _loadItemsSnapshot(WorkflowScreen screen) async {
    final selector = screen.selector;
    final display = screen.display;

    switch (selector.entityType) {
      case EntityType.task:
        final query = _queryBuilder.buildTaskQuery(
          selector: selector,
          display: display,
          now: DateTime.now(),
        );
        final tasks = await _taskRepository.watchAll(query).first;
        return tasks
            .map(
              (t) => WorkflowItemVm(
                entityId: t.id,
                entityType: EntityType.task,
                title: t.name,
              ),
            )
            .toList(growable: false);
      case EntityType.project:
        final query = _queryBuilder.buildProjectQuery(
          selector: selector,
          display: display,
        );
        final projects = await _projectRepository.watchAllByQuery(query).first;
        return projects
            .map(
              (p) => WorkflowItemVm(
                entityId: p.id,
                entityType: EntityType.project,
                title: p.name,
              ),
            )
            .toList(growable: false);
      case EntityType.label:
      case EntityType.goal:
        return const <WorkflowItemVm>[];
    }
  }
}
