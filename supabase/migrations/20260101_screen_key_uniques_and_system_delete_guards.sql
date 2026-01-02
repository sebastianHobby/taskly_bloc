-- Migration: screen_id -> screen_key + idempotent upsert constraints + system delete guards
-- Date: 2026-01-01
--
-- Goals
-- 1) Rename screen_definitions.screen_id to screen_key (stable business key)
-- 2) Add unique indexes used by client/server upserts (on_conflict targets)
-- 3) Prevent deletion of system screens / system labels by normal clients
--    while still allowing cleanup when deleting a user (service_role/admin)

BEGIN;

-- ---------------------------------------------------------------------------
-- 1) Rename screen_id -> screen_key
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'screen_definitions'
      AND column_name = 'screen_id'
  ) AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'screen_definitions'
      AND column_name = 'screen_key'
  ) THEN
    ALTER TABLE public.screen_definitions RENAME COLUMN screen_id TO screen_key;
  END IF;
END $$;

COMMENT ON COLUMN public.screen_definitions.screen_key IS
  'Stable per-user screen identifier (system: inbox/today/...; user-created: uuid string). Used for idempotent upserts and routing.';

-- ---------------------------------------------------------------------------
-- 2) Unique indexes for idempotent upserts
--    These enable PostgREST upsert with on_conflict targets.
-- ---------------------------------------------------------------------------

-- screen_definitions: one screen per user per screen_key
DROP INDEX IF EXISTS public.ux_screen_definitions_user_id_screen_id;
DROP INDEX IF EXISTS public.ux_screen_definitions_user_id_screen_key;
CREATE UNIQUE INDEX ux_screen_definitions_user_id_screen_key
  ON public.screen_definitions (user_id, screen_key);

-- allocation_preferences: one row per user
DROP INDEX IF EXISTS public.ux_allocation_preferences_user_id;
CREATE UNIQUE INDEX ux_allocation_preferences_user_id
  ON public.allocation_preferences (user_id);

-- priority_rankings: one ranking per user per ranking_type
DROP INDEX IF EXISTS public.ux_priority_rankings_user_id_ranking_type;
CREATE UNIQUE INDEX ux_priority_rankings_user_id_ranking_type
  ON public.priority_rankings (user_id, ranking_type);

-- labels: ensure at most one system label per user per system_label_type
-- (partial unique index only applies to system labels)
DROP INDEX IF EXISTS public.ux_labels_user_id_system_label_type;
CREATE UNIQUE INDEX ux_labels_user_id_system_label_type
  ON public.labels (user_id, system_label_type)
  WHERE is_system_label = true;

-- ---------------------------------------------------------------------------
-- 3) Delete guards for system entities
--    We use triggers so we don't depend on your RLS/policy setup.
--    Allow deletes for service_role/admin roles (e.g., user deletion cascades).
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public._is_privileged_delete()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT
    coalesce(auth.role(), '') IN ('service_role')
    OR current_user IN ('postgres', 'supabase_admin');
$$;

-- Prevent deleting system screens (unless privileged)
CREATE OR REPLACE FUNCTION public.prevent_delete_system_screens()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF (OLD.is_system = true OR OLD.is_system = 1) AND NOT public._is_privileged_delete() THEN
    RAISE EXCEPTION 'Cannot delete system screen (screen_key=%).', OLD.screen_key
      USING ERRCODE = '42501';
  END IF;

  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_delete_system_screens ON public.screen_definitions;
CREATE TRIGGER trg_prevent_delete_system_screens
BEFORE DELETE ON public.screen_definitions
FOR EACH ROW
EXECUTE FUNCTION public.prevent_delete_system_screens();

-- Prevent deleting system labels (unless privileged)
CREATE OR REPLACE FUNCTION public.prevent_delete_system_labels()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF (OLD.is_system_label = true OR OLD.is_system_label = 1) AND NOT public._is_privileged_delete() THEN
    RAISE EXCEPTION 'Cannot delete system label (system_label_type=%).', OLD.system_label_type
      USING ERRCODE = '42501';
  END IF;

  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_delete_system_labels ON public.labels;
CREATE TRIGGER trg_prevent_delete_system_labels
BEFORE DELETE ON public.labels
FOR EACH ROW
EXECUTE FUNCTION public.prevent_delete_system_labels();

COMMIT;

-- ---------------------------------------------------------------------------
-- Notes for client/upsert usage
-- - screen_definitions: upsert with on_conflict=user_id,screen_key
-- - labels: upsert system labels with on_conflict=user_id,system_label_type and is_system_label=true
-- - allocation_preferences: upsert with on_conflict=user_id
-- - priority_rankings: upsert with on_conflict=user_id,ranking_type
-- ---------------------------------------------------------------------------
