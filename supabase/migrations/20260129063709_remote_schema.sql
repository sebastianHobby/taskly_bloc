SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = 'powersync_role'
    ) THEN
        CREATE ROLE powersync_role;
    END IF;
END
$$;
CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";
COMMENT ON SCHEMA "public" IS 'standard public schema';
CREATE EXTENSION IF NOT EXISTS "hypopg" WITH SCHEMA "public";
CREATE EXTENSION IF NOT EXISTS "index_advisor" WITH SCHEMA "public";
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";
CREATE TYPE "public"."attention_rule_type" AS ENUM (
    'problem',
    'review',
    'workflowStep',
    'allocationWarning'
);
ALTER TYPE "public"."attention_rule_type" OWNER TO "postgres";
CREATE TYPE "public"."attention_severity" AS ENUM (
    'critical',
    'warning',
    'info'
);
ALTER TYPE "public"."attention_severity" OWNER TO "postgres";
CREATE TYPE "public"."attention_trigger_type" AS ENUM (
    'realtime',
    'scheduled'
);
ALTER TYPE "public"."attention_trigger_type" OWNER TO "postgres";
CREATE TYPE "public"."entity_source" AS ENUM (
    'system_template',
    'user_created',
    'imported'
);
ALTER TYPE "public"."entity_source" OWNER TO "postgres";
CREATE TYPE "public"."label_types" AS ENUM (
    'value',
    'label'
);
ALTER TYPE "public"."label_types" OWNER TO "postgres";
CREATE TYPE "public"."my_day_bucket_types" AS ENUM (
    'planned',
    'due',
    'value',
    'routine'
);
ALTER TYPE "public"."my_day_bucket_types" OWNER TO "postgres";
CREATE TYPE "public"."my_day_pick_bucket" AS ENUM (
    'values',
    'routine',
    'due',
    'starts',
    'manual'
);
ALTER TYPE "public"."my_day_pick_bucket" OWNER TO "postgres";
CREATE TYPE "public"."repeat_type" AS ENUM (
    'fromLastCompleted',
    'fromStartDate'
);
ALTER TYPE "public"."repeat_type" OWNER TO "postgres";
CREATE TYPE "public"."screen_category" AS ENUM (
    'workspace',
    'wellbeing',
    'settings'
);
ALTER TYPE "public"."screen_category" OWNER TO "postgres";
COMMENT ON TYPE "public"."screen_category" IS 'Screen categories for organizing navigation: workspace, wellbeing, settings';
CREATE TYPE "public"."value_priority" AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);
ALTER TYPE "public"."value_priority" OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."_is_privileged_delete"() RETURNS boolean
    LANGUAGE "sql" STABLE
    AS $$
  SELECT
    coalesce(auth.role(), '') IN ('service_role')
    OR current_user IN ('postgres', 'supabase_admin');
$$;
ALTER FUNCTION "public"."_is_privileged_delete"() OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."_legacy_values_read_only"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  raise exception
    'Legacy table is read-only. Use slot columns (projects.primary_value_id / secondary_value_id, tasks.override_primary_value_id / override_secondary_value_id).';
end;
$$;
ALTER FUNCTION "public"."_legacy_values_read_only"() OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."_set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;
ALTER FUNCTION "public"."_set_updated_at"() OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."cleanup_old_analytics_insights"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM analytics_insights
    WHERE generated_at < CURRENT_DATE - INTERVAL '90 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;
ALTER FUNCTION "public"."cleanup_old_analytics_insights"() OWNER TO "postgres";
COMMENT ON FUNCTION "public"."cleanup_old_analytics_insights"() IS 'Delete insights older than 90 days, returns count deleted';
CREATE OR REPLACE FUNCTION "public"."create_default_attention_rules"("p_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Problem Detection Rules (realtime)
  INSERT INTO public.attention_rules (rule_key, user_id, rule_type, trigger_type, trigger_config, entity_selector, severity, display_config, resolution_actions)
  VALUES
    -- Task Overdue
    ('task_overdue', p_user_id, 'problem', 'realtime', 
     '{"grace_period_days": 0}'::jsonb,
     '{"entity_type": "task", "conditions": {"deadline_before": "now", "completed": false}}'::jsonb,
     'critical',
     '{"title": "Overdue Task", "description": "Task is past its deadline", "icon": "warning"}'::jsonb,
     ARRAY['reviewed', 'skipped', 'snoozed']),
    
    -- Task Stale
    ('task_stale', p_user_id, 'problem', 'realtime',
     '{"threshold_days": 30, "grace_period_days": 7}'::jsonb,
     '{"entity_type": "task", "conditions": {"updated_before_days": 30, "completed": false}}'::jsonb,
     'warning',
     '{"title": "Stale Task", "description": "Task hasn''t been updated recently", "icon": "schedule"}'::jsonb,
     ARRAY['reviewed', 'skipped', 'dismissed']),
    
    -- Project Stale
    ('project_stale', p_user_id, 'problem', 'realtime',
     '{"threshold_days": 30, "grace_period_days": 7}'::jsonb,
     '{"entity_type": "project", "conditions": {"updated_before_days": 30, "completed": false}}'::jsonb,
     'warning',
     '{"title": "Stale Project", "description": "Project hasn''t been updated recently", "icon": "folder_open"}'::jsonb,
     ARRAY['reviewed', 'skipped', 'dismissed']),
    
    -- Task Orphan (no value assigned)
    ('task_orphan', p_user_id, 'problem', 'realtime',
     '{"grace_period_days": 3}'::jsonb,
     '{"entity_type": "task", "conditions": {"no_value_assigned": true, "completed": false}}'::jsonb,
     'info',
     '{"title": "Orphan Task", "description": "Task has no value assigned", "icon": "label_off"}'::jsonb,
     ARRAY['reviewed', 'skipped']),
    
    -- Urgent Excluded from Allocation
    ('urgent_excluded', p_user_id, 'allocation_warning', 'realtime',
     '{"urgent_deadline_days": 3, "grace_period_days": 0}'::jsonb,
     '{"entity_type": "task", "conditions": {"deadline_within_days": 3, "priority": "high", "excluded_from_allocation": true}}'::jsonb,
     'critical',
     '{"title": "Urgent Task Excluded", "description": "Urgent task is outside your current focus", "icon": "error"}'::jsonb,
     ARRAY['reviewed'])
  ON CONFLICT (rule_key, user_id) DO NOTHING;
  
  -- Review Rules (scheduled)
  INSERT INTO public.attention_rules (rule_key, user_id, rule_type, trigger_type, trigger_config, entity_selector, severity, display_config, resolution_actions)
  VALUES
    -- Values Alignment Review
    ('values_alignment_check', p_user_id, 'review', 'scheduled',
     '{"frequency_days": 14, "grace_period_days": 7}'::jsonb,
     '{"entity_type": "task", "conditions": {"has_value": true}}'::jsonb,
     'info',
     '{"title": "Values Alignment", "description": "Review if tasks align with your values", "icon": "balance"}'::jsonb,
     ARRAY['reviewed', 'skipped']),
    
    -- Progress Review
    ('progress_review', p_user_id, 'review', 'scheduled',
     '{"frequency_days": 7, "grace_period_days": 3}'::jsonb,
     '{"entity_type": "task", "conditions": {"completed_within_days": 7}}'::jsonb,
     'info',
     '{"title": "Progress Review", "description": "Review completed tasks and achievements", "icon": "trending_up"}'::jsonb,
     ARRAY['reviewed', 'skipped']),
    
    -- Wellbeing Insights
    ('wellbeing_insights', p_user_id, 'review', 'scheduled',
     '{"frequency_days": 7, "grace_period_days": 3}'::jsonb,
     '{"entity_type": "journal", "conditions": {}}'::jsonb,
     'info',
     '{"title": "Wellbeing Check", "description": "Review your energy and mood patterns", "icon": "favorite"}'::jsonb,
     ARRAY['reviewed', 'skipped']),
    
    -- Balance Check
    ('balance_check', p_user_id, 'review', 'scheduled',
     '{"frequency_days": 14, "grace_period_days": 7}'::jsonb,
     '{"entity_type": "value", "conditions": {}}'::jsonb,
     'info',
     '{"title": "Balance Review", "description": "Assess value distribution and neglect", "icon": "pie_chart"}'::jsonb,
     ARRAY['reviewed', 'skipped']),
    
    -- Pinned Tasks Check
    ('pinned_tasks_check', p_user_id, 'review', 'scheduled',
     '{"frequency_days": 7, "grace_period_days": 3}'::jsonb,
     '{"entity_type": "task", "conditions": {"pinned": true}}'::jsonb,
     'info',
     '{"title": "Pinned Tasks", "description": "Review and update pinned tasks", "icon": "push_pin"}'::jsonb,
     ARRAY['reviewed', 'skipped'])
  ON CONFLICT (rule_key, user_id) DO NOTHING;

END;
$$;
ALTER FUNCTION "public"."create_default_attention_rules"("p_user_id" "uuid") OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."enqueue_due_screen_notifications"("max_rows" integer DEFAULT 5000) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  inserted_count integer := 0;
begin
  with due as (
    select
      sd.user_id,
      sd.id as screen_definition_id,
      sd.next_trigger_at as scheduled_for,
      jsonb_build_object(
        'screen_id', sd.screen_id,
        'name', sd.name
      ) as payload
    from public.screen_definitions sd
    where sd.user_id is not null
      and sd.is_active = true
      and sd.trigger_type = 'schedule'
      and sd.next_trigger_at is not null
      and sd.next_trigger_at <= now()
    order by sd.next_trigger_at asc
    limit max_rows
  ),
  ins as (
    insert into public.pending_notifications (
      user_id,
      screen_definition_id,
      scheduled_for,
      payload
    )
    select
      due.user_id,
      due.screen_definition_id,
      due.scheduled_for,
      due.payload
    from due
    on conflict (user_id, screen_definition_id, scheduled_for) do nothing
    returning 1
  )
  select count(*) into inserted_count from ins;

  return inserted_count;
end;
$$;
ALTER FUNCTION "public"."enqueue_due_screen_notifications"("max_rows" integer) OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."generate_productivity_percentile_insight"("p_user_id" "uuid", "p_percentile" numeric, "p_period_start" "date", "p_period_end" "date") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_insight_id UUID;
    v_title TEXT;
    v_description TEXT;
    v_is_positive BOOLEAN;
BEGIN
    -- Determine sentiment based on percentile
    v_is_positive := p_percentile >= 50;
    
    -- Generate title and description
    IF p_percentile >= 75 THEN
        v_title := 'Excellent Productivity Performance';
        v_description := format('You''re in the top %s%% of your productivity range during this period.', 
                               ROUND(100 - p_percentile));
    ELSIF p_percentile >= 50 THEN
        v_title := 'Above Average Productivity';
        v_description := format('Your productivity is above your median level (%s percentile).', 
                               ROUND(p_percentile));
    ELSIF p_percentile >= 25 THEN
        v_title := 'Below Average Productivity';
        v_description := format('Your productivity is below your median level (%s percentile).', 
                               ROUND(p_percentile));
    ELSE
        v_title := 'Low Productivity Alert';
        v_description := format('You''re in the bottom %s%% of your productivity range.', 
                               ROUND(p_percentile));
    END IF;
    
    -- Insert insight
    INSERT INTO analytics_insights (
        user_id,
        insight_type,
        title,
        description,
        metadata,
        score,
        confidence,
        is_positive,
        period_start,
        period_end
    ) VALUES (
        p_user_id,
        'productivity_pattern',
        v_title,
        v_description,
        jsonb_build_object(
            'percentile', p_percentile,
            'metric', 'task_completion_rate'
        ),
        p_percentile,
        0.85,
        v_is_positive,
        p_period_start,
        p_period_end
    )
    RETURNING id INTO v_insight_id;
    
    RETURN v_insight_id;
END;
$$;
ALTER FUNCTION "public"."generate_productivity_percentile_insight"("p_user_id" "uuid", "p_percentile" numeric, "p_period_start" "date", "p_period_end" "date") OWNER TO "postgres";
COMMENT ON FUNCTION "public"."generate_productivity_percentile_insight"("p_user_id" "uuid", "p_percentile" numeric, "p_period_start" "date", "p_period_end" "date") IS 'Generate a productivity percentile insight for a user';
CREATE OR REPLACE FUNCTION "public"."get_significant_correlations"("p_user_id" "uuid", "p_min_coefficient" numeric DEFAULT 0.5, "p_limit" integer DEFAULT 10) RETURNS TABLE("id" "uuid", "source_type" "text", "source_id" "text", "target_type" "text", "target_id" "text", "coefficient" numeric, "strength" "text", "p_value" numeric, "is_significant" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ac.id,
        ac.source_type,
        ac.source_id,
        ac.target_type,
        ac.target_id,
        ac.coefficient,
        ac.strength,
        (ac.statistical_significance->>'pValue')::DECIMAL as p_value,
        (ac.statistical_significance->>'isSignificant')::BOOLEAN as is_significant
    FROM analytics_correlations ac
    WHERE ac.user_id = p_user_id
      AND ABS(ac.coefficient) >= p_min_coefficient
      AND ac.statistical_significance IS NOT NULL
      AND (ac.statistical_significance->>'isSignificant')::BOOLEAN = true
    ORDER BY ABS(ac.coefficient) DESC, ac.computed_at DESC
    LIMIT p_limit;
END;
$$;
ALTER FUNCTION "public"."get_significant_correlations"("p_user_id" "uuid", "p_min_coefficient" numeric, "p_limit" integer) OWNER TO "postgres";
COMMENT ON FUNCTION "public"."get_significant_correlations"("p_user_id" "uuid", "p_min_coefficient" numeric, "p_limit" integer) IS 'Get statistically significant correlations for a user';
CREATE OR REPLACE FUNCTION "public"."on_user_created"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  PERFORM create_default_attention_rules(NEW.user_id);
  RETURN NEW;
END;
$$;
ALTER FUNCTION "public"."on_user_created"() OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."prevent_delete_system_screens"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF (OLD.is_system = true OR OLD.is_system = 1) AND NOT public._is_privileged_delete() THEN
    RAISE EXCEPTION 'Cannot delete system screen (screen_key=%).', OLD.screen_key
      USING ERRCODE = '42501';
  END IF;

  RETURN OLD;
END;
$$;
ALTER FUNCTION "public"."prevent_delete_system_screens"() OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."project_next_actions_task_project_guard"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.project_id IS DISTINCT FROM OLD.project_id THEN
    DELETE FROM public.project_next_actions
    WHERE task_id = NEW.id
      AND (NEW.project_id IS NULL OR project_id <> NEW.project_id);
  END IF;
  RETURN NEW;
END;
$$;
ALTER FUNCTION "public"."project_next_actions_task_project_guard"() OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;
ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."screen_definitions_sync_trigger_fields"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  j jsonb;
  rt text;
  next_str text;
begin
  if new.trigger_config is null then
    new.trigger_type := null;
    new.next_trigger_at := null;
    return new;
  end if;

  -- trigger_config might be TEXT, JSON, or JSONB depending on your schema
  begin
    j := new.trigger_config::jsonb;
  exception when others then
    new.trigger_type := null;
    new.next_trigger_at := null;
    return new;
  end;

  rt := j->>'runtimeType';
  new.trigger_type := rt;

  if rt = 'schedule' then
    next_str := j->>'next_trigger_date';
    new.next_trigger_at := case
      when next_str is null or next_str = '' then null
      else next_str::timestamptz
    end;
  else
    new.next_trigger_at := null;
  end if;

  return new;
end;
$$;
ALTER FUNCTION "public"."screen_definitions_sync_trigger_fields"() OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."set_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END; $$;
ALTER FUNCTION "public"."set_timestamp"() OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;
ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."tasks_enforce_id_and_timestamps"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  -- Prevent client-supplied id on INSERT
  IF TG_OP = 'INSERT' THEN
    -- Ensure DB-generated timestamps. Allow client ID
    NEW.created_at := now();
    NEW.updated_at := now();
    RETURN NEW;
  END IF;

  -- On UPDATE: prevent client from changing created_at, always set updated_at
  IF TG_OP = 'UPDATE' THEN
    NEW.created_at := OLD.created_at;  
    -- Always set updated_at to now() (ignore any client provided value)
    NEW.updated_at := now();
    RETURN NEW;
  END IF;

  RETURN NEW;
END;$$;
ALTER FUNCTION "public"."tasks_enforce_id_and_timestamps"() OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."tg_set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;
ALTER FUNCTION "public"."tg_set_updated_at"() OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."trigger_set_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;
ALTER FUNCTION "public"."trigger_set_timestamp"() OWNER TO "postgres";
CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;
ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";
SET default_tablespace = '';
SET default_table_access_method = "heap";
CREATE TABLE IF NOT EXISTS "public"."analytics_correlations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "correlation_type" "text" NOT NULL,
    "source_type" "text" NOT NULL,
    "source_id" "text" NOT NULL,
    "target_type" "text" NOT NULL,
    "target_id" "text" NOT NULL,
    "period_start" "date" NOT NULL,
    "period_end" "date" NOT NULL,
    "coefficient" numeric(5,4),
    "sample_size" integer NOT NULL,
    "strength" "text" NOT NULL,
    "insight" "text",
    "value_with_source" numeric(5,2),
    "value_without_source" numeric(5,2),
    "computed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "statistical_significance" "jsonb",
    "performance_metrics" "jsonb"
);
ALTER TABLE "public"."analytics_correlations" OWNER TO "postgres";
COMMENT ON TABLE "public"."analytics_correlations" IS 'Cached correlation computations between data series';
COMMENT ON COLUMN "public"."analytics_correlations"."coefficient" IS 'Pearson correlation coefficient (-1 to 1)';
COMMENT ON COLUMN "public"."analytics_correlations"."statistical_significance" IS 'Statistical metrics: {pValue, confidenceInterval, standardError, tStatistic, degreesOfFreedom, isSignificant}';
COMMENT ON COLUMN "public"."analytics_correlations"."performance_metrics" IS 'Computation metrics: {calculationTimeMs, dataPoints, memoryUsedBytes, algorithm}';
CREATE TABLE IF NOT EXISTS "public"."analytics_insights" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "insight_type" "text" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "score" numeric(5,2),
    "confidence" numeric(5,2),
    "is_positive" boolean DEFAULT true NOT NULL,
    "generated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "period_start" "date" NOT NULL,
    "period_end" "date" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "analytics_insights_confidence_check" CHECK ((("confidence" >= (0)::numeric) AND ("confidence" <= (1)::numeric))),
    CONSTRAINT "analytics_insights_insight_type_check" CHECK (("insight_type" = ANY (ARRAY['correlation_discovery'::"text", 'trend_alert'::"text", 'anomaly_detection'::"text", 'productivity_pattern'::"text", 'mood_pattern'::"text", 'recommendation'::"text"]))),
    CONSTRAINT "analytics_insights_score_check" CHECK ((("score" >= (0)::numeric) AND ("score" <= (100)::numeric))),
    CONSTRAINT "valid_period" CHECK (("period_end" >= "period_start"))
);
ALTER TABLE "public"."analytics_insights" OWNER TO "postgres";
COMMENT ON TABLE "public"."analytics_insights" IS 'AI-generated insights from enhanced statistical analysis';
COMMENT ON COLUMN "public"."analytics_insights"."insight_type" IS 'Type of insight discovered';
COMMENT ON COLUMN "public"."analytics_insights"."metadata" IS 'Type-specific data: correlations, patterns, statistics';
COMMENT ON COLUMN "public"."analytics_insights"."score" IS 'Importance score 0-100';
COMMENT ON COLUMN "public"."analytics_insights"."confidence" IS 'Statistical confidence 0-1';
CREATE TABLE IF NOT EXISTS "public"."analytics_snapshots" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "entity_type" "text" NOT NULL,
    "entity_id" "text",
    "snapshot_date" "date" NOT NULL,
    "metrics" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);
