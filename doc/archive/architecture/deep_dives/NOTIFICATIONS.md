# Notifications (Pending) -- Architecture

> Audience: developers
>
> Scope: the pending notifications pipeline (server -> local -> presenter).
> Descriptive only; invariants live in [../INVARIANTS.md](../INVARIANTS.md).

## 1) Purpose

Taskly receives **pending notifications** via sync and processes them locally.
The current presenter logs notifications; the pipeline is designed to swap in
real delivery later.

## 2) High-level flow

```text
PowerSync -> pending_notifications table
  -> PendingNotificationsRepositoryContract.watchPending()
  -> PendingNotificationsProcessor
  -> NotificationPresenter (current: logging)
```

## 3) Where things live

Domain:
- Model: `packages/taskly_domain/lib/src/notifications/model/pending_notification.dart`
- Repository contract:
  `packages/taskly_domain/lib/src/interfaces/pending_notifications_repository_contract.dart`
- Processor + presenter interface:
  `packages/taskly_domain/lib/src/services/notifications/`

Data:
- Drift table:
  `packages/taskly_data/lib/src/infrastructure/drift/features/screen_tables.drift.dart`
- Repository implementation:
  `packages/taskly_data/lib/src/features/notifications/repositories/pending_notifications_repository_impl.dart`
- Presenter (logging):
  `packages/taskly_data/lib/src/features/notifications/services/logging_notification_presenter.dart`

Wiring:
- Data stack + processor setup:
  `packages/taskly_data/lib/src/data_stack/taskly_data_stack.dart`

## 4) Notes

- Notifications are stored in `pending_notifications`.
- The presenter is intentionally swappable; logging is the current default.

## 5) Plan My Day reminder (local infrastructure)

Taskly now includes a local reminder coordinator for Plan My Day:

```text
GlobalSettings(planMyDayReminderEnabled/time + home offset)
  + HomeDayKeyService + TemporalTriggerService
  + MyDayRepository.loadDay(todayDayKey)
  -> PlanMyDayReminderService
  -> NotificationPresenter
```

Behavior:
- Runs only in authenticated app session startup.
- Uses home-day semantics (`HomeDayKeyService`) and reminder time in minutes.
- Emits at most one reminder per home day.
- Skips reminder when today's plan already exists (`ritualCompletedAtUtc != null`).
