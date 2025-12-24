-- =============================================================================
-- REPEATING TASKS FEATURE - POSTGRESQL MIGRATION
-- =============================================================================
-- This script migrates the PostgreSQL/Supabase backend from current state to
-- the new repeating tasks schema with separate tables (no polymorphism).
--
-- Run this in your Supabase SQL Editor or psql.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- STEP 1: Add series_ended column to existing tables
-- -----------------------------------------------------------------------------

-- Add series_ended to tasks table
ALTER TABLE public.tasks
ADD COLUMN IF NOT EXISTS series_ended BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN public.tasks.series_ended IS 
  'When true, stops generating future occurrences for repeating tasks';

-- Add series_ended to projects table
ALTER TABLE public.projects
ADD COLUMN IF NOT EXISTS series_ended BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN public.projects.series_ended IS 
  'When true, stops generating future occurrences for repeating projects';


-- -----------------------------------------------------------------------------
-- STEP 2: Create task_completion_history table
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.task_completion_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  occurrence_date DATE,  -- NULL for non-repeating tasks
  original_occurrence_date DATE,  -- Original RRULE date (for on-time tracking)
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  notes TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- One completion per occurrence per task
  UNIQUE (task_id, occurrence_date)
);

-- Add table comment
COMMENT ON TABLE public.task_completion_history IS 
  'Tracks completion of task occurrences (both repeating and non-repeating)';

COMMENT ON COLUMN public.task_completion_history.occurrence_date IS 
  'The scheduled date of the occurrence. NULL for non-repeating tasks.';

COMMENT ON COLUMN public.task_completion_history.original_occurrence_date IS 
  'Original RRULE-generated date. For rescheduled tasks, differs from occurrence_date. Used for on-time reporting.';

-- Indexes for task_completion_history
CREATE INDEX IF NOT EXISTS idx_task_completion_task 
  ON public.task_completion_history(task_id, occurrence_date);

CREATE INDEX IF NOT EXISTS idx_task_completion_date 
  ON public.task_completion_history(completed_at);

CREATE INDEX IF NOT EXISTS idx_task_completion_original_date 
  ON public.task_completion_history(task_id, original_occurrence_date);

CREATE INDEX IF NOT EXISTS idx_task_completion_user 
  ON public.task_completion_history(user_id);


-- -----------------------------------------------------------------------------
-- STEP 3: Create project_completion_history table
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.project_completion_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  occurrence_date DATE,  -- NULL for non-repeating projects
  original_occurrence_date DATE,  -- Original RRULE date (for on-time tracking)
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  notes TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- One completion per occurrence per project
  UNIQUE (project_id, occurrence_date)
);

COMMENT ON TABLE public.project_completion_history IS 
  'Tracks completion of project occurrences (both repeating and non-repeating)';

-- Indexes for project_completion_history
CREATE INDEX IF NOT EXISTS idx_project_completion_project 
  ON public.project_completion_history(project_id, occurrence_date);

CREATE INDEX IF NOT EXISTS idx_project_completion_date 
  ON public.project_completion_history(completed_at);

CREATE INDEX IF NOT EXISTS idx_project_completion_original_date 
  ON public.project_completion_history(project_id, original_occurrence_date);

CREATE INDEX IF NOT EXISTS idx_project_completion_user 
  ON public.project_completion_history(user_id);


-- -----------------------------------------------------------------------------
-- STEP 4: Create task_recurrence_exceptions table
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.task_recurrence_exceptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  original_date DATE NOT NULL,  -- The RRULE date being modified
  exception_type TEXT NOT NULL CHECK (exception_type IN ('skip', 'reschedule')),
  new_date DATE,  -- Target date for reschedule (NULL if skip)
  new_deadline TIMESTAMPTZ,  -- Override deadline (NULL = inherit from task)
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,  -- Denormalized for sync
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- One exception per original date per task
  UNIQUE (task_id, original_date)
);

COMMENT ON TABLE public.task_recurrence_exceptions IS 
  'Modifications to individual task occurrences (skip or reschedule)';

COMMENT ON COLUMN public.task_recurrence_exceptions.exception_type IS 
  'skip = remove occurrence, reschedule = move to new_date';