ALTER TABLE "public"."analytics_snapshots" OWNER TO "postgres";
COMMENT ON TABLE "public"."analytics_snapshots" IS 'Historical snapshots for server-side computed analytics data';
COMMENT ON COLUMN "public"."analytics_snapshots"."entity_type" IS 'Type of entity: project, label, value, mood, tracker';
COMMENT ON COLUMN "public"."analytics_snapshots"."entity_id" IS 'ID of specific entity, NULL for user-level aggregates';
COMMENT ON COLUMN "public"."analytics_snapshots"."metrics" IS 'JSON object containing computed metrics';
CREATE TABLE IF NOT EXISTS "public"."attention_resolutions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "rule_id" "uuid" NOT NULL,
    "entity_id" "text" NOT NULL,
    "entity_type" "text" NOT NULL,
    "resolved_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "resolution_action" "text" NOT NULL,
    "action_details" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "attention_resolutions_entity_type_check" CHECK (("entity_type" = ANY (ARRAY['task'::"text", 'project'::"text", 'value'::"text", 'journal'::"text", 'tracker'::"text"]))),
    CONSTRAINT "attention_resolutions_resolution_action_check" CHECK (("resolution_action" = ANY (ARRAY['reviewed'::"text", 'skipped'::"text", 'snoozed'::"text", 'dismissed'::"text"])))
);
ALTER TABLE "public"."attention_resolutions" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."attention_rule_runtime_state" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "rule_id" "uuid" NOT NULL,
    "entity_type" "text",
    "entity_id" "text",
    "state_hash" "text",
    "dismissed_state_hash" "text",
    "last_evaluated_at" timestamp with time zone,
    "next_evaluate_after" timestamp with time zone,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "attention_rule_runtime_state_entity_pair_chk" CHECK (((("entity_type" IS NULL) AND ("entity_id" IS NULL)) OR (("entity_type" IS NOT NULL) AND ("entity_id" IS NOT NULL))))
);
ALTER TABLE "public"."attention_rule_runtime_state" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."attention_rules" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "rule_key" "text" NOT NULL,
    "domain" "text" NOT NULL,
    "source" "public"."entity_source" DEFAULT 'user_created'::"public"."entity_source" NOT NULL,
    "severity" "public"."attention_severity" DEFAULT 'info'::"public"."attention_severity" NOT NULL,
    "display_config" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "resolution_actions" "text"[] DEFAULT ARRAY['reviewed'::"text", 'skipped'::"text"] NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "bucket" "text" NOT NULL,
    "evaluator" "text" NOT NULL,
    "evaluator_params" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    CONSTRAINT "attention_rules_bucket_check" CHECK (("bucket" = ANY (ARRAY['action'::"text", 'review'::"text"])))
);
ALTER TABLE "public"."attention_rules" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."journal_entries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "entry_date" "date" NOT NULL,
    "entry_time" timestamp with time zone DEFAULT "now"() NOT NULL,
    "journal_text" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "occurred_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "local_date" "date" DEFAULT (("now"() AT TIME ZONE 'utc'::"text"))::"date" NOT NULL
);
ALTER TABLE "public"."journal_entries" OWNER TO "postgres";
COMMENT ON TABLE "public"."journal_entries" IS 'Daily journal entries with mood ratings';
COMMENT ON COLUMN "public"."journal_entries"."journal_text" IS 'Rich text journal content';
CREATE TABLE IF NOT EXISTS "public"."my_day_days" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "day_utc" "date" NOT NULL,
    "ritual_completed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);
