CREATE OR REPLACE FUNCTION public.update_expense_details_json(
  p_header_id INT,
  p_data jsonb,
  ref1 refcursor
)
RETURNS SETOF refcursor
LANGUAGE plpgsql
AS $function$
DECLARE
  v_total_amt NUMERIC := 0;
  v_date DATE;
  v_entryby TEXT;
  rec JSONB;
BEGIN
  -- 1️⃣ Extract header-level info from FIRST element
  SELECT
    (p_data->0->>'date')::DATE,
    p_data->0->>'entryby'
  INTO
    v_date,
    v_entryby;

  -- 2️⃣ Delete existing DETAILS for this header
  DELETE FROM expense_details
  WHERE header_id = p_header_id;

  -- 3️⃣ Insert NEW DETAILS (many rows, same header_id)
  FOR rec IN SELECT * FROM jsonb_array_elements(p_data)
  LOOP
    INSERT INTO expense_details
      (header_id, expense_cat, expense_amount, createdby, createdat, expense_date)
    VALUES
      (
        p_header_id,
        rec->>'labelName',
        (rec->>'amount')::NUMERIC,
        rec->>'entryby',
        NOW(),
        v_date
      );

    v_total_amt := v_total_amt + (rec->>'amount')::NUMERIC;
  END LOOP;

  -- 4️⃣ Update HEADER with new total and date
  UPDATE expense_header
  SET
    expense_date = v_date,
    expense_total = v_total_amt,
    createdby = v_entryby
  WHERE id = p_header_id;

  -- 5️⃣ Return result
  OPEN ref1 FOR
    SELECT
      'Update Successfully' AS result,
      p_header_id AS header_id,
      v_total_amt AS total_amount;

  RETURN NEXT ref1;
END;
$function$
;
