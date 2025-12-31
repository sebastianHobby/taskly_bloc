-- Migration: Remove Next Action fields from tasks table
-- These fields are being deprecated in favor of a separate next actions system
-- Run this after backing up your data

BEGIN;

-- Drop the next action columns from tasks table
ALTER TABLE public.tasks 
  DROP COLUMN IF EXISTS is_next_action,
  DROP COLUMN IF EXISTS next_action_priority,
  DROP COLUMN IF EXISTS marked_next_action_at,
  DROP COLUMN IF EXISTS next_action_notes;

COMMIT;