ALTER TABLE "public"."my_day_days" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."my_day_picks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "day_id" "uuid" NOT NULL,
    "task_id" "uuid",
    "bucket" "public"."my_day_pick_bucket" NOT NULL,
    "sort_index" integer NOT NULL,
    "picked_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "suggestion_rank" integer,
    "qualifying_value_id" "uuid",
    "reason_codes" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "routine_id" "uuid",
    CONSTRAINT "my_day_picks_reason_codes_is_array" CHECK (("jsonb_typeof"("reason_codes") = 'array'::"text")),
    CONSTRAINT "my_day_picks_sort_index_check" CHECK (("sort_index" >= 0)),
    CONSTRAINT "my_day_picks_suggestion_rank_check" CHECK ((("suggestion_rank" IS NULL) OR ("suggestion_rank" >= 0))),
    CONSTRAINT "my_day_picks_task_or_routine_chk" CHECK (((("task_id" IS NOT NULL) AND ("routine_id" IS NULL)) OR (("task_id" IS NULL) AND ("routine_id" IS NOT NULL))))
);
ALTER TABLE "public"."my_day_picks" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."pending_notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "scheduled_for" timestamp with time zone NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "payload" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "delivered_at" timestamp with time zone,
    "seen_at" timestamp with time zone,
    "screen_key" "text"
);
ALTER TABLE "public"."pending_notifications" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."project_anchor_state" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "last_anchored_at" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);
ALTER TABLE "public"."project_anchor_state" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."project_completion_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "occurrence_date" "date",
    "original_occurrence_date" "date",
    "completed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "notes" "text",
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);
ALTER TABLE "public"."project_completion_history" OWNER TO "postgres";
COMMENT ON TABLE "public"."project_completion_history" IS 'Tracks completion of project occurrences (both repeating and non-repeating)';
CREATE TABLE IF NOT EXISTS "public"."project_next_actions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "task_id" "uuid" NOT NULL,
    "rank" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "project_next_actions_rank_check" CHECK ((("rank" >= 1) AND ("rank" <= 3)))
);
ALTER TABLE "public"."project_next_actions" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."project_recurrence_exceptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "original_date" "date" NOT NULL,
    "exception_type" "text" NOT NULL,
    "new_date" "date",
    "new_deadline" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    CONSTRAINT "project_recurrence_exceptions_exception_type_check" CHECK (("exception_type" = ANY (ARRAY['skip'::"text", 'reschedule'::"text"])))
);
ALTER TABLE "public"."project_recurrence_exceptions" OWNER TO "postgres";
COMMENT ON TABLE "public"."project_recurrence_exceptions" IS 'Modifications to individual project occurrences (skip or reschedule)';
CREATE TABLE IF NOT EXISTS "public"."projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "completed" boolean NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "start_date" "date",
    "deadline_date" "date",
    "repeat_ical_rrule" "text" DEFAULT ''::"text",
    "series_ended" boolean DEFAULT false NOT NULL,
    "repeat_from_completion" boolean DEFAULT false NOT NULL,
    "priority" integer,
    "pinned" boolean DEFAULT false NOT NULL,
    "primary_value_id" "uuid",
    "last_progress_at" timestamp with time zone,
    CONSTRAINT "projects_name_max_len" CHECK (("char_length"("name") <= 100)),
    CONSTRAINT "projects_priority_check" CHECK ((("priority" IS NULL) OR (("priority" >= 1) AND ("priority" <= 4))))
);
ALTER TABLE "public"."projects" OWNER TO "postgres";
COMMENT ON COLUMN "public"."projects"."series_ended" IS 'When true, stops generating future occurrences for repeating projects';
COMMENT ON COLUMN "public"."projects"."repeat_from_completion" IS 'When true, recurrence is anchored to last completion date instead of original start date. Used for rolling/relative recurrence patterns like "7 days after completion".';
CREATE TABLE IF NOT EXISTS "public"."routine_completions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "routine_id" "uuid" NOT NULL,
    "completed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);
ALTER TABLE "public"."routine_completions" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."routine_skips" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "routine_id" "uuid" NOT NULL,
    "period_type" "text" NOT NULL,
    "period_key" "date" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "routine_skips_period_type_check" CHECK (("period_type" = ANY (ARRAY['week'::"text", 'month'::"text"])))
);
ALTER TABLE "public"."routine_skips" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."routines" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "name" "text" NOT NULL,
    "value_id" "uuid" NOT NULL,
    "routine_type" "text" NOT NULL,
    "target_count" integer NOT NULL,
    "schedule_days" smallint[],
    "min_spacing_days" smallint,
    "rest_day_buffer" smallint,
    "preferred_weeks" smallint[],
    "fixed_day_of_month" smallint,
    "fixed_weekday" smallint,
    "fixed_week_of_month" smallint,
    "is_active" boolean DEFAULT true NOT NULL,
    "paused_until" "date",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "routines_fixed_day_of_month_check" CHECK ((("fixed_day_of_month" IS NULL) OR (("fixed_day_of_month" >= 1) AND ("fixed_day_of_month" <= 31)))),
    CONSTRAINT "routines_fixed_week_of_month_check" CHECK ((("fixed_week_of_month" IS NULL) OR (("fixed_week_of_month" >= 1) AND ("fixed_week_of_month" <= 5)))),
    CONSTRAINT "routines_fixed_weekday_check" CHECK ((("fixed_weekday" IS NULL) OR (("fixed_weekday" >= 1) AND ("fixed_weekday" <= 7)))),
    CONSTRAINT "routines_name_check" CHECK (("char_length"("name") <= 100)),
    CONSTRAINT "routines_routine_type_check" CHECK (("routine_type" = ANY (ARRAY['weekly_fixed'::"text", 'weekly_flexible'::"text", 'monthly_fixed'::"text", 'monthly_flexible'::"text"]))),
    CONSTRAINT "routines_target_count_check" CHECK (("target_count" >= 1))
);
ALTER TABLE "public"."routines" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."task_completion_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "task_id" "uuid" NOT NULL,
    "occurrence_date" "date",
    "original_occurrence_date" "date",
    "completed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "notes" "text",
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);
ALTER TABLE "public"."task_completion_history" OWNER TO "postgres";
COMMENT ON TABLE "public"."task_completion_history" IS 'Tracks completion of task occurrences (both repeating and non-repeating)';
COMMENT ON COLUMN "public"."task_completion_history"."occurrence_date" IS 'The scheduled date of the occurrence. NULL for non-repeating tasks.';
COMMENT ON COLUMN "public"."task_completion_history"."original_occurrence_date" IS 'Original RRULE-generated date. For rescheduled tasks, differs from occurrence_date. Used for on-time reporting.';
CREATE TABLE IF NOT EXISTS "public"."task_recurrence_exceptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "task_id" "uuid" NOT NULL,
    "original_date" "date" NOT NULL,
    "exception_type" "text" NOT NULL,
    "new_date" "date",
    "new_deadline" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    CONSTRAINT "task_recurrence_exceptions_exception_type_check" CHECK (("exception_type" = ANY (ARRAY['skip'::"text", 'reschedule'::"text"])))
);
ALTER TABLE "public"."task_recurrence_exceptions" OWNER TO "postgres";
COMMENT ON TABLE "public"."task_recurrence_exceptions" IS 'Modifications to individual task occurrences (skip or reschedule)';
COMMENT ON COLUMN "public"."task_recurrence_exceptions"."exception_type" IS 'skip = remove occurrence, reschedule = move to new_date';
COMMENT ON COLUMN "public"."task_recurrence_exceptions"."new_date" IS 'Target date for reschedule. NULL if skip.';
CREATE TABLE IF NOT EXISTS "public"."task_snooze_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "task_id" "uuid" NOT NULL,
    "snoozed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "snoozed_until" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);
ALTER TABLE "public"."task_snooze_events" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."tasks" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "completed" boolean DEFAULT false NOT NULL,
    "start_date" "date",
    "deadline_date" "date",
    "description" "text",
    "project_id" "uuid",
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "repeat_ical_rrule" "text" DEFAULT ''::"text",
    "series_ended" boolean DEFAULT false NOT NULL,
    "repeat_from_completion" boolean DEFAULT false NOT NULL,
    "review_notes" "text",
    "priority" integer,
    "pinned" boolean DEFAULT false NOT NULL,
    "override_primary_value_id" "uuid",
    "override_secondary_value_id" "uuid",
    "my_day_snoozed_until" "date",
    CONSTRAINT "tasks_name_max_len" CHECK (("char_length"("name") <= 100)),
    CONSTRAINT "tasks_override_primary_secondary_distinct_chk" CHECK ((("override_primary_value_id" IS NULL) OR ("override_secondary_value_id" IS NULL) OR ("override_primary_value_id" <> "override_secondary_value_id"))),
    CONSTRAINT "tasks_override_secondary_requires_primary_chk" CHECK ((("override_secondary_value_id" IS NULL) OR ("override_primary_value_id" IS NOT NULL))),
    CONSTRAINT "tasks_priority_check" CHECK ((("priority" IS NULL) OR (("priority" >= 1) AND ("priority" <= 4))))
);
ALTER TABLE "public"."tasks" OWNER TO "postgres";
COMMENT ON COLUMN "public"."tasks"."series_ended" IS 'When true, stops generating future occurrences for repeating tasks';
COMMENT ON COLUMN "public"."tasks"."repeat_from_completion" IS 'When true, recurrence is anchored to last completion date instead of original start date. Used for rolling/relative recurrence patterns like "7 days after completion".';
CREATE TABLE IF NOT EXISTS "public"."tracker_definition_choices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "tracker_id" "uuid" NOT NULL,
    "choice_key" "text" NOT NULL,
    "label" "text" NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);
ALTER TABLE "public"."tracker_definition_choices" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."tracker_definitions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "scope" "text" NOT NULL,
    "roles" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "value_type" "text" NOT NULL,
    "config" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "goal" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "source" "text" DEFAULT 'user'::"text" NOT NULL,
    "system_key" "text",
    "op_kind" "text" DEFAULT 'set'::"text" NOT NULL,
    "value_kind" "text",
    "unit_kind" "text",
    "min_int" bigint,
    "max_int" bigint,
    "step_int" bigint,
    "linked_value_id" "uuid",
    "is_outcome" boolean DEFAULT false NOT NULL,
    "is_insight_enabled" boolean DEFAULT false NOT NULL,
    "higher_is_better" boolean,
    "group_id" "uuid",
    CONSTRAINT "tracker_definitions_op_kind_check" CHECK (("op_kind" = ANY (ARRAY['set'::"text", 'add'::"text"]))),
    CONSTRAINT "tracker_definitions_op_value_kind_chk" CHECK ((("op_kind" = 'set'::"text") OR (("op_kind" = 'add'::"text") AND ("value_kind" = 'number'::"text")))),
    CONSTRAINT "tracker_definitions_scope_check" CHECK (("scope" = ANY (ARRAY['entry'::"text", 'day'::"text", 'sleep_night'::"text"]))),
    CONSTRAINT "tracker_definitions_source_check" CHECK (("source" = ANY (ARRAY['user'::"text", 'system'::"text"]))),
    CONSTRAINT "tracker_definitions_unit_kind_check" CHECK (("unit_kind" = ANY (ARRAY['count'::"text", 'ml'::"text", 'mg'::"text", 'minutes'::"text", 'steps'::"text"]))),
    CONSTRAINT "tracker_definitions_value_kind_check" CHECK (("value_kind" = ANY (ARRAY['rating'::"text", 'number'::"text", 'boolean'::"text", 'single_choice'::"text"]))),
    CONSTRAINT "tracker_definitions_value_type_check" CHECK (("value_type" = ANY (ARRAY['rating'::"text", 'quantity'::"text", 'choice'::"text", 'yes_no'::"text"])))
);
ALTER TABLE "public"."tracker_definitions" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."tracker_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "tracker_id" "uuid" NOT NULL,
    "anchor_type" "text" NOT NULL,
    "entry_id" "uuid",
    "anchor_date" "date",
    "op" "text" NOT NULL,
    "value" "jsonb",
    "occurred_at" timestamp with time zone NOT NULL,
    "recorded_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "tracker_events_anchor_entry_check" CHECK (((("anchor_type" = 'entry'::"text") AND ("entry_id" IS NOT NULL) AND ("anchor_date" IS NULL)) OR (("anchor_type" = ANY (ARRAY['day'::"text", 'sleep_night'::"text"])) AND ("anchor_date" IS NOT NULL) AND ("entry_id" IS NULL)))),
    CONSTRAINT "tracker_events_anchor_shape_chk" CHECK (((("anchor_type" = 'entry'::"text") AND ("entry_id" IS NOT NULL) AND ("anchor_date" IS NULL)) OR (("anchor_type" = ANY (ARRAY['day'::"text", 'sleep_night'::"text"])) AND ("anchor_date" IS NOT NULL) AND ("entry_id" IS NULL)))),
    CONSTRAINT "tracker_events_anchor_type_check" CHECK (("anchor_type" = ANY (ARRAY['entry'::"text", 'day'::"text", 'sleep_night'::"text"]))),
    CONSTRAINT "tracker_events_op_check" CHECK (("op" = ANY (ARRAY['set'::"text", 'add'::"text", 'clear'::"text"])))
);
ALTER TABLE "public"."tracker_events" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."tracker_groups" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "name" "text" NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "tracker_groups_name_check" CHECK (("char_length"("name") <= 100))
);
ALTER TABLE "public"."tracker_groups" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."tracker_preferences" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "tracker_id" "uuid" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "pinned" boolean DEFAULT false NOT NULL,
    "show_in_quick_add" boolean DEFAULT false NOT NULL,
    "color" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "tracker_preferences_color_check" CHECK ((("color" IS NULL) OR ("color" ~ '^#[0-9A-Fa-f]{6}$'::"text")))
);
ALTER TABLE "public"."tracker_preferences" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."tracker_state_day" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "anchor_type" "text" NOT NULL,
    "anchor_date" "date" NOT NULL,
    "tracker_id" "uuid" NOT NULL,
    "value" "jsonb",
    "last_event_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "tracker_state_day_anchor_type_check" CHECK (("anchor_type" = ANY (ARRAY['day'::"text", 'sleep_night'::"text"])))
);
ALTER TABLE "public"."tracker_state_day" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."tracker_state_entry" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "entry_id" "uuid" NOT NULL,
    "tracker_id" "uuid" NOT NULL,
    "value" "jsonb",
    "last_event_id" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);
