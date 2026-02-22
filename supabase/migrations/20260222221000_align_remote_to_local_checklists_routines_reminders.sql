-- Align hosted Supabase schema to local PowerSync + Drift contracts.
-- Explicitly remove legacy project_next_actions artifacts and legacy routine-field data.

do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'routine_period_type_enum'
  ) then
    create type "public"."routine_period_type_enum" as enum ('day', 'week', 'fortnight', 'month');
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'routine_schedule_mode_enum'
  ) then
    create type "public"."routine_schedule_mode_enum" as enum ('flexible', 'scheduled');
  end if;
end $$;

drop trigger if exists "trg_project_next_actions_task_project_guard" on "public"."tasks";

drop policy if exists "routines_insert" on "public"."routines";

drop function if exists "public"."project_next_actions_task_project_guard"();

drop table if exists "public"."project_next_actions" cascade;

alter table "public"."routine_skips" drop constraint if exists "routine_skips_period_type_check";

alter table "public"."routines" drop constraint if exists "routines_fixed_day_of_month_check";

alter table "public"."routines" drop constraint if exists "routines_fixed_week_of_month_check";

alter table "public"."routines" drop constraint if exists "routines_fixed_weekday_check";

alter table "public"."routines" drop constraint if exists "routines_routine_type_check";

alter table "public"."routines" drop constraint if exists "routines_value_id_fkey";

drop index if exists "public"."routines_value_id_idx";


  create table if not exists "public"."checklist_events" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null default auth.uid(),
    "parent_type" text not null,
    "parent_id" uuid not null,
    "checklist_item_id" uuid,
    "scope_period_type" text,
    "scope_date" date,
    "event_type" text not null,
    "metrics_json" jsonb not null default '{}'::jsonb,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."checklist_events" enable row level security;


  create table if not exists "public"."routine_checklist_item_state" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null default auth.uid(),
    "routine_id" uuid not null,
    "checklist_item_id" uuid not null,
    "period_type" public.routine_period_type_enum not null,
    "window_key" date not null,
    "is_checked" boolean not null default false,
    "checked_at" timestamp with time zone,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."routine_checklist_item_state" enable row level security;


  create table if not exists "public"."routine_checklist_items" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null default auth.uid(),
    "routine_id" uuid not null,
    "title" text not null,
    "sort_index" integer not null default 0,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."routine_checklist_items" enable row level security;


  create table if not exists "public"."task_checklist_item_state" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null default auth.uid(),
    "task_id" uuid not null,
    "checklist_item_id" uuid not null,
    "occurrence_date" date,
    "is_checked" boolean not null default false,
    "checked_at" timestamp with time zone,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."task_checklist_item_state" enable row level security;


  create table if not exists "public"."task_checklist_items" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null default auth.uid(),
    "task_id" uuid not null,
    "title" text not null,
    "sort_index" integer not null default 0,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."task_checklist_items" enable row level security;

alter table "public"."routine_completions" add column if not exists "completed_day_local" date;

alter table "public"."routine_completions" add column if not exists "completed_time_local_minutes" integer;

alter table "public"."routine_skips" alter column "period_type" set data type public.routine_period_type_enum using "period_type"::public.routine_period_type_enum;

-- Explicitly discard legacy routine payloads before dropping legacy columns.
delete from "public"."routine_completions"
where routine_id in (select id from "public"."routines");

delete from "public"."routine_skips"
where routine_id in (select id from "public"."routines");

truncate table "public"."routine_checklist_item_state";

truncate table "public"."routine_checklist_items";

delete from "public"."routines";

alter table "public"."routines" drop column if exists "fixed_day_of_month";

alter table "public"."routines" drop column if exists "fixed_week_of_month";

alter table "public"."routines" drop column if exists "fixed_weekday";

alter table "public"."routines" drop column if exists "preferred_weeks";

alter table "public"."routines" drop column if exists "routine_type";

alter table "public"."routines" drop column if exists "value_id";

alter table "public"."routines" add column if not exists "period_type" public.routine_period_type_enum not null;

alter table "public"."routines" add column if not exists "project_id" uuid not null;

alter table "public"."routines" add column if not exists "schedule_mode" public.routine_schedule_mode_enum not null;

alter table "public"."routines" add column if not exists "schedule_month_days" integer[];

alter table "public"."routines" add column if not exists "schedule_time_minutes" smallint;

alter table "public"."tasks" add column if not exists "reminder_at_utc" timestamp with time zone;

