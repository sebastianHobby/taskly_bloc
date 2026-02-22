begin;

create extension if not exists pgcrypto;

create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.sync_issues (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,

  status text not null default 'open'
    check (status in ('open', 'resolved', 'ignored')),
  severity text not null default 'error'
    check (severity in ('info', 'warning', 'error', 'critical')),
  category text not null
    check (category in ('validation', 'conflict', 'auth', 'schema', 'transport', 'pipeline')),

  fingerprint text not null,
  issue_code text not null,

  title text not null,
  message text not null,

  correlation_id uuid,
  sync_session_id text,
  client_id text,
  operation text,
  entity_type text,
  entity_id text,
  remote_code text,
  remote_message text,
  details jsonb not null default '{}'::jsonb,

  first_seen_at timestamptz not null default timezone('utc', now()),
  last_seen_at timestamptz not null default timezone('utc', now()),
  occurrence_count integer not null default 1 check (occurrence_count >= 1),

  resolved_at timestamptz,

  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),

  unique (user_id, fingerprint)
);

drop trigger if exists trg_sync_issues_updated_at on public.sync_issues;
create trigger trg_sync_issues_updated_at
before update on public.sync_issues
for each row execute function public.tg_set_updated_at();

create index if not exists idx_sync_issues_user_status_seen
  on public.sync_issues (user_id, status, last_seen_at desc);

create index if not exists idx_sync_issues_user_created
  on public.sync_issues (user_id, created_at desc);

create index if not exists idx_sync_issues_correlation
  on public.sync_issues (correlation_id);

alter table public.sync_issues enable row level security;

drop policy if exists "sync_issues_select_own" on public.sync_issues;
create policy "sync_issues_select_own"
on public.sync_issues
for select
to authenticated
using (auth.uid() = user_id);

commit;