ALTER TABLE "public"."tracker_state_entry" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."user_profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "settings_overrides" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);
ALTER TABLE "public"."user_profiles" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."value_ratings_weekly" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "value_id" "uuid" NOT NULL,
    "week_start" "date" NOT NULL,
    "rating" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "value_ratings_weekly_rating_check" CHECK ((("rating" >= 1) AND ("rating" <= 10)))
);
ALTER TABLE "public"."value_ratings_weekly" OWNER TO "postgres";
CREATE TABLE IF NOT EXISTS "public"."values" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "color" "text" DEFAULT '#ffffff'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "icon_name" "text",
    "priority" "public"."value_priority",
    CONSTRAINT "labels_color_hex_check" CHECK ((("color" IS NULL) OR ("color" ~ '^#[0-9A-Fa-f]{6}$'::"text"))),
    CONSTRAINT "labels_name_max_len" CHECK (("char_length"("name") <= 100))
);
ALTER TABLE "public"."values" OWNER TO "postgres";
ALTER TABLE ONLY "public"."analytics_correlations"
    ADD CONSTRAINT "analytics_correlations_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."analytics_insights"
    ADD CONSTRAINT "analytics_insights_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."analytics_snapshots"
    ADD CONSTRAINT "analytics_snapshots_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."attention_resolutions"
    ADD CONSTRAINT "attention_resolutions_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."attention_rule_runtime_state"
    ADD CONSTRAINT "attention_rule_runtime_state_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."attention_rules"
    ADD CONSTRAINT "attention_rules_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."attention_rules"
    ADD CONSTRAINT "attention_rules_user_rule_key_uk" UNIQUE ("user_id", "rule_key");
ALTER TABLE ONLY "public"."journal_entries"
    ADD CONSTRAINT "journal_entries_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."values"
    ADD CONSTRAINT "labels_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."values"
    ADD CONSTRAINT "labels_user_name_uniq" UNIQUE ("user_id", "name");
ALTER TABLE ONLY "public"."my_day_days"
    ADD CONSTRAINT "my_day_days_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."my_day_days"
    ADD CONSTRAINT "my_day_days_user_day_uniq" UNIQUE ("user_id", "day_utc");
ALTER TABLE ONLY "public"."my_day_picks"
    ADD CONSTRAINT "my_day_picks_day_task_uniq" UNIQUE ("day_id", "task_id");
ALTER TABLE ONLY "public"."my_day_picks"
    ADD CONSTRAINT "my_day_picks_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."pending_notifications"
    ADD CONSTRAINT "pending_notifications_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."project_anchor_state"
    ADD CONSTRAINT "project_anchor_state_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."project_anchor_state"
    ADD CONSTRAINT "project_anchor_state_unique" UNIQUE ("project_id");
ALTER TABLE ONLY "public"."project_completion_history"
    ADD CONSTRAINT "project_completion_history_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."project_completion_history"
    ADD CONSTRAINT "project_completion_history_project_id_occurrence_date_key" UNIQUE ("project_id", "occurrence_date");
ALTER TABLE ONLY "public"."project_next_actions"
    ADD CONSTRAINT "project_next_actions_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."project_recurrence_exceptions"
    ADD CONSTRAINT "project_recurrence_exceptions_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."project_recurrence_exceptions"
    ADD CONSTRAINT "project_recurrence_exceptions_project_id_original_date_key" UNIQUE ("project_id", "original_date");
ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."routine_completions"
    ADD CONSTRAINT "routine_completions_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."routine_skips"
    ADD CONSTRAINT "routine_skips_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."routine_skips"
    ADD CONSTRAINT "routine_skips_unique" UNIQUE ("routine_id", "period_type", "period_key");
ALTER TABLE ONLY "public"."routines"
    ADD CONSTRAINT "routines_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."task_completion_history"
    ADD CONSTRAINT "task_completion_history_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."task_completion_history"
    ADD CONSTRAINT "task_completion_history_task_id_occurrence_date_key" UNIQUE ("task_id", "occurrence_date");
ALTER TABLE ONLY "public"."task_recurrence_exceptions"
    ADD CONSTRAINT "task_recurrence_exceptions_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."task_recurrence_exceptions"
    ADD CONSTRAINT "task_recurrence_exceptions_task_id_original_date_key" UNIQUE ("task_id", "original_date");
ALTER TABLE ONLY "public"."task_snooze_events"
    ADD CONSTRAINT "task_snooze_events_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."tracker_definition_choices"
    ADD CONSTRAINT "tracker_definition_choices_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."tracker_definitions"
    ADD CONSTRAINT "tracker_definitions_pkey" PRIMARY KEY ("id");
ALTER TABLE "public"."tracker_definitions"
    ADD CONSTRAINT "tracker_definitions_sleep_set_only_chk" CHECK ((("scope" <> 'sleep_night'::"text") OR ("op_kind" = 'set'::"text"))) NOT VALID;
ALTER TABLE "public"."tracker_definitions"
    ADD CONSTRAINT "tracker_definitions_system_key_required_chk" CHECK (((("source" = 'user'::"text") AND ("system_key" IS NULL)) OR (("source" = 'system'::"text") AND ("system_key" IS NOT NULL)))) NOT VALID;
ALTER TABLE ONLY "public"."tracker_events"
    ADD CONSTRAINT "tracker_events_pkey" PRIMARY KEY ("id");
ALTER TABLE "public"."tracker_events"
    ADD CONSTRAINT "tracker_events_value_by_op_chk" CHECK (((("op" = 'clear'::"text") AND ("value" IS NULL)) OR (("op" = ANY (ARRAY['set'::"text", 'add'::"text"])) AND ("value" IS NOT NULL)))) NOT VALID;
ALTER TABLE ONLY "public"."tracker_groups"
    ADD CONSTRAINT "tracker_groups_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."tracker_preferences"
    ADD CONSTRAINT "tracker_preferences_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."tracker_state_day"
    ADD CONSTRAINT "tracker_state_day_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."tracker_state_entry"
    ADD CONSTRAINT "tracker_state_entry_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."analytics_correlations"
    ADD CONSTRAINT "unique_correlation" UNIQUE ("user_id", "correlation_type", "source_id", "target_id", "period_start");
ALTER TABLE ONLY "public"."analytics_snapshots"
    ADD CONSTRAINT "unique_snapshot" UNIQUE ("user_id", "entity_type", "entity_id", "snapshot_date");
ALTER TABLE ONLY "public"."journal_entries"
    ADD CONSTRAINT "unique_user_entry_date" UNIQUE ("user_id", "entry_date");
ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_user_id_unique" UNIQUE ("user_id");
ALTER TABLE ONLY "public"."value_ratings_weekly"
    ADD CONSTRAINT "value_ratings_weekly_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."value_ratings_weekly"
    ADD CONSTRAINT "value_ratings_weekly_user_value_week_unique" UNIQUE ("user_id", "value_id", "week_start");
