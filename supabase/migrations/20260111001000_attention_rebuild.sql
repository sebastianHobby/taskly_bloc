-- Attention tables rebuild (Option 3) + runtime state
--
-- Notes:
-- - Creates missing enums if they don't exist (safe for local/dev).
-- - Rebuilds only attention-related tables.
-- - All tables have: id UUID PK, user_id UUID default auth.uid().

begin;

create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- Enum types (create-if-missing)
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'entity_source') THEN
    CREATE TYPE public.entity_source AS ENUM ('system_template', 'user_created', 'imported');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'attention_severity') THEN
    CREATE TYPE public.attention_severity AS ENUM ('info', 'warning', 'critical');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'attention_rule_type') THEN
    CREATE TYPE public.attention_rule_type AS ENUM ('problem', 'review', 'workflowStep', 'allocationWarning');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'attention_trigger_type') THEN
    CREATE TYPE public.attention_trigger_type AS ENUM ('realtime', 'scheduled');
  END IF;
END
$$;

-- -----------------------------------------------------------------------------
-- Helper for updated_at
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Drop existing attention tables
-- -----------------------------------------------------------------------------
drop table if exists public.attention_rule_runtime_state cascade;
drop table if exists public.attention_resolutions cascade;
drop table if exists public.attention_condition_states cascade;
drop table if exists public.attention_rules cascade;

-- -----------------------------------------------------------------------------
-- attention_rules
-- -----------------------------------------------------------------------------
create table public.attention_rules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  rule_key text not null,

  -- Stable grouping axes
  domain text not null,
  category text not null,

  trigger_config jsonb not null default '{}'::jsonb,
  entity_selector jsonb not null default '{}'::jsonb,
  display_config jsonb not null default '{}'::jsonb,

  resolution_actions text[] not null default array['reviewed','skipped']::text[],
  active boolean not null default true,

  source public.entity_source not null default 'user_created'::public.entity_source,
  rule_type public.attention_rule_type not null,
  trigger_type public.attention_trigger_type not null,
  severity public.attention_severity not null default 'info'::public.attention_severity,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint attention_rules_user_id_fkey foreign key (user_id) references auth.users(id),
  constraint attention_rules_user_rule_key_uk unique (user_id, rule_key)
);

create index attention_rules_user_id_idx on public.attention_rules(user_id);
create index attention_rules_domain_category_idx on public.attention_rules(user_id, domain, category);

create trigger trg_attention_rules_set_updated_at
before update on public.attention_rules
for each row execute function public.set_updated_at();

alter table public.attention_rules enable row level security;

drop policy if exists attention_rules_select_own on public.attention_rules;
create policy attention_rules_select_own on public.attention_rules
for select to authenticated
using (user_id = auth.uid());

drop policy if exists attention_rules_insert_own on public.attention_rules;
create policy attention_rules_insert_own on public.attention_rules
for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists attention_rules_update_own on public.attention_rules;
create policy attention_rules_update_own on public.attention_rules
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists attention_rules_delete_own on public.attention_rules;
create policy attention_rules_delete_own on public.attention_rules
for delete to authenticated
using (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- attention_resolutions
-- -----------------------------------------------------------------------------
create table public.attention_resolutions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  rule_id uuid not null,
  entity_id text not null,
  entity_type text not null,
  resolved_at timestamptz not null default now(),
  resolution_action text not null,
  action_details jsonb,
  created_at timestamptz not null default now(),

  constraint attention_resolutions_user_id_fkey foreign key (user_id) references auth.users(id),
  constraint attention_resolutions_rule_id_fkey foreign key (rule_id) references public.attention_rules(id) on delete cascade
);

create index attention_resolutions_user_rule_idx on public.attention_resolutions(user_id, rule_id);

alter table public.attention_resolutions enable row level security;

drop policy if exists attention_resolutions_select_own on public.attention_resolutions;
create policy attention_resolutions_select_own on public.attention_resolutions
for select to authenticated
using (user_id = auth.uid());

drop policy if exists attention_resolutions_insert_own on public.attention_resolutions;
create policy attention_resolutions_insert_own on public.attention_resolutions
for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists attention_resolutions_delete_own on public.attention_resolutions;
create policy attention_resolutions_delete_own on public.attention_resolutions
for delete to authenticated
using (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- attention_rule_runtime_state
-- -----------------------------------------------------------------------------
create table public.attention_rule_runtime_state (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  rule_id uuid not null,

  entity_type text,
  entity_id text,

  state_hash text,
  dismissed_state_hash text,
  last_evaluated_at timestamptz,
  next_evaluate_after timestamptz,
  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint attention_rule_runtime_state_user_id_fkey foreign key (user_id) references auth.users(id),
  constraint attention_rule_runtime_state_rule_id_fkey foreign key (rule_id) references public.attention_rules(id) on delete cascade,
  constraint attention_rule_runtime_state_entity_pair_chk check (
    (entity_type is null and entity_id is null) or (entity_type is not null and entity_id is not null)
  )
);

create index attention_rule_runtime_state_user_rule_idx
  on public.attention_rule_runtime_state(user_id, rule_id);

create trigger trg_attention_rule_runtime_state_set_updated_at
before update on public.attention_rule_runtime_state
for each row execute function public.set_updated_at();

alter table public.attention_rule_runtime_state enable row level security;

drop policy if exists attention_rule_runtime_state_select_own on public.attention_rule_runtime_state;
create policy attention_rule_runtime_state_select_own on public.attention_rule_runtime_state
for select to authenticated
using (user_id = auth.uid());

drop policy if exists attention_rule_runtime_state_insert_own on public.attention_rule_runtime_state;
create policy attention_rule_runtime_state_insert_own on public.attention_rule_runtime_state
for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists attention_rule_runtime_state_update_own on public.attention_rule_runtime_state;
create policy attention_rule_runtime_state_update_own on public.attention_rule_runtime_state
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists attention_rule_runtime_state_delete_own on public.attention_rule_runtime_state;
create policy attention_rule_runtime_state_delete_own on public.attention_rule_runtime_state
for delete to authenticated
using (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- attention_condition_states (kept for compatibility with existing sync rules)
-- -----------------------------------------------------------------------------
create table public.attention_condition_states (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),

  entity_type text not null,
  entity_id uuid not null,
  condition_key text not null,

  first_detected_at timestamptz not null default now(),
  last_detected_at timestamptz not null default now(),
  last_cleared_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint attention_condition_states_user_id_fkey foreign key (user_id) references auth.users(id)
);

create index attention_condition_states_user_entity_idx
  on public.attention_condition_states(user_id, entity_type, entity_id);

create trigger trg_attention_condition_states_set_updated_at
before update on public.attention_condition_states
for each row execute function public.set_updated_at();

alter table public.attention_condition_states enable row level security;

drop policy if exists attention_condition_states_select_own on public.attention_condition_states;
create policy attention_condition_states_select_own on public.attention_condition_states
for select to authenticated
using (user_id = auth.uid());

drop policy if exists attention_condition_states_insert_own on public.attention_condition_states;
create policy attention_condition_states_insert_own on public.attention_condition_states
for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists attention_condition_states_update_own on public.attention_condition_states;
create policy attention_condition_states_update_own on public.attention_condition_states
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists attention_condition_states_delete_own on public.attention_condition_states;
create policy attention_condition_states_delete_own on public.attention_condition_states
for delete to authenticated
using (user_id = auth.uid());

commit;
