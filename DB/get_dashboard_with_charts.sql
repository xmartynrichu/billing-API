-- get_dashboard - Returns dashboard counts and chart data
-- Created By: Martin Rijay.X
-- Created On: 26-01-2026

CREATE OR REPLACE FUNCTION public.get_dashboard(
    currentuser character varying, 
    expcount refcursor, 
    revcount refcursor, 
    empcount refcursor, 
    fiscount refcursor, 
    lblcount refcursor, 
    usrcount refcursor,
    combined_chart refcursor
)
 RETURNS SETOF refcursor
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Total Expense Count
    OPEN expcount FOR 
        SELECT COALESCE(SUM(CAST(expense_total AS int)), 0) AS value 
        FROM expense_header
        WHERE createdby = currentuser;
    RETURN NEXT expcount;
   
    -- Total Revenue Count
    OPEN revcount FOR 
        SELECT COALESCE(SUM(CAST(fish_sold AS int)), 0) AS value 
        FROM revenue
        WHERE createdby = currentuser;
    RETURN NEXT revcount;
   
    -- Employee Count
    OPEN empcount FOR 
        SELECT COUNT(*)::int AS value 
        FROM employee
        WHERE createdby = currentuser;
    RETURN NEXT empcount;
   
    -- Fish Master Count
    OPEN fiscount FOR 
        SELECT COUNT(*)::int AS value 
        FROM fishmaster
        WHERE createdby = currentuser;
    RETURN NEXT fiscount;
   
    -- Label Master Count
    OPEN lblcount FOR 
        SELECT COUNT(*)::int AS value 
        FROM labelmaster
        WHERE createdby = currentuser;
    RETURN NEXT lblcount;
   
    -- Users Count
    OPEN usrcount FOR 
        SELECT COUNT(*)::int AS value 
        FROM users
        WHERE createdby = currentuser;
    RETURN NEXT usrcount;
   
    -- Combined Date-wise Bar Chart Data (Expense + Revenue)
    OPEN combined_chart FOR 
        SELECT 
            COALESCE(e.expense_date, r.rev_date)::date AS date,
            TO_CHAR(COALESCE(e.expense_date, r.rev_date)::date, 'DD-MMM-YYYY') AS date_formatted,
            COALESCE(e.total_expense, 0)::int AS total_expense,
            COALESCE(r.total_revenue, 0)::int AS total_revenue
        FROM (
            SELECT 
                CAST(expense_date AS date) AS expense_date, 
                SUM(CAST(expense_total AS int)) AS total_expense
            FROM expense_header
            WHERE createdby = currentuser
            GROUP BY CAST(expense_date AS date)
        ) e
        FULL OUTER JOIN (
            SELECT 
                CAST(rev_date AS date) AS rev_date, 
                SUM(CAST(fish_sold AS int)) AS total_revenue
            FROM revenue
            WHERE createdby = currentuser
            GROUP BY CAST(rev_date AS date)
        ) r ON CAST(e.expense_date AS date) = CAST(r.rev_date AS date)
        ORDER BY COALESCE(e.expense_date, r.rev_date) DESC
        LIMIT 30;
    RETURN NEXT combined_chart;

END;
$function$;