CREATE INDEX "attention_resolutions_rule_id_idx" ON "public"."attention_resolutions" USING "btree" ("user_id", "rule_id");
CREATE INDEX "attention_resolutions_user_id_idx" ON "public"."attention_resolutions" USING "btree" ("user_id");
CREATE INDEX "attention_rule_runtime_state_user_rule_idx" ON "public"."attention_rule_runtime_state" USING "btree" ("user_id", "rule_id");
CREATE INDEX "attention_rules_active_idx" ON "public"."attention_rules" USING "btree" ("user_id", "active");
CREATE INDEX "attention_rules_user_active_bucket_idx" ON "public"."attention_rules" USING "btree" ("user_id", "active", "bucket");
CREATE INDEX "attention_rules_user_evaluator_idx" ON "public"."attention_rules" USING "btree" ("user_id", "evaluator");
CREATE INDEX "attention_rules_user_id_idx" ON "public"."attention_rules" USING "btree" ("user_id");
CREATE INDEX "idx_analytics_correlations_performance" ON "public"."analytics_correlations" USING "gin" ("performance_metrics") WHERE ("performance_metrics" IS NOT NULL);
CREATE INDEX "idx_analytics_correlations_period" ON "public"."analytics_correlations" USING "btree" ("period_start", "period_end");
CREATE INDEX "idx_analytics_correlations_significance" ON "public"."analytics_correlations" USING "gin" ("statistical_significance") WHERE ("statistical_significance" IS NOT NULL);
CREATE INDEX "idx_analytics_correlations_user" ON "public"."analytics_correlations" USING "btree" ("user_id", "correlation_type");
CREATE INDEX "idx_analytics_insights_metadata" ON "public"."analytics_insights" USING "gin" ("metadata");
CREATE INDEX "idx_analytics_insights_period" ON "public"."analytics_insights" USING "btree" ("period_start", "period_end");
CREATE INDEX "idx_analytics_insights_score" ON "public"."analytics_insights" USING "btree" ("user_id", "score" DESC) WHERE ("score" IS NOT NULL);
CREATE INDEX "idx_analytics_insights_type" ON "public"."analytics_insights" USING "btree" ("user_id", "insight_type", "generated_at" DESC);
CREATE INDEX "idx_analytics_insights_user" ON "public"."analytics_insights" USING "btree" ("user_id", "generated_at" DESC);
CREATE INDEX "idx_analytics_snapshots_date" ON "public"."analytics_snapshots" USING "btree" ("snapshot_date");
CREATE INDEX "idx_analytics_snapshots_lookup" ON "public"."analytics_snapshots" USING "btree" ("user_id", "entity_type", "entity_id", "snapshot_date");
CREATE INDEX "idx_journal_entries_user_date" ON "public"."journal_entries" USING "btree" ("user_id", "entry_date") WHERE ("deleted_at" IS NULL);
CREATE INDEX "idx_labels_user_id" ON "public"."values" USING "btree" ("user_id");
CREATE UNIQUE INDEX "idx_labels_user_lower_name_unique" ON "public"."values" USING "btree" ("user_id", "lower"("name"));
CREATE INDEX "idx_project_completion_date" ON "public"."project_completion_history" USING "btree" ("completed_at");
CREATE INDEX "idx_project_completion_history_user_id" ON "public"."project_completion_history" USING "btree" ("user_id");
CREATE INDEX "idx_project_completion_original_date" ON "public"."project_completion_history" USING "btree" ("project_id", "original_occurrence_date");
CREATE INDEX "idx_project_completion_project" ON "public"."project_completion_history" USING "btree" ("project_id", "occurrence_date");
CREATE INDEX "idx_project_completion_user" ON "public"."project_completion_history" USING "btree" ("user_id");
CREATE INDEX "idx_project_exception_new_date" ON "public"."project_recurrence_exceptions" USING "btree" ("project_id", "new_date") WHERE ("new_date" IS NOT NULL);
CREATE INDEX "idx_project_exception_project" ON "public"."project_recurrence_exceptions" USING "btree" ("project_id", "original_date");
CREATE INDEX "idx_project_recurrence_exceptions_user_id" ON "public"."project_recurrence_exceptions" USING "btree" ("user_id");
CREATE INDEX "idx_projects_priority" ON "public"."projects" USING "btree" ("user_id", "priority") WHERE ("priority" IS NOT NULL);
CREATE INDEX "idx_projects_user_id" ON "public"."projects" USING "btree" ("user_id");
CREATE INDEX "idx_task_completion_date" ON "public"."task_completion_history" USING "btree" ("completed_at");
CREATE INDEX "idx_task_completion_history_user_id" ON "public"."task_completion_history" USING "btree" ("user_id");
CREATE INDEX "idx_task_completion_original_date" ON "public"."task_completion_history" USING "btree" ("task_id", "original_occurrence_date");
CREATE INDEX "idx_task_completion_task" ON "public"."task_completion_history" USING "btree" ("task_id", "occurrence_date");
CREATE INDEX "idx_task_completion_user" ON "public"."task_completion_history" USING "btree" ("user_id");
CREATE INDEX "idx_task_exception_new_date" ON "public"."task_recurrence_exceptions" USING "btree" ("task_id", "new_date") WHERE ("new_date" IS NOT NULL);
CREATE INDEX "idx_task_exception_task" ON "public"."task_recurrence_exceptions" USING "btree" ("task_id", "original_date");
CREATE INDEX "idx_task_recurrence_exceptions_user_id" ON "public"."task_recurrence_exceptions" USING "btree" ("user_id");
CREATE INDEX "idx_tasks_priority" ON "public"."tasks" USING "btree" ("user_id", "priority") WHERE ("priority" IS NOT NULL);
CREATE INDEX "idx_tasks_project_id" ON "public"."tasks" USING "btree" ("project_id");
CREATE INDEX "idx_tasks_user_completed_deadline" ON "public"."tasks" USING "btree" ("user_id", "completed", "deadline_date");
CREATE INDEX "idx_tasks_user_id" ON "public"."tasks" USING "btree" ("user_id");
CREATE INDEX "idx_user_profiles_user_id" ON "public"."user_profiles" USING "btree" ("user_id");
CREATE INDEX "my_day_days_user_day_idx" ON "public"."my_day_days" USING "btree" ("user_id", "day_utc");
CREATE UNIQUE INDEX "my_day_picks_day_routine_unique" ON "public"."my_day_picks" USING "btree" ("day_id", "routine_id") WHERE ("routine_id" IS NOT NULL);
CREATE INDEX "my_day_picks_day_sort_idx" ON "public"."my_day_picks" USING "btree" ("day_id", "sort_index");
CREATE UNIQUE INDEX "my_day_picks_day_task_unique" ON "public"."my_day_picks" USING "btree" ("day_id", "task_id") WHERE ("task_id" IS NOT NULL);
CREATE INDEX "my_day_picks_user_task_idx" ON "public"."my_day_picks" USING "btree" ("user_id", "task_id");
CREATE INDEX "pending_notifications_user_status_due" ON "public"."pending_notifications" USING "btree" ("user_id", "status", "scheduled_for");
CREATE INDEX "project_next_actions_project_id_idx" ON "public"."project_next_actions" USING "btree" ("project_id");
CREATE UNIQUE INDEX "project_next_actions_project_rank_uq" ON "public"."project_next_actions" USING "btree" ("project_id", "rank");
CREATE UNIQUE INDEX "project_next_actions_project_task_uq" ON "public"."project_next_actions" USING "btree" ("project_id", "task_id");
CREATE INDEX "project_next_actions_task_id_idx" ON "public"."project_next_actions" USING "btree" ("task_id");
CREATE INDEX "project_next_actions_user_id_idx" ON "public"."project_next_actions" USING "btree" ("user_id");
CREATE INDEX "projects_primary_value_id_idx" ON "public"."projects" USING "btree" ("primary_value_id");
CREATE INDEX "routine_completions_completed_at_idx" ON "public"."routine_completions" USING "btree" ("completed_at");
CREATE INDEX "routine_completions_routine_id_idx" ON "public"."routine_completions" USING "btree" ("routine_id");
CREATE INDEX "routine_completions_user_id_idx" ON "public"."routine_completions" USING "btree" ("user_id");
CREATE INDEX "routine_skips_routine_id_idx" ON "public"."routine_skips" USING "btree" ("routine_id");
CREATE INDEX "routine_skips_user_id_idx" ON "public"."routine_skips" USING "btree" ("user_id");
CREATE INDEX "routines_user_id_idx" ON "public"."routines" USING "btree" ("user_id");
CREATE INDEX "routines_value_id_idx" ON "public"."routines" USING "btree" ("value_id");
CREATE INDEX "task_snooze_events_snoozed_at_idx" ON "public"."task_snooze_events" USING "btree" ("snoozed_at");
CREATE INDEX "task_snooze_events_task_id_idx" ON "public"."task_snooze_events" USING "btree" ("task_id");
CREATE INDEX "task_snooze_events_user_id_idx" ON "public"."task_snooze_events" USING "btree" ("user_id");
CREATE INDEX "tasks_override_primary_value_id_idx" ON "public"."tasks" USING "btree" ("override_primary_value_id");
CREATE INDEX "tasks_override_secondary_value_id_idx" ON "public"."tasks" USING "btree" ("override_secondary_value_id");
CREATE UNIQUE INDEX "tracker_definition_choices_unique" ON "public"."tracker_definition_choices" USING "btree" ("user_id", "tracker_id", "choice_key");
CREATE INDEX "tracker_definitions_user_group_sort_idx" ON "public"."tracker_definitions" USING "btree" ("user_id", "group_id", "sort_order");
CREATE UNIQUE INDEX "tracker_definitions_user_name_uniq" ON "public"."tracker_definitions" USING "btree" ("user_id", "lower"("name")) WHERE ("deleted_at" IS NULL);
CREATE INDEX "tracker_definitions_user_scope_active_idx" ON "public"."tracker_definitions" USING "btree" ("user_id", "scope", "is_active", "sort_order") WHERE ("deleted_at" IS NULL);
CREATE INDEX "tracker_definitions_user_scope_sort_idx" ON "public"."tracker_definitions" USING "btree" ("user_id", "scope", "sort_order");
CREATE UNIQUE INDEX "tracker_definitions_user_system_key_unique" ON "public"."tracker_definitions" USING "btree" ("user_id", "system_key") WHERE ("system_key" IS NOT NULL);
CREATE INDEX "tracker_events_user_anchor_date_idx" ON "public"."tracker_events" USING "btree" ("user_id", "anchor_type", "anchor_date") WHERE ("anchor_date" IS NOT NULL);
CREATE INDEX "tracker_events_user_anchor_day_idx" ON "public"."tracker_events" USING "btree" ("user_id", "anchor_type", "anchor_date", "occurred_at" DESC);
CREATE INDEX "tracker_events_user_anchor_entry_idx" ON "public"."tracker_events" USING "btree" ("user_id", "anchor_type", "entry_id") WHERE ("entry_id" IS NOT NULL);
CREATE INDEX "tracker_events_user_entry_time_idx" ON "public"."tracker_events" USING "btree" ("user_id", "entry_id", "occurred_at" DESC);
CREATE INDEX "tracker_events_user_tracker_occurred_idx" ON "public"."tracker_events" USING "btree" ("user_id", "tracker_id", "occurred_at" DESC);
CREATE INDEX "tracker_events_user_tracker_time_idx" ON "public"."tracker_events" USING "btree" ("user_id", "tracker_id", "occurred_at" DESC);
CREATE UNIQUE INDEX "tracker_groups_user_name_unique" ON "public"."tracker_groups" USING "btree" ("user_id", "lower"("name"));
CREATE INDEX "tracker_groups_user_sort_idx" ON "public"."tracker_groups" USING "btree" ("user_id", "sort_order");
CREATE UNIQUE INDEX "tracker_preferences_user_tracker_unique" ON "public"."tracker_preferences" USING "btree" ("user_id", "tracker_id");
CREATE INDEX "tracker_state_day_lookup_idx" ON "public"."tracker_state_day" USING "btree" ("user_id", "anchor_type", "anchor_date");
CREATE UNIQUE INDEX "tracker_state_day_uniq" ON "public"."tracker_state_day" USING "btree" ("user_id", "anchor_type", "anchor_date", "tracker_id");
CREATE UNIQUE INDEX "tracker_state_day_unique_key" ON "public"."tracker_state_day" USING "btree" ("user_id", "anchor_type", "anchor_date", "tracker_id");
CREATE UNIQUE INDEX "tracker_state_entry_uniq" ON "public"."tracker_state_entry" USING "btree" ("user_id", "entry_id", "tracker_id");
CREATE UNIQUE INDEX "tracker_state_entry_unique_key" ON "public"."tracker_state_entry" USING "btree" ("user_id", "entry_id", "tracker_id");
CREATE UNIQUE INDEX "ux_analytics_snapshots_entity_date" ON "public"."analytics_snapshots" USING "btree" ("user_id", "entity_type", "entity_id", "snapshot_date") NULLS NOT DISTINCT;
COMMENT ON INDEX "public"."ux_analytics_snapshots_entity_date" IS 'Ensures one analytics snapshot per entity per day. NULLS NOT DISTINCT handles global snapshots.';
CREATE UNIQUE INDEX "ux_project_completion_history_project_occurrence" ON "public"."project_completion_history" USING "btree" ("project_id", "occurrence_date") NULLS NOT DISTINCT;
COMMENT ON INDEX "public"."ux_project_completion_history_project_occurrence" IS 'Ensures a project occurrence can only be completed once. NULLS NOT DISTINCT handles non-repeating projects.';
CREATE UNIQUE INDEX "ux_project_recurrence_exceptions_project_date" ON "public"."project_recurrence_exceptions" USING "btree" ("project_id", "original_date");
COMMENT ON INDEX "public"."ux_project_recurrence_exceptions_project_date" IS 'Ensures only one exception (skip/reschedule) per project per original RRULE date.';
CREATE UNIQUE INDEX "ux_task_completion_history_task_occurrence" ON "public"."task_completion_history" USING "btree" ("task_id", "occurrence_date") NULLS NOT DISTINCT;
COMMENT ON INDEX "public"."ux_task_completion_history_task_occurrence" IS 'Ensures a task occurrence can only be completed once. NULLS NOT DISTINCT handles non-repeating tasks.';
CREATE UNIQUE INDEX "ux_task_recurrence_exceptions_task_date" ON "public"."task_recurrence_exceptions" USING "btree" ("task_id", "original_date");
COMMENT ON INDEX "public"."ux_task_recurrence_exceptions_task_date" IS 'Ensures only one exception (skip/reschedule) per task per original RRULE date.';
CREATE INDEX "value_ratings_weekly_user_id_idx" ON "public"."value_ratings_weekly" USING "btree" ("user_id");
CREATE INDEX "value_ratings_weekly_value_id_idx" ON "public"."value_ratings_weekly" USING "btree" ("value_id");
CREATE INDEX "value_ratings_weekly_week_start_idx" ON "public"."value_ratings_weekly" USING "btree" ("week_start");
CREATE OR REPLACE TRIGGER "set_project_completion_updated_at" BEFORE UPDATE ON "public"."project_completion_history" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();
CREATE OR REPLACE TRIGGER "set_project_exception_updated_at" BEFORE UPDATE ON "public"."project_recurrence_exceptions" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();
CREATE OR REPLACE TRIGGER "set_task_completion_updated_at" BEFORE UPDATE ON "public"."task_completion_history" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();
CREATE OR REPLACE TRIGGER "set_task_exception_updated_at" BEFORE UPDATE ON "public"."task_recurrence_exceptions" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();
CREATE OR REPLACE TRIGGER "set_updated_at_tracker_definitions" BEFORE UPDATE ON "public"."tracker_definitions" FOR EACH ROW EXECUTE FUNCTION "public"."tg_set_updated_at"();
CREATE OR REPLACE TRIGGER "set_updated_at_tracker_state_day" BEFORE UPDATE ON "public"."tracker_state_day" FOR EACH ROW EXECUTE FUNCTION "public"."tg_set_updated_at"();
CREATE OR REPLACE TRIGGER "set_updated_at_tracker_state_entry" BEFORE UPDATE ON "public"."tracker_state_entry" FOR EACH ROW EXECUTE FUNCTION "public"."tg_set_updated_at"();
CREATE OR REPLACE TRIGGER "tasks_enforce_id_and_timestamps_trg" BEFORE INSERT OR UPDATE ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."tasks_enforce_id_and_timestamps"();
CREATE OR REPLACE TRIGGER "trg_attention_rule_runtime_state_set_updated_at" BEFORE UPDATE ON "public"."attention_rule_runtime_state" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();
CREATE OR REPLACE TRIGGER "trg_attention_rules_set_updated_at" BEFORE UPDATE ON "public"."attention_rules" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();
CREATE OR REPLACE TRIGGER "trg_my_day_days_updated_at" BEFORE UPDATE ON "public"."my_day_days" FOR EACH ROW EXECUTE FUNCTION "public"."_set_updated_at"();
CREATE OR REPLACE TRIGGER "trg_my_day_picks_updated_at" BEFORE UPDATE ON "public"."my_day_picks" FOR EACH ROW EXECUTE FUNCTION "public"."_set_updated_at"();
CREATE OR REPLACE TRIGGER "trg_project_next_actions_task_project_guard" AFTER UPDATE OF "project_id" ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."project_next_actions_task_project_guard"();
CREATE OR REPLACE TRIGGER "user_profiles_set_timestamp" BEFORE UPDATE ON "public"."user_profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_timestamp"();
ALTER TABLE ONLY "public"."analytics_correlations"
    ADD CONSTRAINT "analytics_correlations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."analytics_insights"
    ADD CONSTRAINT "analytics_insights_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."analytics_snapshots"
    ADD CONSTRAINT "analytics_snapshots_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."attention_resolutions"
    ADD CONSTRAINT "attention_resolutions_rule_id_fkey" FOREIGN KEY ("rule_id") REFERENCES "public"."attention_rules"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."attention_resolutions"
    ADD CONSTRAINT "attention_resolutions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."attention_rule_runtime_state"
    ADD CONSTRAINT "attention_rule_runtime_state_rule_id_fkey" FOREIGN KEY ("rule_id") REFERENCES "public"."attention_rules"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."attention_rule_runtime_state"
    ADD CONSTRAINT "attention_rule_runtime_state_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."attention_rules"
    ADD CONSTRAINT "attention_rules_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."journal_entries"
    ADD CONSTRAINT "journal_entries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."values"
    ADD CONSTRAINT "labels_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."my_day_picks"
    ADD CONSTRAINT "my_day_picks_day_id_fkey" FOREIGN KEY ("day_id") REFERENCES "public"."my_day_days"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."my_day_picks"
    ADD CONSTRAINT "my_day_picks_qualifying_value_id_fkey" FOREIGN KEY ("qualifying_value_id") REFERENCES "public"."values"("id") ON DELETE SET NULL;
