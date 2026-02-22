-- Align journal schema with multi-entry-per-day behavior and maintain tracker projections.

-- 1) Allow multiple journal entries per day per user.
ALTER TABLE public.journal_entries
  DROP CONSTRAINT IF EXISTS unique_user_entry_date;

-- Keep/read-path performance for day-grouped timeline and per-day entry lists.
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_date_time
  ON public.journal_entries USING btree (user_id, entry_date, entry_time DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_journal_entries_user_local_date_time
  ON public.journal_entries USING btree (user_id, local_date, entry_time DESC)
  WHERE deleted_at IS NULL;

-- 2) Projection reducer for tracker event-log rows.
CREATE OR REPLACE FUNCTION public.tracker_reduce_jsonb_value(
  p_existing jsonb,
  p_op text,
  p_value jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  existing_num numeric;
  incoming_num numeric;
BEGIN
  IF p_op = 'clear' THEN
    RETURN NULL;
  END IF;

  IF p_op = 'set' THEN
    RETURN p_value;
  END IF;

  IF p_op <> 'add' THEN
    RETURN p_existing;
  END IF;

  -- add: numeric accumulation for quantity-style trackers.
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

  IF ev.anchor_type = 'entry' THEN
    SELECT value
    INTO current_value
    FROM public.tracker_state_entry
    WHERE user_id = ev.user_id
      AND entry_id = ev.entry_id
      AND tracker_id = ev.tracker_id;

    next_value := public.tracker_reduce_jsonb_value(current_value, ev.op, ev.value);

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

    next_value := public.tracker_reduce_jsonb_value(current_value, ev.op, ev.value);

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

CREATE OR REPLACE FUNCTION public.trg_apply_tracker_event_projection()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM public.apply_tracker_event_projection(NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_apply_tracker_event_projection ON public.tracker_events;
CREATE TRIGGER trg_apply_tracker_event_projection
AFTER INSERT OR UPDATE OF tracker_id, anchor_type, entry_id, anchor_date, op, value
ON public.tracker_events
FOR EACH ROW
EXECUTE FUNCTION public.trg_apply_tracker_event_projection();

-- 3) Rebuild projections from the canonical event log to remove any drift.
CREATE OR REPLACE FUNCTION public.rebuild_tracker_state_projections()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  ev_id uuid;
BEGIN
  TRUNCATE TABLE public.tracker_state_entry;
  TRUNCATE TABLE public.tracker_state_day;

  FOR ev_id IN
    SELECT e.id
    FROM public.tracker_events e
    ORDER BY e.recorded_at ASC, e.occurred_at ASC, e.id ASC
  LOOP
    PERFORM public.apply_tracker_event_projection(ev_id);
  END LOOP;
END;
$$;

SELECT public.rebuild_tracker_state_projections();