alter table "public"."tasks" add column if not exists "reminder_kind" text not null default 'none'::text;

alter table "public"."tasks" add column if not exists "reminder_minutes_before_due" integer;

alter table "public"."tasks" alter column "my_day_snoozed_until" set data type timestamp with time zone using "my_day_snoozed_until"::timestamp with time zone;

CREATE UNIQUE INDEX IF NOT EXISTS checklist_events_pkey ON public.checklist_events USING btree (id);

CREATE INDEX IF NOT EXISTS idx_checklist_events_scope ON public.checklist_events USING btree (scope_period_type, scope_date);

CREATE INDEX IF NOT EXISTS idx_checklist_events_user_parent_time ON public.checklist_events USING btree (user_id, parent_type, parent_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_routine_checklist_items_routine_sort ON public.routine_checklist_items USING btree (routine_id, sort_index);

CREATE INDEX IF NOT EXISTS idx_routine_checklist_items_user_id ON public.routine_checklist_items USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_routine_checklist_state_routine_window ON public.routine_checklist_item_state USING btree (routine_id, period_type, window_key);

CREATE INDEX IF NOT EXISTS idx_routine_checklist_state_user_id ON public.routine_checklist_item_state USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_task_checklist_items_task_sort ON public.task_checklist_items USING btree (task_id, sort_index);

CREATE INDEX IF NOT EXISTS idx_task_checklist_items_user_id ON public.task_checklist_items USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_task_checklist_state_task_occurrence ON public.task_checklist_item_state USING btree (task_id, occurrence_date);

CREATE INDEX IF NOT EXISTS idx_task_checklist_state_user_id ON public.task_checklist_item_state USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_tasks_reminder_absolute_due ON public.tasks USING btree (reminder_at_utc) WHERE (reminder_kind = 'absolute'::text);

CREATE INDEX IF NOT EXISTS idx_tasks_reminder_before_due ON public.tasks USING btree (deadline_date, reminder_minutes_before_due) WHERE (reminder_kind = 'before_due'::text);

CREATE UNIQUE INDEX IF NOT EXISTS routine_checklist_item_state_pkey ON public.routine_checklist_item_state USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS routine_checklist_items_pkey ON public.routine_checklist_items USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS task_checklist_item_state_pkey ON public.task_checklist_item_state USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS task_checklist_items_pkey ON public.task_checklist_items USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_attention_rule_runtime_state_rule_entity ON public.attention_rule_runtime_state USING btree (rule_id, entity_type, entity_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_project_completion_history_project_occurrence ON public.project_completion_history USING btree (project_id, occurrence_date);

CREATE UNIQUE INDEX IF NOT EXISTS uq_project_recurrence_exceptions_project_original ON public.project_recurrence_exceptions USING btree (project_id, original_date);

CREATE UNIQUE INDEX IF NOT EXISTS uq_task_completion_history_task_occurrence ON public.task_completion_history USING btree (task_id, occurrence_date);

CREATE UNIQUE INDEX IF NOT EXISTS uq_task_recurrence_exceptions_task_original ON public.task_recurrence_exceptions USING btree (task_id, original_date);

CREATE UNIQUE INDEX IF NOT EXISTS uq_value_ratings_weekly_user_value_week ON public.value_ratings_weekly USING btree (user_id, value_id, week_start);

CREATE UNIQUE INDEX IF NOT EXISTS ux_routine_checklist_items_id_routine ON public.routine_checklist_items USING btree (id, routine_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_routine_checklist_state_routine_item_window ON public.routine_checklist_item_state USING btree (routine_id, checklist_item_id, period_type, window_key);

CREATE UNIQUE INDEX IF NOT EXISTS ux_task_checklist_items_id_task ON public.task_checklist_items USING btree (id, task_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_task_checklist_state_task_item_occurrence ON public.task_checklist_item_state USING btree (task_id, checklist_item_id, occurrence_date) NULLS NOT DISTINCT;

CREATE UNIQUE INDEX IF NOT EXISTS routine_skips_unique ON public.routine_skips USING btree (routine_id, period_type, period_key);

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'checklist_events_pkey' and conrelid = 'public.checklist_events'::regclass) then
    alter table "public"."checklist_events" add constraint "checklist_events_pkey" PRIMARY KEY using index "checklist_events_pkey";
  end if;
end $$;


do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'routine_checklist_item_state_pkey' and conrelid = 'public.routine_checklist_item_state'::regclass) then
    alter table "public"."routine_checklist_item_state" add constraint "routine_checklist_item_state_pkey" PRIMARY KEY using index "routine_checklist_item_state_pkey";
  end if;
end $$;


do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'routine_checklist_items_pkey' and conrelid = 'public.routine_checklist_items'::regclass) then
    alter table "public"."routine_checklist_items" add constraint "routine_checklist_items_pkey" PRIMARY KEY using index "routine_checklist_items_pkey";
  end if;
end $$;


do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'task_checklist_item_state_pkey' and conrelid = 'public.task_checklist_item_state'::regclass) then
    alter table "public"."task_checklist_item_state" add constraint "task_checklist_item_state_pkey" PRIMARY KEY using index "task_checklist_item_state_pkey";
  end if;