COMMENT ON COLUMN public.task_recurrence_exceptions.new_date IS 
  'Target date for reschedule. NULL if skip.';

COMMENT ON COLUMN public.task_recurrence_exceptions.user_id IS 
  'Denormalized user_id for simpler PowerSync sync rules';

-- Indexes for task_recurrence_exceptions
CREATE INDEX IF NOT EXISTS idx_task_exception_task 
  ON public.task_recurrence_exceptions(task_id, original_date);

CREATE INDEX IF NOT EXISTS idx_task_exception_new_date 
  ON public.task_recurrence_exceptions(task_id, new_date)
  WHERE new_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_task_exception_user 
  ON public.task_recurrence_exceptions(user_id);


-- -----------------------------------------------------------------------------
-- STEP 5: Create project_recurrence_exceptions table
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.project_recurrence_exceptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  original_date DATE NOT NULL,  -- The RRULE date being modified
  exception_type TEXT NOT NULL CHECK (exception_type IN ('skip', 'reschedule')),
  new_date DATE,  -- Target date for reschedule (NULL if skip)
  new_deadline TIMESTAMPTZ,  -- Override deadline (NULL = inherit from project)
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,  -- Denormalized for sync
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- One exception per original date per project
  UNIQUE (project_id, original_date)
);

COMMENT ON TABLE public.project_recurrence_exceptions IS 
  'Modifications to individual project occurrences (skip or reschedule)';

COMMENT ON COLUMN public.project_recurrence_exceptions.user_id IS 
  'Denormalized user_id for simpler PowerSync sync rules';

-- Indexes for project_recurrence_exceptions
CREATE INDEX IF NOT EXISTS idx_project_exception_project 
  ON public.project_recurrence_exceptions(project_id, original_date);

CREATE INDEX IF NOT EXISTS idx_project_exception_new_date 
  ON public.project_recurrence_exceptions(project_id, new_date)
  WHERE new_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_project_exception_user 
  ON public.project_recurrence_exceptions(user_id);


-- -----------------------------------------------------------------------------
-- STEP 6: Create updated_at triggers
-- -----------------------------------------------------------------------------

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for task_completion_history
DROP TRIGGER IF EXISTS set_task_completion_updated_at ON public.task_completion_history;
CREATE TRIGGER set_task_completion_updated_at
  BEFORE UPDATE ON public.task_completion_history
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Trigger for project_completion_history
DROP TRIGGER IF EXISTS set_project_completion_updated_at ON public.project_completion_history;
CREATE TRIGGER set_project_completion_updated_at
  BEFORE UPDATE ON public.project_completion_history
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Trigger for task_recurrence_exceptions
DROP TRIGGER IF EXISTS set_task_exception_updated_at ON public.task_recurrence_exceptions;
CREATE TRIGGER set_task_exception_updated_at
  BEFORE UPDATE ON public.task_recurrence_exceptions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Trigger for project_recurrence_exceptions
DROP TRIGGER IF EXISTS set_project_exception_updated_at ON public.project_recurrence_exceptions;
CREATE TRIGGER set_project_exception_updated_at
  BEFORE UPDATE ON public.project_recurrence_exceptions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();


-- -----------------------------------------------------------------------------
-- STEP 7: Row Level Security (RLS)
-- -----------------------------------------------------------------------------

