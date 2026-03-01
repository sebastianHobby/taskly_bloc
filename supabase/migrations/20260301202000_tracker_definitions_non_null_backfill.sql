-- Backfill tracker_definitions non-null reducer/source fields for local+remote parity.

UPDATE public.tracker_definitions
SET source = 'user'
WHERE source IS NULL OR btrim(source) = '';

UPDATE public.tracker_definitions
SET op_kind = 'set'
WHERE op_kind IS NULL OR btrim(op_kind) = '';

UPDATE public.tracker_definitions
SET aggregation_kind = 'sum'
WHERE aggregation_kind IS NULL OR btrim(aggregation_kind) = '';

ALTER TABLE public.tracker_definitions
  ALTER COLUMN source SET DEFAULT 'user';

ALTER TABLE public.tracker_definitions
  ALTER COLUMN source SET NOT NULL;

ALTER TABLE public.tracker_definitions
  ALTER COLUMN op_kind SET DEFAULT 'set';

ALTER TABLE public.tracker_definitions
  ALTER COLUMN op_kind SET NOT NULL;

ALTER TABLE public.tracker_definitions
  ALTER COLUMN aggregation_kind SET DEFAULT 'sum';

ALTER TABLE public.tracker_definitions
  ALTER COLUMN aggregation_kind SET NOT NULL;