end $$;


do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'task_checklist_items_pkey' and conrelid = 'public.task_checklist_items'::regclass) then
    alter table "public"."task_checklist_items" add constraint "task_checklist_items_pkey" PRIMARY KEY using index "task_checklist_items_pkey";
  end if;
end $$;


do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'uq_attention_rule_runtime_state_rule_entity' and conrelid = 'public.attention_rule_runtime_state'::regclass) then
    alter table "public"."attention_rule_runtime_state" add constraint "uq_attention_rule_runtime_state_rule_entity" UNIQUE using index "uq_attention_rule_runtime_state_rule_entity";
  end if;
end $$;


do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'checklist_events_event_type_check' and conrelid = 'public.checklist_events'::regclass) then
    alter table "public"."checklist_events" add constraint "checklist_events_event_type_check" CHECK ((event_type = ANY (ARRAY['checked'::text, 'unchecked'::text, 'parent_completed'::text, 'parent_logged'::text]))) not valid;
  end if;
end $$;


alter table "public"."checklist_events" validate constraint "checklist_events_event_type_check";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'checklist_events_parent_type_check' and conrelid = 'public.checklist_events'::regclass) then
    alter table "public"."checklist_events" add constraint "checklist_events_parent_type_check" CHECK ((parent_type = ANY (ARRAY['task'::text, 'routine'::text]))) not valid;
  end if;
end $$;


alter table "public"."checklist_events" validate constraint "checklist_events_parent_type_check";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'checklist_events_scope_period_type_check' and conrelid = 'public.checklist_events'::regclass) then
    alter table "public"."checklist_events" add constraint "checklist_events_scope_period_type_check" CHECK (((scope_period_type IS NULL) OR (scope_period_type = ANY (ARRAY['day'::text, 'week'::text, 'month'::text])))) not valid;
  end if;
end $$;


alter table "public"."checklist_events" validate constraint "checklist_events_scope_period_type_check";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'checklist_events_user_id_fkey' and conrelid = 'public.checklist_events'::regclass) then
    alter table "public"."checklist_events" add constraint "checklist_events_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;
  end if;
end $$;


alter table "public"."checklist_events" validate constraint "checklist_events_user_id_fkey";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'uq_project_completion_history_project_occurrence' and conrelid = 'public.project_completion_history'::regclass) then
    alter table "public"."project_completion_history" add constraint "uq_project_completion_history_project_occurrence" UNIQUE using index "uq_project_completion_history_project_occurrence";
  end if;
end $$;


do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'uq_project_recurrence_exceptions_project_original' and conrelid = 'public.project_recurrence_exceptions'::regclass) then
    alter table "public"."project_recurrence_exceptions" add constraint "uq_project_recurrence_exceptions_project_original" UNIQUE using index "uq_project_recurrence_exceptions_project_original";
  end if;
end $$;


do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'routine_checklist_item_state_checklist_item_id_fkey' and conrelid = 'public.routine_checklist_item_state'::regclass) then
    alter table "public"."routine_checklist_item_state" add constraint "routine_checklist_item_state_checklist_item_id_fkey" FOREIGN KEY (checklist_item_id) REFERENCES public.routine_checklist_items(id) ON DELETE CASCADE not valid;
  end if;
end $$;


alter table "public"."routine_checklist_item_state" validate constraint "routine_checklist_item_state_checklist_item_id_fkey";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'routine_checklist_item_state_routine_id_fkey' and conrelid = 'public.routine_checklist_item_state'::regclass) then
    alter table "public"."routine_checklist_item_state" add constraint "routine_checklist_item_state_routine_id_fkey" FOREIGN KEY (routine_id) REFERENCES public.routines(id) ON DELETE CASCADE not valid;
  end if;
end $$;


