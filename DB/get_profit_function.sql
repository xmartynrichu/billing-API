-- ==========================================
-- Function: get_profit()
-- Purpose: Get daily profit statement with revenue and expense aggregation
-- Created By: Martin Rijay.X
-- Created On: 28-01-2026
-- Updated: 16-04-2026
-- ==========================================

CREATE OR REPLACE FUNCTION public.get_profit(ref1 refcursor, p_date DATE DEFAULT NULL)
 RETURNS SETOF refcursor
 LANGUAGE plpgsql
AS $function$

--Usage: 
-- For all dates: select * from get_profit('ref1'); fetch all in "ref1";
-- For specific date: select * from get_profit('ref1', '2026-04-15'::date); fetch all in "ref1";
   
BEGIN
    OPEN ref1 FOR 
    SELECT 
        r.date,
        r.revenue,
        COALESCE(e.expense, 0) as expense,
        (r.revenue - COALESCE(e.expense, 0)) as profit
    FROM 
        (
            SELECT 
                rev_date::date as date,
                SUM(fish_sold::numeric) as revenue
            FROM revenue
            WHERE p_date IS NULL OR rev_date::date = p_date
            GROUP BY rev_date::date
        ) r
    LEFT JOIN 
        (
            SELECT 
                expense_date::date as date,
                SUM(expense_amount::numeric) as expense
            FROM expense_details
            WHERE p_date IS NULL OR expense_date::date = p_date
            GROUP BY expense_date::date
        ) e ON e.date = r.date
    WHERE p_date IS NULL OR r.date = p_date
    ORDER BY 
        r.date DESC;
     
    RETURN NEXT ref1;

END;
$function$
;