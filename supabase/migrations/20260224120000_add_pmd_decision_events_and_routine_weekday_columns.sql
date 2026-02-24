begin;

create extension if not exists pgcrypto;

create table if not exists public.my_day_decision_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  day_key_utc date not null,
  entity_type text not null,
  entity_id uuid not null,
  shelf text not null,
  action text not null,
  action_at_utc timestamptz not null,
  defer_kind text,
  from_day_key date,
  to_day_key date,
  suggestion_rank integer,
  meta_json jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  check (entity_type in ('task', 'routine')),
  check (shelf in ('due', 'planned', 'routine_scheduled', 'routine_flexible', 'suggestion')),
  check (action in ('kept', 'deferred', 'snoozed', 'removed', 'completed')),
  check (defer_kind is null or defer_kind in ('deadline_reschedule', 'start_reschedule', 'snooze')),
  check (suggestion_rank is null or suggestion_rank >= 0),
  check (meta_json is null or jsonb_typeof(meta_json) = 'object')
);

create index if not exists idx_my_day_decision_events_user_day_action
  on public.my_day_decision_events (user_id, day_key_utc, action);

create index if not exists idx_my_day_decision_events_entity_action_at
  on public.my_day_decision_events (entity_type, entity_id, action_at_utc);

create index if not exists idx_my_day_decision_events_shelf_action_at
  on public.my_day_decision_events (shelf, action_at_utc);

create index if not exists idx_my_day_decision_events_action_at
  on public.my_day_decision_events (action_at_utc);

alter table public.my_day_decision_events enable row level security;

drop policy if exists "my_day_decision_events_select_own" on public.my_day_decision_events;
create policy "my_day_decision_events_select_own"
on public.my_day_decision_events
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "my_day_decision_events_insert_own" on public.my_day_decision_events;
create policy "my_day_decision_events_insert_own"
on public.my_day_decision_events
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "my_day_decision_events_update_own" on public.my_day_decision_events;
create policy "my_day_decision_events_update_own"
on public.my_day_decision_events
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "my_day_decision_events_delete_own" on public.my_day_decision_events;
create policy "my_day_decision_events_delete_own"
on public.my_day_decision_events
for delete
to authenticated
using (auth.uid() = user_id);

grant all on table public.my_day_decision_events to anon;
grant all on table public.my_day_decision_events to authenticated;
grant all on table public.my_day_decision_events to service_role;
grant select on table public.my_day_decision_events to powersync_role;

alter table public.routine_completions
  add column if not exists completed_weekday_local integer;

alter table public.routine_completions
  add column if not exists timezone_offset_minutes integer;

create index if not exists idx_routine_completions_routine_weekday
  on public.routine_completions (routine_id, completed_weekday_local);

commit;