alter table "public"."routine_checklist_item_state" validate constraint "routine_checklist_item_state_routine_id_fkey";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'routine_checklist_items_routine_id_fkey' and conrelid = 'public.routine_checklist_items'::regclass) then
    alter table "public"."routine_checklist_items" add constraint "routine_checklist_items_routine_id_fkey" FOREIGN KEY (routine_id) REFERENCES public.routines(id) not valid;
  end if;
end $$;


alter table "public"."routine_checklist_items" validate constraint "routine_checklist_items_routine_id_fkey";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'routine_checklist_items_sort_index_check' and conrelid = 'public.routine_checklist_items'::regclass) then
    alter table "public"."routine_checklist_items" add constraint "routine_checklist_items_sort_index_check" CHECK ((sort_index >= 0)) not valid;
  end if;
end $$;


alter table "public"."routine_checklist_items" validate constraint "routine_checklist_items_sort_index_check";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'routine_checklist_items_title_check' and conrelid = 'public.routine_checklist_items'::regclass) then
    alter table "public"."routine_checklist_items" add constraint "routine_checklist_items_title_check" CHECK ((char_length(title) <= 200)) not valid;
  end if;
end $$;


alter table "public"."routine_checklist_items" validate constraint "routine_checklist_items_title_check";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'routine_checklist_items_user_id_fkey' and conrelid = 'public.routine_checklist_items'::regclass) then
    alter table "public"."routine_checklist_items" add constraint "routine_checklist_items_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;
  end if;
end $$;


alter table "public"."routine_checklist_items" validate constraint "routine_checklist_items_user_id_fkey";

CREATE OR REPLACE FUNCTION public.is_valid_month_days(days integer[])
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
AS $function$
  SELECT CASE
    WHEN days IS NULL OR array_length(days, 1) IS NULL THEN true
    ELSE COALESCE(bool_and(d BETWEEN 1 AND 31), true)
  END
  FROM unnest(days) AS d;
$function$
;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'routines_project_id_fkey' and conrelid = 'public.routines'::regclass) then
    alter table "public"."routines" add constraint "routines_project_id_fkey" FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE not valid;
  end if;
end $$;


alter table "public"."routines" validate constraint "routines_project_id_fkey";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'routines_schedule_month_days_check' and conrelid = 'public.routines'::regclass) then
    alter table "public"."routines" add constraint "routines_schedule_month_days_check" CHECK (public.is_valid_month_days(schedule_month_days)) not valid;
  end if;
end $$;


alter table "public"."routines" validate constraint "routines_schedule_month_days_check";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'routines_schedule_time_minutes_check' and conrelid = 'public.routines'::regclass) then
    alter table "public"."routines" add constraint "routines_schedule_time_minutes_check" CHECK (((schedule_time_minutes IS NULL) OR ((schedule_time_minutes >= 0) AND (schedule_time_minutes <= 1439)))) not valid;
  end if;
end $$;


alter table "public"."routines" validate constraint "routines_schedule_time_minutes_check";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'task_checklist_item_state_checklist_item_id_fkey' and conrelid = 'public.task_checklist_item_state'::regclass) then
    alter table "public"."task_checklist_item_state" add constraint "task_checklist_item_state_checklist_item_id_fkey" FOREIGN KEY (checklist_item_id) REFERENCES public.task_checklist_items(id) ON DELETE CASCADE not valid;
  end if;
end $$;


alter table "public"."task_checklist_item_state" validate constraint "task_checklist_item_state_checklist_item_id_fkey";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'task_checklist_item_state_task_id_fkey' and conrelid = 'public.task_checklist_item_state'::regclass) then
    alter table "public"."task_checklist_item_state" add constraint "task_checklist_item_state_task_id_fkey" FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE not valid;
  end if;
end $$;


alter table "public"."task_checklist_item_state" validate constraint "task_checklist_item_state_task_id_fkey";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'task_checklist_items_sort_index_check' and conrelid = 'public.task_checklist_items'::regclass) then
    alter table "public"."task_checklist_items" add constraint "task_checklist_items_sort_index_check" CHECK ((sort_index >= 0)) not valid;
  end if;
end $$;


alter table "public"."task_checklist_items" validate constraint "task_checklist_items_sort_index_check";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'task_checklist_items_task_id_fkey' and conrelid = 'public.task_checklist_items'::regclass) then
    alter table "public"."task_checklist_items" add constraint "task_checklist_items_task_id_fkey" FOREIGN KEY (task_id) REFERENCES public.tasks(id) not valid;
  end if;
end $$;


