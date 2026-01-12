-- Phase 6: Workflow table cleanup
--
-- This migration is intentionally idempotent and safe to re-run.
-- Coordinate application with your Supabase/Postgres admin.

DROP TABLE IF EXISTS workflow_step_executions CASCADE;
DROP TABLE IF EXISTS workflow_steps CASCADE;
DROP TABLE IF EXISTS workflow_definitions CASCADE;
