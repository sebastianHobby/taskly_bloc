-- PowerSync requires a logical replication publication named `powersync`.
--
-- This is safe to run multiple times.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication
    WHERE pubname = 'powersync'
  ) THEN
    CREATE PUBLICATION powersync FOR ALL TABLES;
  END IF;
END
$$;