alter table "public"."task_checklist_items" validate constraint "task_checklist_items_task_id_fkey";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'task_checklist_items_title_check' and conrelid = 'public.task_checklist_items'::regclass) then
    alter table "public"."task_checklist_items" add constraint "task_checklist_items_title_check" CHECK ((char_length(title) <= 200)) not valid;
  end if;
end $$;


alter table "public"."task_checklist_items" validate constraint "task_checklist_items_title_check";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'task_checklist_items_user_id_fkey' and conrelid = 'public.task_checklist_items'::regclass) then
    alter table "public"."task_checklist_items" add constraint "task_checklist_items_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;
  end if;
end $$;


alter table "public"."task_checklist_items" validate constraint "task_checklist_items_user_id_fkey";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'uq_task_completion_history_task_occurrence' and conrelid = 'public.task_completion_history'::regclass) then
    alter table "public"."task_completion_history" add constraint "uq_task_completion_history_task_occurrence" UNIQUE using index "uq_task_completion_history_task_occurrence";
  end if;
end $$;


do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'uq_task_recurrence_exceptions_task_original' and conrelid = 'public.task_recurrence_exceptions'::regclass) then
    alter table "public"."task_recurrence_exceptions" add constraint "uq_task_recurrence_exceptions_task_original" UNIQUE using index "uq_task_recurrence_exceptions_task_original";
  end if;
end $$;


do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'tasks_reminder_kind_check' and conrelid = 'public.tasks'::regclass) then
    alter table "public"."tasks" add constraint "tasks_reminder_kind_check" CHECK ((reminder_kind = ANY (ARRAY['none'::text, 'absolute'::text, 'before_due'::text]))) not valid;
  end if;
end $$;


alter table "public"."tasks" validate constraint "tasks_reminder_kind_check";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'tasks_reminder_shape_check' and conrelid = 'public.tasks'::regclass) then
    alter table "public"."tasks" add constraint "tasks_reminder_shape_check" CHECK ((((reminder_kind = 'none'::text) AND (reminder_at_utc IS NULL) AND (reminder_minutes_before_due IS NULL)) OR ((reminder_kind = 'absolute'::text) AND (reminder_at_utc IS NOT NULL) AND (reminder_minutes_before_due IS NULL)) OR ((reminder_kind = 'before_due'::text) AND (reminder_at_utc IS NULL) AND ((reminder_minutes_before_due >= 0) AND (reminder_minutes_before_due <= 10080))))) not valid;
  end if;
end $$;


alter table "public"."tasks" validate constraint "tasks_reminder_shape_check";

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'uq_value_ratings_weekly_user_value_week' and conrelid = 'public.value_ratings_weekly'::regclass) then
    alter table "public"."value_ratings_weekly" add constraint "uq_value_ratings_weekly_user_value_week" UNIQUE using index "uq_value_ratings_weekly_user_value_week";
  end if;
end $$;


set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.is_valid_month_days(days integer[])
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
AS $function$
  SELECT CASE
    WHEN days IS NULL OR array_length(days, 1) IS NULL THEN true
    ELSE COALESCE(bool_and(d BETWEEN 1 AND 31), true)
  END
  FROM unnest(days) AS d;
$function$
;

grant delete on table "public"."checklist_events" to "anon";

grant insert on table "public"."checklist_events" to "anon";

grant references on table "public"."checklist_events" to "anon";

grant select on table "public"."checklist_events" to "anon";

grant trigger on table "public"."checklist_events" to "anon";

grant truncate on table "public"."checklist_events" to "anon";

grant update on table "public"."checklist_events" to "anon";

grant delete on table "public"."checklist_events" to "authenticated";

grant insert on table "public"."checklist_events" to "authenticated";

grant references on table "public"."checklist_events" to "authenticated";

grant select on table "public"."checklist_events" to "authenticated";

grant trigger on table "public"."checklist_events" to "authenticated";

grant truncate on table "public"."checklist_events" to "authenticated";

grant update on table "public"."checklist_events" to "authenticated";

grant select on table "public"."checklist_events" to "powersync_role";

grant delete on table "public"."checklist_events" to "service_role";

grant insert on table "public"."checklist_events" to "service_role";

grant references on table "public"."checklist_events" to "service_role";

grant select on table "public"."checklist_events" to "service_role";

grant trigger on table "public"."checklist_events" to "service_role";

grant truncate on table "public"."checklist_events" to "service_role";

grant update on table "public"."checklist_events" to "service_role";

grant delete on table "public"."routine_checklist_item_state" to "anon";

