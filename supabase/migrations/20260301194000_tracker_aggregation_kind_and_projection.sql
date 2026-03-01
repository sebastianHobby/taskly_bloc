-- Add tracker_definitions.aggregation_kind and update projection reducer to support avg via {sum,count}.

ALTER TABLE public.tracker_definitions
  ADD COLUMN IF NOT EXISTS aggregation_kind text;

UPDATE public.tracker_definitions
SET aggregation_kind = COALESCE(aggregation_kind, 'sum');

ALTER TABLE public.tracker_definitions
  ALTER COLUMN aggregation_kind SET DEFAULT 'sum';

ALTER TABLE public.tracker_definitions
  ALTER COLUMN aggregation_kind SET NOT NULL;

ALTER TABLE public.tracker_definitions
  DROP CONSTRAINT IF EXISTS tracker_definitions_aggregation_kind_check;

ALTER TABLE public.tracker_definitions
  ADD CONSTRAINT tracker_definitions_aggregation_kind_check
  CHECK (aggregation_kind = ANY (ARRAY['sum', 'avg']::text[]));

CREATE OR REPLACE FUNCTION public.tracker_reduce_jsonb_value(
  p_existing jsonb,
  p_op text,
  p_value jsonb,
  p_aggregation_kind text
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  existing_num numeric;
  incoming_num numeric;
  cur_sum numeric;
  cur_count numeric;
BEGIN
  IF p_op = 'clear' THEN
    RETURN NULL;
  END IF;

  IF p_aggregation_kind = 'avg' THEN
    IF p_op <> 'add' OR p_value IS NULL OR jsonb_typeof(p_value) <> 'number' THEN
      RETURN p_existing;
    END IF;

    incoming_num := (p_value #>> '{}')::numeric;
    cur_sum := COALESCE((p_existing ->> 'sum')::numeric, 0);
    cur_count := COALESCE((p_existing ->> 'count')::numeric, 0);

    RETURN jsonb_build_object(
      'sum', cur_sum + incoming_num,
      'count', cur_count + 1
    );
  END IF;

  IF p_op = 'set' THEN
    RETURN p_value;
  END IF;

  IF p_op <> 'add' THEN
    RETURN p_existing;
  END IF;

  IF p_value IS NULL OR jsonb_typeof(p_value) <> 'number' THEN
    RETURN p_existing;
  END IF;

  incoming_num := (p_value #>> '{}')::numeric;
  IF p_existing IS NULL OR jsonb_typeof(p_existing) <> 'number' THEN
    RETURN to_jsonb(incoming_num);
  END IF;

  existing_num := (p_existing #>> '{}')::numeric;
  RETURN to_jsonb(existing_num + incoming_num);
END;
$$;

CREATE OR REPLACE FUNCTION public.apply_tracker_event_projection(
  p_event_id uuid
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  ev public.tracker_events%ROWTYPE;
  def public.tracker_definitions%ROWTYPE;
  current_value jsonb;
  next_value jsonb;
BEGIN
  SELECT *
  INTO ev
  FROM public.tracker_events
  WHERE id = p_event_id;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  SELECT *
  INTO def
  FROM public.tracker_definitions
  WHERE id = ev.tracker_id;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  IF ev.anchor_type = 'entry' THEN
    SELECT value
    INTO current_value
    FROM public.tracker_state_entry
    WHERE user_id = ev.user_id
      AND entry_id = ev.entry_id
      AND tracker_id = ev.tracker_id;

    next_value := public.tracker_reduce_jsonb_value(
      current_value,
      ev.op,
      ev.value,
      COALESCE(def.aggregation_kind, 'sum')
    );

    IF next_value IS NULL THEN
      DELETE FROM public.tracker_state_entry
      WHERE user_id = ev.user_id
        AND entry_id = ev.entry_id
        AND tracker_id = ev.tracker_id;
      RETURN;
    END IF;

    INSERT INTO public.tracker_state_entry (
      user_id,
      entry_id,
      tracker_id,
      value,
      last_event_id,
      updated_at
    )
    VALUES (
      ev.user_id,
      ev.entry_id,
      ev.tracker_id,
      next_value,
      ev.id,
      now()
    )
    ON CONFLICT (user_id, entry_id, tracker_id)
    DO UPDATE SET
      value = EXCLUDED.value,
      last_event_id = EXCLUDED.last_event_id,
      updated_at = EXCLUDED.updated_at;

    RETURN;
  END IF;

  IF ev.anchor_type IN ('day', 'sleep_night') THEN
    SELECT value
    INTO current_value
    FROM public.tracker_state_day
    WHERE user_id = ev.user_id
      AND anchor_type = ev.anchor_type
      AND anchor_date = ev.anchor_date
      AND tracker_id = ev.tracker_id;

    next_value := public.tracker_reduce_jsonb_value(
      current_value,
      ev.op,
      ev.value,
      COALESCE(def.aggregation_kind, 'sum')
    );

    IF next_value IS NULL THEN
      DELETE FROM public.tracker_state_day
      WHERE user_id = ev.user_id
        AND anchor_type = ev.anchor_type
        AND anchor_date = ev.anchor_date
        AND tracker_id = ev.tracker_id;
      RETURN;
    END IF;

    INSERT INTO public.tracker_state_day (
      user_id,
      anchor_type,
      anchor_date,
      tracker_id,
      value,
      last_event_id,
      updated_at
    )
    VALUES (
      ev.user_id,
      ev.anchor_type,
      ev.anchor_date,
      ev.tracker_id,
      next_value,
      ev.id,
      now()
    )
    ON CONFLICT (user_id, anchor_type, anchor_date, tracker_id)
    DO UPDATE SET
      value = EXCLUDED.value,
      last_event_id = EXCLUDED.last_event_id,
      updated_at = EXCLUDED.updated_at;

    RETURN;
  END IF;
END;
$$;

SELECT public.rebuild_tracker_state_projections();