ALTER TABLE ONLY "public"."my_day_picks"
    ADD CONSTRAINT "my_day_picks_routine_id_fkey" FOREIGN KEY ("routine_id") REFERENCES "public"."routines"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."my_day_picks"
    ADD CONSTRAINT "my_day_picks_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."project_anchor_state"
    ADD CONSTRAINT "project_anchor_state_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."project_anchor_state"
    ADD CONSTRAINT "project_anchor_state_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."project_completion_history"
    ADD CONSTRAINT "project_completion_history_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."project_completion_history"
    ADD CONSTRAINT "project_completion_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;
ALTER TABLE ONLY "public"."project_next_actions"
    ADD CONSTRAINT "project_next_actions_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."project_next_actions"
    ADD CONSTRAINT "project_next_actions_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."project_next_actions"
    ADD CONSTRAINT "project_next_actions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."project_recurrence_exceptions"
    ADD CONSTRAINT "project_recurrence_exceptions_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."project_recurrence_exceptions"
    ADD CONSTRAINT "project_recurrence_exceptions_user_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_primary_value_id_fkey" FOREIGN KEY ("primary_value_id") REFERENCES "public"."values"("id") ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY "public"."routine_completions"
    ADD CONSTRAINT "routine_completions_routine_id_fkey" FOREIGN KEY ("routine_id") REFERENCES "public"."routines"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."routine_completions"
    ADD CONSTRAINT "routine_completions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."routine_skips"
    ADD CONSTRAINT "routine_skips_routine_id_fkey" FOREIGN KEY ("routine_id") REFERENCES "public"."routines"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."routine_skips"
    ADD CONSTRAINT "routine_skips_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."routines"
    ADD CONSTRAINT "routines_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."routines"
    ADD CONSTRAINT "routines_value_id_fkey" FOREIGN KEY ("value_id") REFERENCES "public"."values"("id");
ALTER TABLE ONLY "public"."task_completion_history"
    ADD CONSTRAINT "task_completion_history_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."task_completion_history"
    ADD CONSTRAINT "task_completion_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;
ALTER TABLE ONLY "public"."task_recurrence_exceptions"
    ADD CONSTRAINT "task_recurrence_exceptions_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."task_recurrence_exceptions"
    ADD CONSTRAINT "task_recurrence_exceptions_user_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."task_snooze_events"
    ADD CONSTRAINT "task_snooze_events_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY "public"."task_snooze_events"
    ADD CONSTRAINT "task_snooze_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_override_primary_value_id_fkey" FOREIGN KEY ("override_primary_value_id") REFERENCES "public"."values"("id") ON DELETE SET NULL;
ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_override_secondary_value_id_fkey" FOREIGN KEY ("override_secondary_value_id") REFERENCES "public"."values"("id") ON DELETE SET NULL;
ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY "public"."tracker_definition_choices"
    ADD CONSTRAINT "tracker_definition_choices_tracker_id_fkey" FOREIGN KEY ("tracker_id") REFERENCES "public"."tracker_definitions"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."tracker_definition_choices"
    ADD CONSTRAINT "tracker_definition_choices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."tracker_definitions"
    ADD CONSTRAINT "tracker_definitions_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."tracker_groups"("id") ON DELETE SET NULL;
ALTER TABLE ONLY "public"."tracker_definitions"
    ADD CONSTRAINT "tracker_definitions_linked_value_id_fkey" FOREIGN KEY ("linked_value_id") REFERENCES "public"."values"("id") ON DELETE SET NULL;
ALTER TABLE ONLY "public"."tracker_definitions"
    ADD CONSTRAINT "tracker_definitions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."tracker_events"
    ADD CONSTRAINT "tracker_events_entry_id_fkey" FOREIGN KEY ("entry_id") REFERENCES "public"."journal_entries"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."tracker_events"
    ADD CONSTRAINT "tracker_events_tracker_id_fkey" FOREIGN KEY ("tracker_id") REFERENCES "public"."tracker_definitions"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."tracker_events"
    ADD CONSTRAINT "tracker_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."tracker_groups"
    ADD CONSTRAINT "tracker_groups_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."tracker_preferences"
    ADD CONSTRAINT "tracker_preferences_tracker_id_fkey" FOREIGN KEY ("tracker_id") REFERENCES "public"."tracker_definitions"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."tracker_preferences"
    ADD CONSTRAINT "tracker_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."tracker_state_day"
    ADD CONSTRAINT "tracker_state_day_tracker_id_fkey" FOREIGN KEY ("tracker_id") REFERENCES "public"."tracker_definitions"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."tracker_state_day"
    ADD CONSTRAINT "tracker_state_day_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."tracker_state_entry"
    ADD CONSTRAINT "tracker_state_entry_entry_id_fkey" FOREIGN KEY ("entry_id") REFERENCES "public"."journal_entries"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."tracker_state_entry"
    ADD CONSTRAINT "tracker_state_entry_tracker_id_fkey" FOREIGN KEY ("tracker_id") REFERENCES "public"."tracker_definitions"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."tracker_state_entry"
    ADD CONSTRAINT "tracker_state_entry_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;
ALTER TABLE ONLY "public"."value_ratings_weekly"
    ADD CONSTRAINT "value_ratings_weekly_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."value_ratings_weekly"
    ADD CONSTRAINT "value_ratings_weekly_value_id_fkey" FOREIGN KEY ("value_id") REFERENCES "public"."values"("id");
CREATE POLICY "Enable insert for users based on user_id" ON "public"."task_snooze_events" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));
CREATE POLICY "Users can delete own profile" ON "public"."user_profiles" FOR DELETE USING (("auth"."uid"() = "user_id"));
CREATE POLICY "Users can insert own profile" ON "public"."user_profiles" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));
CREATE POLICY "Users can update own profile" ON "public"."user_profiles" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));
CREATE POLICY "Users can view own profile" ON "public"."user_profiles" FOR SELECT USING (("auth"."uid"() = "user_id"));
ALTER TABLE "public"."analytics_correlations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."analytics_insights" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."analytics_snapshots" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."attention_resolutions" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "attention_resolutions_delete_own" ON "public"."attention_resolutions" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));
CREATE POLICY "attention_resolutions_insert_own" ON "public"."attention_resolutions" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));
CREATE POLICY "attention_resolutions_select_own" ON "public"."attention_resolutions" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));
ALTER TABLE "public"."attention_rule_runtime_state" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "attention_rule_runtime_state_delete_own" ON "public"."attention_rule_runtime_state" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));
CREATE POLICY "attention_rule_runtime_state_insert_own" ON "public"."attention_rule_runtime_state" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));
CREATE POLICY "attention_rule_runtime_state_select_own" ON "public"."attention_rule_runtime_state" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));
CREATE POLICY "attention_rule_runtime_state_update_own" ON "public"."attention_rule_runtime_state" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));
ALTER TABLE "public"."attention_rules" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "attention_rules_delete_own" ON "public"."attention_rules" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));
CREATE POLICY "attention_rules_insert_own" ON "public"."attention_rules" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));
CREATE POLICY "attention_rules_select_own" ON "public"."attention_rules" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));
CREATE POLICY "attention_rules_update_own" ON "public"."attention_rules" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));
ALTER TABLE "public"."journal_entries" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."my_day_days" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "my_day_days_delete_own" ON "public"."my_day_days" FOR DELETE USING (("user_id" = "auth"."uid"()));
CREATE POLICY "my_day_days_insert_own" ON "public"."my_day_days" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));
CREATE POLICY "my_day_days_select_own" ON "public"."my_day_days" FOR SELECT USING (("user_id" = "auth"."uid"()));
CREATE POLICY "my_day_days_update_own" ON "public"."my_day_days" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));
ALTER TABLE "public"."my_day_picks" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "my_day_picks_delete_own" ON "public"."my_day_picks" FOR DELETE USING (("user_id" = "auth"."uid"()));
CREATE POLICY "my_day_picks_insert_own" ON "public"."my_day_picks" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));
CREATE POLICY "my_day_picks_select_own" ON "public"."my_day_picks" FOR SELECT USING (("user_id" = "auth"."uid"()));
CREATE POLICY "my_day_picks_update_own" ON "public"."my_day_picks" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));
ALTER TABLE "public"."pending_notifications" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pending_notifications_insert_own" ON "public"."pending_notifications" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));
CREATE POLICY "pending_notifications_select_own" ON "public"."pending_notifications" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));
CREATE POLICY "pending_notifications_update_own" ON "public"."pending_notifications" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));
ALTER TABLE "public"."project_anchor_state" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "project_anchor_state_delete" ON "public"."project_anchor_state" FOR DELETE USING (("auth"."uid"() = "user_id"));
CREATE POLICY "project_anchor_state_insert" ON "public"."project_anchor_state" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));
CREATE POLICY "project_anchor_state_select" ON "public"."project_anchor_state" FOR SELECT USING (("auth"."uid"() = "user_id"));
CREATE POLICY "project_anchor_state_update" ON "public"."project_anchor_state" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));
ALTER TABLE "public"."project_completion_history" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."project_next_actions" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "project_next_actions_delete" ON "public"."project_next_actions" FOR DELETE USING (("auth"."uid"() = "user_id"));
CREATE POLICY "project_next_actions_insert" ON "public"."project_next_actions" FOR INSERT WITH CHECK ((("auth"."uid"() = "user_id") AND (EXISTS ( SELECT 1
   FROM "public"."projects" "p"
  WHERE (("p"."id" = "project_next_actions"."project_id") AND ("p"."user_id" = "auth"."uid"())))) AND (EXISTS ( SELECT 1
   FROM "public"."tasks" "t"
  WHERE (("t"."id" = "project_next_actions"."task_id") AND ("t"."user_id" = "auth"."uid"()))))));
CREATE POLICY "project_next_actions_select" ON "public"."project_next_actions" FOR SELECT USING (("auth"."uid"() = "user_id"));
CREATE POLICY "project_next_actions_update" ON "public"."project_next_actions" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));
ALTER TABLE "public"."project_recurrence_exceptions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."projects" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rls_user_owner" ON "public"."analytics_correlations" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));
CREATE POLICY "rls_user_owner" ON "public"."analytics_insights" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));
CREATE POLICY "rls_user_owner" ON "public"."analytics_snapshots" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));
CREATE POLICY "rls_user_owner" ON "public"."journal_entries" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));
CREATE POLICY "rls_user_owner" ON "public"."project_completion_history" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));
CREATE POLICY "rls_user_owner" ON "public"."project_recurrence_exceptions" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));
CREATE POLICY "rls_user_owner" ON "public"."projects" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));
CREATE POLICY "rls_user_owner" ON "public"."task_completion_history" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));
CREATE POLICY "rls_user_owner" ON "public"."task_recurrence_exceptions" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));
CREATE POLICY "rls_user_owner" ON "public"."tasks" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));
CREATE POLICY "rls_user_owner" ON "public"."values" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));
ALTER TABLE "public"."routine_completions" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "routine_completions_delete" ON "public"."routine_completions" FOR DELETE USING (("auth"."uid"() = "user_id"));
CREATE POLICY "routine_completions_insert" ON "public"."routine_completions" FOR INSERT WITH CHECK ((("auth"."uid"() = "user_id") AND (EXISTS ( SELECT 1
   FROM "public"."routines" "r"
  WHERE (("r"."id" = "routine_completions"."routine_id") AND ("r"."user_id" = "auth"."uid"()))))));