grant insert on table "public"."routine_checklist_item_state" to "anon";

grant references on table "public"."routine_checklist_item_state" to "anon";

grant select on table "public"."routine_checklist_item_state" to "anon";

grant trigger on table "public"."routine_checklist_item_state" to "anon";

grant truncate on table "public"."routine_checklist_item_state" to "anon";

grant update on table "public"."routine_checklist_item_state" to "anon";

grant delete on table "public"."routine_checklist_item_state" to "authenticated";

grant insert on table "public"."routine_checklist_item_state" to "authenticated";

grant references on table "public"."routine_checklist_item_state" to "authenticated";

grant select on table "public"."routine_checklist_item_state" to "authenticated";

grant trigger on table "public"."routine_checklist_item_state" to "authenticated";

grant truncate on table "public"."routine_checklist_item_state" to "authenticated";

grant update on table "public"."routine_checklist_item_state" to "authenticated";

grant select on table "public"."routine_checklist_item_state" to "powersync_role";

grant delete on table "public"."routine_checklist_item_state" to "service_role";

grant insert on table "public"."routine_checklist_item_state" to "service_role";

grant references on table "public"."routine_checklist_item_state" to "service_role";

grant select on table "public"."routine_checklist_item_state" to "service_role";

grant trigger on table "public"."routine_checklist_item_state" to "service_role";

grant truncate on table "public"."routine_checklist_item_state" to "service_role";

grant update on table "public"."routine_checklist_item_state" to "service_role";

grant delete on table "public"."routine_checklist_items" to "anon";

grant insert on table "public"."routine_checklist_items" to "anon";

grant references on table "public"."routine_checklist_items" to "anon";

grant select on table "public"."routine_checklist_items" to "anon";

grant trigger on table "public"."routine_checklist_items" to "anon";

grant truncate on table "public"."routine_checklist_items" to "anon";

grant update on table "public"."routine_checklist_items" to "anon";

grant delete on table "public"."routine_checklist_items" to "authenticated";

grant insert on table "public"."routine_checklist_items" to "authenticated";

grant references on table "public"."routine_checklist_items" to "authenticated";

grant select on table "public"."routine_checklist_items" to "authenticated";

grant trigger on table "public"."routine_checklist_items" to "authenticated";

grant truncate on table "public"."routine_checklist_items" to "authenticated";

grant update on table "public"."routine_checklist_items" to "authenticated";

grant select on table "public"."routine_checklist_items" to "powersync_role";

grant delete on table "public"."routine_checklist_items" to "service_role";

grant insert on table "public"."routine_checklist_items" to "service_role";

grant references on table "public"."routine_checklist_items" to "service_role";

grant select on table "public"."routine_checklist_items" to "service_role";

grant trigger on table "public"."routine_checklist_items" to "service_role";

grant truncate on table "public"."routine_checklist_items" to "service_role";

grant update on table "public"."routine_checklist_items" to "service_role";

grant delete on table "public"."task_checklist_item_state" to "anon";

grant insert on table "public"."task_checklist_item_state" to "anon";

grant references on table "public"."task_checklist_item_state" to "anon";

grant select on table "public"."task_checklist_item_state" to "anon";

grant trigger on table "public"."task_checklist_item_state" to "anon";

grant truncate on table "public"."task_checklist_item_state" to "anon";

grant update on table "public"."task_checklist_item_state" to "anon";

grant delete on table "public"."task_checklist_item_state" to "authenticated";

grant insert on table "public"."task_checklist_item_state" to "authenticated";

grant references on table "public"."task_checklist_item_state" to "authenticated";

grant select on table "public"."task_checklist_item_state" to "authenticated";

grant trigger on table "public"."task_checklist_item_state" to "authenticated";

grant truncate on table "public"."task_checklist_item_state" to "authenticated";

grant update on table "public"."task_checklist_item_state" to "authenticated";

grant select on table "public"."task_checklist_item_state" to "powersync_role";

grant delete on table "public"."task_checklist_item_state" to "service_role";

grant insert on table "public"."task_checklist_item_state" to "service_role";

grant references on table "public"."task_checklist_item_state" to "service_role";

grant select on table "public"."task_checklist_item_state" to "service_role";

grant trigger on table "public"."task_checklist_item_state" to "service_role";

grant truncate on table "public"."task_checklist_item_state" to "service_role";

grant update on table "public"."task_checklist_item_state" to "service_role";

grant delete on table "public"."task_checklist_items" to "anon";

