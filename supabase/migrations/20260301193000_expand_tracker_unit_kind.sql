-- Expand tracker_definitions.unit_kind to include all supported UI units.

ALTER TABLE public.tracker_definitions
  DROP CONSTRAINT IF EXISTS tracker_definitions_unit_kind_check;

ALTER TABLE public.tracker_definitions
  ADD CONSTRAINT tracker_definitions_unit_kind_check
  CHECK (
    unit_kind IS NULL OR unit_kind = ANY (
      ARRAY[
        'count','times','reps',
        'ml','l','oz','cup',
        'mg','g','kg','oz_mass','lb',
        'minutes','hours','steps'
      ]::text[]
    )
  );