CREATE POLICY "routine_completions_select" ON "public"."routine_completions" FOR SELECT USING (("auth"."uid"() = "user_id"));
CREATE POLICY "routine_completions_update" ON "public"."routine_completions" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));
ALTER TABLE "public"."routine_skips" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "routine_skips_delete" ON "public"."routine_skips" FOR DELETE USING (("auth"."uid"() = "user_id"));
CREATE POLICY "routine_skips_insert" ON "public"."routine_skips" FOR INSERT WITH CHECK ((("auth"."uid"() = "user_id") AND (EXISTS ( SELECT 1
   FROM "public"."routines" "r"
  WHERE (("r"."id" = "routine_skips"."routine_id") AND ("r"."user_id" = "auth"."uid"()))))));
CREATE POLICY "routine_skips_select" ON "public"."routine_skips" FOR SELECT USING (("auth"."uid"() = "user_id"));
CREATE POLICY "routine_skips_update" ON "public"."routine_skips" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));
ALTER TABLE "public"."routines" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "routines_delete" ON "public"."routines" FOR DELETE USING (("auth"."uid"() = "user_id"));
CREATE POLICY "routines_insert" ON "public"."routines" FOR INSERT WITH CHECK ((("auth"."uid"() = "user_id") AND (EXISTS ( SELECT 1
   FROM "public"."values" "v"
  WHERE (("v"."id" = "routines"."value_id") AND ("v"."user_id" = "auth"."uid"()))))));