grant insert on table "public"."task_checklist_items" to "anon";

grant references on table "public"."task_checklist_items" to "anon";

grant select on table "public"."task_checklist_items" to "anon";

grant trigger on table "public"."task_checklist_items" to "anon";

grant truncate on table "public"."task_checklist_items" to "anon";

grant update on table "public"."task_checklist_items" to "anon";

grant delete on table "public"."task_checklist_items" to "authenticated";

grant insert on table "public"."task_checklist_items" to "authenticated";

grant references on table "public"."task_checklist_items" to "authenticated";

grant select on table "public"."task_checklist_items" to "authenticated";

grant trigger on table "public"."task_checklist_items" to "authenticated";

grant truncate on table "public"."task_checklist_items" to "authenticated";

grant update on table "public"."task_checklist_items" to "authenticated";

grant select on table "public"."task_checklist_items" to "powersync_role";

grant delete on table "public"."task_checklist_items" to "service_role";

grant insert on table "public"."task_checklist_items" to "service_role";

grant references on table "public"."task_checklist_items" to "service_role";

grant select on table "public"."task_checklist_items" to "service_role";

grant trigger on table "public"."task_checklist_items" to "service_role";

grant truncate on table "public"."task_checklist_items" to "service_role";

grant update on table "public"."task_checklist_items" to "service_role";


-- Idempotent policy recreation.
drop policy if exists "checklist_events_delete" on "public"."checklist_events";
drop policy if exists "checklist_events_insert" on "public"."checklist_events";
drop policy if exists "checklist_events_select" on "public"."checklist_events";
drop policy if exists "routine_checklist_item_state_delete" on "public"."routine_checklist_item_state";
drop policy if exists "routine_checklist_item_state_insert" on "public"."routine_checklist_item_state";
drop policy if exists "routine_checklist_item_state_select" on "public"."routine_checklist_item_state";
drop policy if exists "routine_checklist_item_state_update" on "public"."routine_checklist_item_state";
drop policy if exists "routine_checklist_items_delete" on "public"."routine_checklist_items";
drop policy if exists "routine_checklist_items_insert" on "public"."routine_checklist_items";
drop policy if exists "routine_checklist_items_select" on "public"."routine_checklist_items";
drop policy if exists "routine_checklist_items_update" on "public"."routine_checklist_items";
drop policy if exists "routines_delete_own" on "public"."routines";
drop policy if exists "routines_insert_own" on "public"."routines";
drop policy if exists "routines_select_own" on "public"."routines";
drop policy if exists "routines_update_own" on "public"."routines";
drop policy if exists "task_checklist_item_state_delete" on "public"."task_checklist_item_state";
drop policy if exists "task_checklist_item_state_insert" on "public"."task_checklist_item_state";
drop policy if exists "task_checklist_item_state_select" on "public"."task_checklist_item_state";
drop policy if exists "task_checklist_item_state_update" on "public"."task_checklist_item_state";
drop policy if exists "task_checklist_items_delete" on "public"."task_checklist_items";
drop policy if exists "task_checklist_items_insert" on "public"."task_checklist_items";
drop policy if exists "task_checklist_items_select" on "public"."task_checklist_items";
drop policy if exists "task_checklist_items_update" on "public"."task_checklist_items";

  create policy "checklist_events_delete"
  on "public"."checklist_events"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "checklist_events_insert"
  on "public"."checklist_events"
  as permissive
  for insert
  to public
with check (((auth.uid() = user_id) AND (((parent_type = 'task'::text) AND (EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = checklist_events.parent_id) AND (t.user_id = auth.uid()))))) OR ((parent_type = 'routine'::text) AND (EXISTS ( SELECT 1
   FROM public.routines r
  WHERE ((r.id = checklist_events.parent_id) AND (r.user_id = auth.uid()))))))));



  create policy "checklist_events_select"
  on "public"."checklist_events"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "routine_checklist_item_state_delete"
  on "public"."routine_checklist_item_state"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "routine_checklist_item_state_insert"
  on "public"."routine_checklist_item_state"
  as permissive
  for insert
  to public
with check (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM public.routines r
  WHERE ((r.id = routine_checklist_item_state.routine_id) AND (r.user_id = auth.uid())))) AND (EXISTS ( SELECT 1
   FROM public.routine_checklist_items i
  WHERE ((i.id = routine_checklist_item_state.checklist_item_id) AND (i.routine_id = routine_checklist_item_state.routine_id) AND (i.user_id = auth.uid()))))));



  create policy "routine_checklist_item_state_select"
  on "public"."routine_checklist_item_state"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "routine_checklist_item_state_update"
  on "public"."routine_checklist_item_state"
  as permissive
  for update
  to public
