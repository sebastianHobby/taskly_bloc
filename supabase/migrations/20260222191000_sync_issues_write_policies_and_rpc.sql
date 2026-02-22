begin;

drop policy if exists "sync_issues_insert_own" on public.sync_issues;
create policy "sync_issues_insert_own"
on public.sync_issues
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "sync_issues_update_own" on public.sync_issues;
create policy "sync_issues_update_own"
on public.sync_issues
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create or replace function public.record_sync_issue(
  p_status text,
  p_severity text,
  p_category text,
  p_fingerprint text,
  p_issue_code text,
  p_title text,
  p_message text,
  p_correlation_id uuid default null,
  p_sync_session_id text default null,
  p_client_id text default null,
  p_operation text default null,
  p_entity_type text default null,
  p_entity_id text default null,
  p_remote_code text default null,
  p_remote_message text default null,
  p_details jsonb default '{}'::jsonb,
  p_seen_at timestamptz default timezone('utc', now())
) returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_issue_id uuid;
begin
  if v_user_id is null then
    raise exception 'record_sync_issue requires authenticated user'
      using errcode = '42501';
  end if;

  insert into public.sync_issues (
    user_id,
    status,
    severity,
    category,
    fingerprint,
    issue_code,
    title,
    message,
    correlation_id,
    sync_session_id,
    client_id,
    operation,
    entity_type,
    entity_id,
    remote_code,
    remote_message,
    details,
    first_seen_at,
    last_seen_at,
    occurrence_count,
    resolved_at
  ) values (
    v_user_id,
    p_status,
    p_severity,
    p_category,
    p_fingerprint,
    p_issue_code,
    p_title,
    p_message,
    p_correlation_id,
    p_sync_session_id,
    p_client_id,
    p_operation,
    p_entity_type,
    p_entity_id,
    p_remote_code,
    p_remote_message,
    coalesce(p_details, '{}'::jsonb),
    p_seen_at,
    p_seen_at,
    1,
    null
  )
  on conflict (user_id, fingerprint)
  do update set
    status = excluded.status,
    severity = excluded.severity,
    category = excluded.category,
    issue_code = excluded.issue_code,
    title = excluded.title,
    message = excluded.message,
    correlation_id = excluded.correlation_id,
    sync_session_id = excluded.sync_session_id,
    client_id = excluded.client_id,
    operation = excluded.operation,
    entity_type = excluded.entity_type,
    entity_id = excluded.entity_id,
    remote_code = excluded.remote_code,
    remote_message = excluded.remote_message,
    details = excluded.details,
    last_seen_at = excluded.last_seen_at,
    occurrence_count = public.sync_issues.occurrence_count + 1,
    resolved_at = null
  returning id into v_issue_id;

  return v_issue_id;
end;
$$;

grant execute on function public.record_sync_issue(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  jsonb,
  timestamptz
) to authenticated;

commit;