CREATE POLICY "routines_select" ON "public"."routines" FOR SELECT USING (("auth"."uid"() = "user_id"));
CREATE POLICY "routines_update" ON "public"."routines" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));
ALTER TABLE "public"."task_completion_history" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."task_recurrence_exceptions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."task_snooze_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."tasks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."tracker_definition_choices" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tracker_definition_choices_write_own" ON "public"."tracker_definition_choices" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));
ALTER TABLE "public"."tracker_definitions" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tracker_definitions_owner_all" ON "public"."tracker_definitions" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));
ALTER TABLE "public"."tracker_events" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tracker_events_delete_own" ON "public"."tracker_events" FOR DELETE USING (("user_id" = "auth"."uid"()));
CREATE POLICY "tracker_events_insert_own" ON "public"."tracker_events" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));
CREATE POLICY "tracker_events_select_own" ON "public"."tracker_events" FOR SELECT USING (("user_id" = "auth"."uid"()));
CREATE POLICY "tracker_events_update_own" ON "public"."tracker_events" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));
ALTER TABLE "public"."tracker_groups" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tracker_groups_delete_own" ON "public"."tracker_groups" FOR DELETE USING (("auth"."uid"() = "user_id"));
CREATE POLICY "tracker_groups_insert_own" ON "public"."tracker_groups" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));
CREATE POLICY "tracker_groups_select_own" ON "public"."tracker_groups" FOR SELECT USING (("auth"."uid"() = "user_id"));
CREATE POLICY "tracker_groups_update_own" ON "public"."tracker_groups" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));
ALTER TABLE "public"."tracker_preferences" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tracker_preferences_delete_own" ON "public"."tracker_preferences" FOR DELETE USING (("user_id" = "auth"."uid"()));
CREATE POLICY "tracker_preferences_insert_own" ON "public"."tracker_preferences" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));
CREATE POLICY "tracker_preferences_select_own" ON "public"."tracker_preferences" FOR SELECT USING (("user_id" = "auth"."uid"()));
CREATE POLICY "tracker_preferences_update_own" ON "public"."tracker_preferences" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));
ALTER TABLE "public"."tracker_state_day" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tracker_state_day_delete_own" ON "public"."tracker_state_day" FOR DELETE USING (("user_id" = "auth"."uid"()));
CREATE POLICY "tracker_state_day_insert_own" ON "public"."tracker_state_day" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));
CREATE POLICY "tracker_state_day_select_own" ON "public"."tracker_state_day" FOR SELECT USING (("user_id" = "auth"."uid"()));
CREATE POLICY "tracker_state_day_update_own" ON "public"."tracker_state_day" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));
ALTER TABLE "public"."tracker_state_entry" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tracker_state_entry_delete_own" ON "public"."tracker_state_entry" FOR DELETE USING (("user_id" = "auth"."uid"()));
CREATE POLICY "tracker_state_entry_insert_own" ON "public"."tracker_state_entry" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));
CREATE POLICY "tracker_state_entry_select_own" ON "public"."tracker_state_entry" FOR SELECT USING (("user_id" = "auth"."uid"()));
CREATE POLICY "tracker_state_entry_update_own" ON "public"."tracker_state_entry" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));
ALTER TABLE "public"."user_profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."value_ratings_weekly" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "value_ratings_weekly_delete_own" ON "public"."value_ratings_weekly" FOR DELETE USING (("auth"."uid"() = "user_id"));
CREATE POLICY "value_ratings_weekly_insert_own" ON "public"."value_ratings_weekly" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));
CREATE POLICY "value_ratings_weekly_select_own" ON "public"."value_ratings_weekly" FOR SELECT USING (("auth"."uid"() = "user_id"));
CREATE POLICY "value_ratings_weekly_update_own" ON "public"."value_ratings_weekly" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));
ALTER TABLE "public"."values" ENABLE ROW LEVEL SECURITY;
CREATE PUBLICATION "powersync" FOR ALL TABLES WITH (publish = 'insert, update, delete, truncate');
ALTER PUBLICATION "powersync" OWNER TO "postgres";
ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";
GRANT ALL ON FUNCTION "public"."_is_privileged_delete"() TO "anon";
GRANT ALL ON FUNCTION "public"."_is_privileged_delete"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."_is_privileged_delete"() TO "service_role";
GRANT ALL ON FUNCTION "public"."_legacy_values_read_only"() TO "anon";
GRANT ALL ON FUNCTION "public"."_legacy_values_read_only"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."_legacy_values_read_only"() TO "service_role";
GRANT ALL ON FUNCTION "public"."_set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."_set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."_set_updated_at"() TO "service_role";
GRANT ALL ON FUNCTION "public"."cleanup_old_analytics_insights"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_old_analytics_insights"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_old_analytics_insights"() TO "service_role";
GRANT ALL ON FUNCTION "public"."create_default_attention_rules"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_default_attention_rules"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_default_attention_rules"("p_user_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."enqueue_due_screen_notifications"("max_rows" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."enqueue_due_screen_notifications"("max_rows" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."enqueue_due_screen_notifications"("max_rows" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."generate_productivity_percentile_insight"("p_user_id" "uuid", "p_percentile" numeric, "p_period_start" "date", "p_period_end" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."generate_productivity_percentile_insight"("p_user_id" "uuid", "p_percentile" numeric, "p_period_start" "date", "p_period_end" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_productivity_percentile_insight"("p_user_id" "uuid", "p_percentile" numeric, "p_period_start" "date", "p_period_end" "date") TO "service_role";
GRANT ALL ON FUNCTION "public"."get_significant_correlations"("p_user_id" "uuid", "p_min_coefficient" numeric, "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_significant_correlations"("p_user_id" "uuid", "p_min_coefficient" numeric, "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_significant_correlations"("p_user_id" "uuid", "p_min_coefficient" numeric, "p_limit" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."hypopg"(OUT "indexname" "text", OUT "indexrelid" "oid", OUT "indrelid" "oid", OUT "innatts" integer, OUT "indisunique" boolean, OUT "indkey" "int2vector", OUT "indcollation" "oidvector", OUT "indclass" "oidvector", OUT "indoption" "oidvector", OUT "indexprs" "pg_node_tree", OUT "indpred" "pg_node_tree", OUT "amid" "oid") TO "postgres";
GRANT ALL ON FUNCTION "public"."hypopg"(OUT "indexname" "text", OUT "indexrelid" "oid", OUT "indrelid" "oid", OUT "innatts" integer, OUT "indisunique" boolean, OUT "indkey" "int2vector", OUT "indcollation" "oidvector", OUT "indclass" "oidvector", OUT "indoption" "oidvector", OUT "indexprs" "pg_node_tree", OUT "indpred" "pg_node_tree", OUT "amid" "oid") TO "anon";
GRANT ALL ON FUNCTION "public"."hypopg"(OUT "indexname" "text", OUT "indexrelid" "oid", OUT "indrelid" "oid", OUT "innatts" integer, OUT "indisunique" boolean, OUT "indkey" "int2vector", OUT "indcollation" "oidvector", OUT "indclass" "oidvector", OUT "indoption" "oidvector", OUT "indexprs" "pg_node_tree", OUT "indpred" "pg_node_tree", OUT "amid" "oid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hypopg"(OUT "indexname" "text", OUT "indexrelid" "oid", OUT "indrelid" "oid", OUT "innatts" integer, OUT "indisunique" boolean, OUT "indkey" "int2vector", OUT "indcollation" "oidvector", OUT "indclass" "oidvector", OUT "indoption" "oidvector", OUT "indexprs" "pg_node_tree", OUT "indpred" "pg_node_tree", OUT "amid" "oid") TO "service_role";
GRANT ALL ON FUNCTION "public"."hypopg_create_index"("sql_order" "text", OUT "indexrelid" "oid", OUT "indexname" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."hypopg_create_index"("sql_order" "text", OUT "indexrelid" "oid", OUT "indexname" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."hypopg_create_index"("sql_order" "text", OUT "indexrelid" "oid", OUT "indexname" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hypopg_create_index"("sql_order" "text", OUT "indexrelid" "oid", OUT "indexname" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."hypopg_drop_index"("indexid" "oid") TO "postgres";
GRANT ALL ON FUNCTION "public"."hypopg_drop_index"("indexid" "oid") TO "anon";
GRANT ALL ON FUNCTION "public"."hypopg_drop_index"("indexid" "oid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hypopg_drop_index"("indexid" "oid") TO "service_role";
GRANT ALL ON FUNCTION "public"."hypopg_get_indexdef"("indexid" "oid") TO "postgres";
GRANT ALL ON FUNCTION "public"."hypopg_get_indexdef"("indexid" "oid") TO "anon";
GRANT ALL ON FUNCTION "public"."hypopg_get_indexdef"("indexid" "oid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hypopg_get_indexdef"("indexid" "oid") TO "service_role";
GRANT ALL ON FUNCTION "public"."hypopg_hidden_indexes"() TO "postgres";
GRANT ALL ON FUNCTION "public"."hypopg_hidden_indexes"() TO "anon";
GRANT ALL ON FUNCTION "public"."hypopg_hidden_indexes"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."hypopg_hidden_indexes"() TO "service_role";
GRANT ALL ON FUNCTION "public"."hypopg_hide_index"("indexid" "oid") TO "postgres";
GRANT ALL ON FUNCTION "public"."hypopg_hide_index"("indexid" "oid") TO "anon";
GRANT ALL ON FUNCTION "public"."hypopg_hide_index"("indexid" "oid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hypopg_hide_index"("indexid" "oid") TO "service_role";
GRANT ALL ON FUNCTION "public"."hypopg_relation_size"("indexid" "oid") TO "postgres";
GRANT ALL ON FUNCTION "public"."hypopg_relation_size"("indexid" "oid") TO "anon";
GRANT ALL ON FUNCTION "public"."hypopg_relation_size"("indexid" "oid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hypopg_relation_size"("indexid" "oid") TO "service_role";
GRANT ALL ON FUNCTION "public"."hypopg_reset"() TO "postgres";
GRANT ALL ON FUNCTION "public"."hypopg_reset"() TO "anon";
GRANT ALL ON FUNCTION "public"."hypopg_reset"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."hypopg_reset"() TO "service_role";
GRANT ALL ON FUNCTION "public"."hypopg_reset_index"() TO "postgres";
GRANT ALL ON FUNCTION "public"."hypopg_reset_index"() TO "anon";
GRANT ALL ON FUNCTION "public"."hypopg_reset_index"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."hypopg_reset_index"() TO "service_role";
GRANT ALL ON FUNCTION "public"."hypopg_unhide_all_indexes"() TO "postgres";
GRANT ALL ON FUNCTION "public"."hypopg_unhide_all_indexes"() TO "anon";
GRANT ALL ON FUNCTION "public"."hypopg_unhide_all_indexes"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."hypopg_unhide_all_indexes"() TO "service_role";
GRANT ALL ON FUNCTION "public"."hypopg_unhide_index"("indexid" "oid") TO "postgres";
GRANT ALL ON FUNCTION "public"."hypopg_unhide_index"("indexid" "oid") TO "anon";
GRANT ALL ON FUNCTION "public"."hypopg_unhide_index"("indexid" "oid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hypopg_unhide_index"("indexid" "oid") TO "service_role";
GRANT ALL ON FUNCTION "public"."index_advisor"("query" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."index_advisor"("query" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."index_advisor"("query" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."index_advisor"("query" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."on_user_created"() TO "anon";
GRANT ALL ON FUNCTION "public"."on_user_created"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."on_user_created"() TO "service_role";
GRANT ALL ON FUNCTION "public"."prevent_delete_system_screens"() TO "anon";
GRANT ALL ON FUNCTION "public"."prevent_delete_system_screens"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."prevent_delete_system_screens"() TO "service_role";
GRANT ALL ON FUNCTION "public"."project_next_actions_task_project_guard"() TO "anon";
GRANT ALL ON FUNCTION "public"."project_next_actions_task_project_guard"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."project_next_actions_task_project_guard"() TO "service_role";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";
GRANT ALL ON FUNCTION "public"."screen_definitions_sync_trigger_fields"() TO "anon";
GRANT ALL ON FUNCTION "public"."screen_definitions_sync_trigger_fields"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."screen_definitions_sync_trigger_fields"() TO "service_role";
GRANT ALL ON FUNCTION "public"."set_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_timestamp"() TO "service_role";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";
GRANT ALL ON FUNCTION "public"."tasks_enforce_id_and_timestamps"() TO "anon";
GRANT ALL ON FUNCTION "public"."tasks_enforce_id_and_timestamps"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."tasks_enforce_id_and_timestamps"() TO "service_role";
GRANT ALL ON FUNCTION "public"."tg_set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."tg_set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."tg_set_updated_at"() TO "service_role";
GRANT ALL ON FUNCTION "public"."trigger_set_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_set_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_set_timestamp"() TO "service_role";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";
GRANT ALL ON TABLE "public"."analytics_correlations" TO "anon";
GRANT ALL ON TABLE "public"."analytics_correlations" TO "authenticated";
GRANT ALL ON TABLE "public"."analytics_correlations" TO "service_role";
GRANT SELECT ON TABLE "public"."analytics_correlations" TO "powersync_role";
GRANT ALL ON TABLE "public"."analytics_insights" TO "anon";
GRANT ALL ON TABLE "public"."analytics_insights" TO "authenticated";
GRANT ALL ON TABLE "public"."analytics_insights" TO "service_role";
GRANT SELECT ON TABLE "public"."analytics_insights" TO "powersync_role";
GRANT ALL ON TABLE "public"."analytics_snapshots" TO "anon";
GRANT ALL ON TABLE "public"."analytics_snapshots" TO "authenticated";
GRANT ALL ON TABLE "public"."analytics_snapshots" TO "service_role";
GRANT SELECT ON TABLE "public"."analytics_snapshots" TO "powersync_role";
GRANT ALL ON TABLE "public"."attention_resolutions" TO "anon";
GRANT ALL ON TABLE "public"."attention_resolutions" TO "authenticated";
GRANT ALL ON TABLE "public"."attention_resolutions" TO "service_role";
GRANT SELECT ON TABLE "public"."attention_resolutions" TO "powersync_role";
GRANT ALL ON TABLE "public"."attention_rule_runtime_state" TO "anon";
GRANT ALL ON TABLE "public"."attention_rule_runtime_state" TO "authenticated";
GRANT ALL ON TABLE "public"."attention_rule_runtime_state" TO "service_role";
GRANT SELECT ON TABLE "public"."attention_rule_runtime_state" TO "powersync_role";
GRANT ALL ON TABLE "public"."attention_rules" TO "anon";
GRANT ALL ON TABLE "public"."attention_rules" TO "authenticated";
GRANT ALL ON TABLE "public"."attention_rules" TO "service_role";
GRANT SELECT ON TABLE "public"."attention_rules" TO "powersync_role";
GRANT ALL ON TABLE "public"."hypopg_list_indexes" TO "postgres";
GRANT ALL ON TABLE "public"."hypopg_list_indexes" TO "anon";
GRANT ALL ON TABLE "public"."hypopg_list_indexes" TO "authenticated";
GRANT ALL ON TABLE "public"."hypopg_list_indexes" TO "service_role";
GRANT ALL ON TABLE "public"."hypopg_hidden_indexes" TO "postgres";
GRANT ALL ON TABLE "public"."hypopg_hidden_indexes" TO "anon";
GRANT ALL ON TABLE "public"."hypopg_hidden_indexes" TO "authenticated";
GRANT ALL ON TABLE "public"."hypopg_hidden_indexes" TO "service_role";
GRANT ALL ON TABLE "public"."journal_entries" TO "anon";
GRANT ALL ON TABLE "public"."journal_entries" TO "authenticated";
GRANT ALL ON TABLE "public"."journal_entries" TO "service_role";
GRANT SELECT ON TABLE "public"."journal_entries" TO "powersync_role";
GRANT ALL ON TABLE "public"."my_day_days" TO "anon";
GRANT ALL ON TABLE "public"."my_day_days" TO "authenticated";
GRANT ALL ON TABLE "public"."my_day_days" TO "service_role";
GRANT SELECT ON TABLE "public"."my_day_days" TO "powersync_role";
GRANT ALL ON TABLE "public"."my_day_picks" TO "anon";
GRANT ALL ON TABLE "public"."my_day_picks" TO "authenticated";
GRANT ALL ON TABLE "public"."my_day_picks" TO "service_role";
GRANT SELECT ON TABLE "public"."my_day_picks" TO "powersync_role";
GRANT ALL ON TABLE "public"."pending_notifications" TO "anon";
GRANT ALL ON TABLE "public"."pending_notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."pending_notifications" TO "service_role";
GRANT SELECT ON TABLE "public"."pending_notifications" TO "powersync_role";
GRANT ALL ON TABLE "public"."project_anchor_state" TO "anon";
GRANT ALL ON TABLE "public"."project_anchor_state" TO "authenticated";
GRANT ALL ON TABLE "public"."project_anchor_state" TO "service_role";
GRANT SELECT ON TABLE "public"."project_anchor_state" TO "powersync_role";
GRANT ALL ON TABLE "public"."project_completion_history" TO "anon";
GRANT ALL ON TABLE "public"."project_completion_history" TO "authenticated";
GRANT ALL ON TABLE "public"."project_completion_history" TO "service_role";
GRANT SELECT ON TABLE "public"."project_completion_history" TO "powersync_role";
GRANT ALL ON TABLE "public"."project_next_actions" TO "anon";
GRANT ALL ON TABLE "public"."project_next_actions" TO "authenticated";
GRANT ALL ON TABLE "public"."project_next_actions" TO "service_role";
GRANT SELECT ON TABLE "public"."project_next_actions" TO "powersync_role";
GRANT ALL ON TABLE "public"."project_recurrence_exceptions" TO "anon";
GRANT ALL ON TABLE "public"."project_recurrence_exceptions" TO "authenticated";
GRANT ALL ON TABLE "public"."project_recurrence_exceptions" TO "service_role";
GRANT SELECT ON TABLE "public"."project_recurrence_exceptions" TO "powersync_role";
GRANT ALL ON TABLE "public"."projects" TO "anon";
GRANT ALL ON TABLE "public"."projects" TO "authenticated";
GRANT ALL ON TABLE "public"."projects" TO "service_role";
GRANT SELECT ON TABLE "public"."projects" TO "powersync_role";
GRANT ALL ON TABLE "public"."routine_completions" TO "anon";
GRANT ALL ON TABLE "public"."routine_completions" TO "authenticated";
GRANT ALL ON TABLE "public"."routine_completions" TO "service_role";
GRANT SELECT ON TABLE "public"."routine_completions" TO "powersync_role";
GRANT ALL ON TABLE "public"."routine_skips" TO "anon";
GRANT ALL ON TABLE "public"."routine_skips" TO "authenticated";
GRANT ALL ON TABLE "public"."routine_skips" TO "service_role";
GRANT SELECT ON TABLE "public"."routine_skips" TO "powersync_role";
GRANT ALL ON TABLE "public"."routines" TO "anon";
GRANT ALL ON TABLE "public"."routines" TO "authenticated";
GRANT ALL ON TABLE "public"."routines" TO "service_role";
GRANT SELECT ON TABLE "public"."routines" TO "powersync_role";
GRANT ALL ON TABLE "public"."task_completion_history" TO "anon";
GRANT ALL ON TABLE "public"."task_completion_history" TO "authenticated";
GRANT ALL ON TABLE "public"."task_completion_history" TO "service_role";
GRANT SELECT ON TABLE "public"."task_completion_history" TO "powersync_role";
GRANT ALL ON TABLE "public"."task_recurrence_exceptions" TO "anon";
GRANT ALL ON TABLE "public"."task_recurrence_exceptions" TO "authenticated";
GRANT ALL ON TABLE "public"."task_recurrence_exceptions" TO "service_role";
GRANT SELECT ON TABLE "public"."task_recurrence_exceptions" TO "powersync_role";
GRANT ALL ON TABLE "public"."task_snooze_events" TO "anon";
GRANT ALL ON TABLE "public"."task_snooze_events" TO "authenticated";
GRANT ALL ON TABLE "public"."task_snooze_events" TO "service_role";
GRANT SELECT ON TABLE "public"."task_snooze_events" TO "powersync_role";
GRANT ALL ON TABLE "public"."tasks" TO "anon";
GRANT ALL ON TABLE "public"."tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."tasks" TO "service_role";
GRANT SELECT ON TABLE "public"."tasks" TO "powersync_role";
GRANT ALL ON TABLE "public"."tracker_definition_choices" TO "anon";
GRANT ALL ON TABLE "public"."tracker_definition_choices" TO "authenticated";
GRANT ALL ON TABLE "public"."tracker_definition_choices" TO "service_role";
GRANT SELECT ON TABLE "public"."tracker_definition_choices" TO "powersync_role";
GRANT ALL ON TABLE "public"."tracker_definitions" TO "anon";
GRANT ALL ON TABLE "public"."tracker_definitions" TO "authenticated";
GRANT ALL ON TABLE "public"."tracker_definitions" TO "service_role";
GRANT SELECT ON TABLE "public"."tracker_definitions" TO "powersync_role";
GRANT ALL ON TABLE "public"."tracker_events" TO "anon";
GRANT ALL ON TABLE "public"."tracker_events" TO "authenticated";
GRANT ALL ON TABLE "public"."tracker_events" TO "service_role";
GRANT SELECT ON TABLE "public"."tracker_events" TO "powersync_role";
GRANT ALL ON TABLE "public"."tracker_groups" TO "anon";
GRANT ALL ON TABLE "public"."tracker_groups" TO "authenticated";
GRANT ALL ON TABLE "public"."tracker_groups" TO "service_role";
GRANT SELECT ON TABLE "public"."tracker_groups" TO "powersync_role";
GRANT ALL ON TABLE "public"."tracker_preferences" TO "anon";
GRANT ALL ON TABLE "public"."tracker_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."tracker_preferences" TO "service_role";
GRANT SELECT ON TABLE "public"."tracker_preferences" TO "powersync_role";
GRANT ALL ON TABLE "public"."tracker_state_day" TO "anon";
GRANT ALL ON TABLE "public"."tracker_state_day" TO "authenticated";
GRANT ALL ON TABLE "public"."tracker_state_day" TO "service_role";
GRANT SELECT ON TABLE "public"."tracker_state_day" TO "powersync_role";
GRANT ALL ON TABLE "public"."tracker_state_entry" TO "anon";
GRANT ALL ON TABLE "public"."tracker_state_entry" TO "authenticated";
GRANT ALL ON TABLE "public"."tracker_state_entry" TO "service_role";
GRANT SELECT ON TABLE "public"."tracker_state_entry" TO "powersync_role";
GRANT ALL ON TABLE "public"."user_profiles" TO "anon";
GRANT ALL ON TABLE "public"."user_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_profiles" TO "service_role";
GRANT SELECT ON TABLE "public"."user_profiles" TO "powersync_role";
GRANT ALL ON TABLE "public"."value_ratings_weekly" TO "anon";
GRANT ALL ON TABLE "public"."value_ratings_weekly" TO "authenticated";
GRANT ALL ON TABLE "public"."value_ratings_weekly" TO "service_role";
GRANT SELECT ON TABLE "public"."value_ratings_weekly" TO "powersync_role";
GRANT ALL ON TABLE "public"."values" TO "anon";
GRANT ALL ON TABLE "public"."values" TO "authenticated";
GRANT ALL ON TABLE "public"."values" TO "service_role";
GRANT SELECT ON TABLE "public"."values" TO "powersync_role";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT ON TABLES TO "powersync_role";