using ((auth.uid() = user_id))
with check (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM public.routines r
  WHERE ((r.id = routine_checklist_item_state.routine_id) AND (r.user_id = auth.uid())))) AND (EXISTS ( SELECT 1
   FROM public.routine_checklist_items i
  WHERE ((i.id = routine_checklist_item_state.checklist_item_id) AND (i.routine_id = routine_checklist_item_state.routine_id) AND (i.user_id = auth.uid()))))));



  create policy "routine_checklist_items_delete"
  on "public"."routine_checklist_items"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "routine_checklist_items_insert"
  on "public"."routine_checklist_items"
  as permissive
  for insert
  to public
with check (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM public.routines r
  WHERE ((r.id = routine_checklist_items.routine_id) AND (r.user_id = auth.uid()))))));



  create policy "routine_checklist_items_select"
  on "public"."routine_checklist_items"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "routine_checklist_items_update"
  on "public"."routine_checklist_items"
  as permissive
  for update
  to public
using ((auth.uid() = user_id))
with check (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM public.routines r
  WHERE ((r.id = routine_checklist_items.routine_id) AND (r.user_id = auth.uid()))))));



  create policy "routines_delete_own"
  on "public"."routines"
  as permissive
  for delete
  to authenticated
using ((user_id = auth.uid()));



  create policy "routines_insert_own"
  on "public"."routines"
  as permissive
  for insert
  to authenticated
with check ((user_id = auth.uid()));



  create policy "routines_select_own"
  on "public"."routines"
  as permissive
  for select
  to authenticated
using ((user_id = auth.uid()));



  create policy "routines_update_own"
  on "public"."routines"
  as permissive
  for update
  to authenticated
using ((user_id = auth.uid()))
with check ((user_id = auth.uid()));



  create policy "task_checklist_item_state_delete"
  on "public"."task_checklist_item_state"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "task_checklist_item_state_insert"
  on "public"."task_checklist_item_state"
  as permissive
  for insert
  to public
with check (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = task_checklist_item_state.task_id) AND (t.user_id = auth.uid())))) AND (EXISTS ( SELECT 1
   FROM public.task_checklist_items i
  WHERE ((i.id = task_checklist_item_state.checklist_item_id) AND (i.task_id = task_checklist_item_state.task_id) AND (i.user_id = auth.uid()))))));



  create policy "task_checklist_item_state_select"
  on "public"."task_checklist_item_state"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "task_checklist_item_state_update"
  on "public"."task_checklist_item_state"
  as permissive
  for update
  to public
using ((auth.uid() = user_id))
with check (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = task_checklist_item_state.task_id) AND (t.user_id = auth.uid())))) AND (EXISTS ( SELECT 1
   FROM public.task_checklist_items i
  WHERE ((i.id = task_checklist_item_state.checklist_item_id) AND (i.task_id = task_checklist_item_state.task_id) AND (i.user_id = auth.uid()))))));



  create policy "task_checklist_items_delete"
  on "public"."task_checklist_items"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "task_checklist_items_insert"
  on "public"."task_checklist_items"
  as permissive
  for insert
  to public
with check (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = task_checklist_items.task_id) AND (t.user_id = auth.uid()))))));



  create policy "task_checklist_items_select"
  on "public"."task_checklist_items"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "task_checklist_items_update"
  on "public"."task_checklist_items"
  as permissive
  for update
  to public
using ((auth.uid() = user_id))
with check (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = task_checklist_items.task_id) AND (t.user_id = auth.uid()))))));

drop trigger if exists set_routine_checklist_item_state_updated_at on public.routine_checklist_item_state;
drop trigger if exists set_routine_checklist_items_updated_at on public.routine_checklist_items;
drop trigger if exists set_task_checklist_item_state_updated_at on public.task_checklist_item_state;
drop trigger if exists set_task_checklist_items_updated_at on public.task_checklist_items;

CREATE TRIGGER set_routine_checklist_item_state_updated_at BEFORE UPDATE ON public.routine_checklist_item_state FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_routine_checklist_items_updated_at BEFORE UPDATE ON public.routine_checklist_items FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_task_checklist_item_state_updated_at BEFORE UPDATE ON public.task_checklist_item_state FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_task_checklist_items_updated_at BEFORE UPDATE ON public.task_checklist_items FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


