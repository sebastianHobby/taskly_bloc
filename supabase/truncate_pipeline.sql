-- Fast deterministic cleanup for local E2E / pipeline tests.
--
-- Purpose: reset ONLY application tables that pipeline tests touch,
-- without re-applying migrations or seed.
--
-- Safe to run repeatedly.

DO $$
DECLARE
  names text[] := ARRAY[
    'tasks',
    'projects',
    'values',
    'user_profiles'
  ];
  name text;
  trunc_list text := '';
BEGIN
  FOREACH name IN ARRAY names LOOP
    IF to_regclass('public.' || name) IS NOT NULL THEN
      trunc_list := trunc_list ||
          CASE WHEN trunc_list = '' THEN '' ELSE ', ' END ||
          format('public.%I', name);
    END IF;
  END LOOP;

  IF trunc_list = '' THEN
    RAISE NOTICE 'No pipeline tables found to truncate.';
    RETURN;
  END IF;

  EXECUTE 'TRUNCATE TABLE ' || trunc_list || ' RESTART IDENTITY CASCADE';
END $$;