-- Enable RLS on all new tables
ALTER TABLE public.task_completion_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_completion_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_recurrence_exceptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_recurrence_exceptions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can manage completion history for their own tasks
CREATE POLICY "Users can view their task completions"
  ON public.task_completion_history
  FOR SELECT
  USING (
    task_id IN (SELECT id FROM public.tasks WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can insert their task completions"
  ON public.task_completion_history
  FOR INSERT
  WITH CHECK (
    task_id IN (SELECT id FROM public.tasks WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can update their task completions"
  ON public.task_completion_history
  FOR UPDATE
  USING (
    task_id IN (SELECT id FROM public.tasks WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can delete their task completions"
  ON public.task_completion_history
  FOR DELETE
  USING (
    task_id IN (SELECT id FROM public.tasks WHERE user_id = auth.uid())
  );

-- Policy: Users can manage completion history for their own projects
CREATE POLICY "Users can view their project completions"
  ON public.project_completion_history
  FOR SELECT
  USING (
    project_id IN (SELECT id FROM public.projects WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can insert their project completions"
  ON public.project_completion_history
  FOR INSERT
  WITH CHECK (
    project_id IN (SELECT id FROM public.projects WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can update their project completions"
  ON public.project_completion_history
  FOR UPDATE
  USING (
    project_id IN (SELECT id FROM public.projects WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can delete their project completions"
  ON public.project_completion_history
  FOR DELETE
  USING (
    project_id IN (SELECT id FROM public.projects WHERE user_id = auth.uid())
  );

-- Policy: Users can manage recurrence exceptions for their own tasks
CREATE POLICY "Users can view their task exceptions"
  ON public.task_recurrence_exceptions
  FOR SELECT
  USING (
    task_id IN (SELECT id FROM public.tasks WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can insert their task exceptions"
  ON public.task_recurrence_exceptions
  FOR INSERT
  WITH CHECK (
    task_id IN (SELECT id FROM public.tasks WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can update their task exceptions"
  ON public.task_recurrence_exceptions
  FOR UPDATE
  USING (
    task_id IN (SELECT id FROM public.tasks WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can delete their task exceptions"
  ON public.task_recurrence_exceptions
  FOR DELETE
  USING (
    task_id IN (SELECT id FROM public.tasks WHERE user_id = auth.uid())
  );

-- Policy: Users can manage recurrence exceptions for their own projects
CREATE POLICY "Users can view their project exceptions"
  ON public.project_recurrence_exceptions
  FOR SELECT
  USING (
    project_id IN (SELECT id FROM public.projects WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can insert their project exceptions"
  ON public.project_recurrence_exceptions
  FOR INSERT
  WITH CHECK (
    project_id IN (SELECT id FROM public.projects WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can update their project exceptions"
  ON public.project_recurrence_exceptions
  FOR UPDATE
  USING (
    project_id IN (SELECT id FROM public.projects WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can delete their project exceptions"
  ON public.project_recurrence_exceptions
  FOR DELETE
  USING (
    project_id IN (SELECT id FROM public.projects WHERE user_id = auth.uid())
  );


-- -----------------------------------------------------------------------------
-- STEP 8: Grant permissions (for Supabase service role)
-- -----------------------------------------------------------------------------

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.task_completion_history TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.project_completion_history TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.task_recurrence_exceptions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.project_recurrence_exceptions TO authenticated;

-- Grant usage on sequences (if any)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;


-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================
-- Run these after migration to verify the schema was created correctly:

-- Check new columns exist
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'tasks' AND column_name = 'series_ended';

-- Check new tables exist
-- SELECT table_name 
-- FROM information_schema.tables 
-- WHERE table_schema = 'public' 
--   AND table_name IN (
--     'task_completion_history', 
--     'project_completion_history',
--     'task_recurrence_exceptions',
--     'project_recurrence_exceptions'
--   );

-- Check indexes
-- SELECT indexname, tablename 
-- FROM pg_indexes 
-- WHERE schemaname = 'public' 
--   AND tablename LIKE '%completion%' OR tablename LIKE '%exception%';

-- Check RLS policies
-- SELECT tablename, policyname, cmd 
-- FROM pg_policies 
-- WHERE schemaname = 'public'
--   AND tablename IN (
--     'task_completion_history', 
--     'project_completion_history',
--     'task_recurrence_exceptions',
--     'project_recurrence_exceptions'
--   );


-- =============================================================================
-- ROLLBACK SCRIPT (if needed)
-- =============================================================================
-- Uncomment and run if you need to rollback this migration:

-- DROP TABLE IF EXISTS public.project_recurrence_exceptions CASCADE;
-- DROP TABLE IF EXISTS public.task_recurrence_exceptions CASCADE;
-- DROP TABLE IF EXISTS public.project_completion_history CASCADE;
-- DROP TABLE IF EXISTS public.task_completion_history CASCADE;
-- ALTER TABLE public.tasks DROP COLUMN IF EXISTS series_ended;
-- ALTER TABLE public.projects DROP COLUMN IF EXISTS series_ended;
