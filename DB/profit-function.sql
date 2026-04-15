-- Profit Report Function
-- Groups revenue and expense by date and calculates profit

CREATE OR REPLACE FUNCTION public.get_profit(ref1 refcursor)
 RETURNS SETOF refcursor
 LANGUAGE plpgsql
AS $function$
DECLARE
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
            GROUP BY rev_date::date
        ) r
    LEFT JOIN 
        (
            SELECT 
                expense_date::date as date,
                SUM(expense_total::numeric) as expense
            FROM expense_header
            GROUP BY expense_date::date
        ) e ON e.date = r.date
    ORDER BY 
        r.date DESC;
    
    RETURN NEXT ref1;
END;
$function$;
