-- ==========================================
-- Function: get_profittomail()
-- Purpose: Get daily profit statement in account format
--          Revenue (fish names) on left, Expenses (categories) on right
--          Specifically for email report with account statement layout
-- Created By: Martin Rijay.X
-- Created On: 28-01-2026
-- Updated: 16-04-2026
-- ==========================================

CREATE OR REPLACE FUNCTION public.get_profittomail(ref1 refcursor, p_date DATE DEFAULT NULL)
 RETURNS SETOF refcursor
 LANGUAGE plpgsql
AS $function$

--Usage: 
-- For specific date: select * from get_profittomail('ref1', '2026-04-15'::date); fetch all in "ref1";
-- Returns account statement format: fish names/revenue on left, expense categories on right
   
BEGIN
    OPEN ref1 FOR 
    SELECT 
        -- Date column
        COALESCE(rev.statement_date, exp.statement_date)::date as statement_date,
        -- Left side: Revenue by Fish Name
        rev.fish_name,
        rev.fish_revenue,
        -- Right side: Expense by Category
        exp.expense_cat,
        exp.expense_amount,
        -- Summary totals
        rev.total_revenue,
        exp.total_expense,
        (rev.total_revenue - COALESCE(exp.total_expense, 0)) as total_profit
    FROM 
        (
            SELECT 
                COALESCE(p_date, CURRENT_DATE) as statement_date,
                fish_name,
                SUM(fish_sold::numeric) as fish_revenue,
                SUM(SUM(fish_sold::numeric)) OVER () as total_revenue
            FROM revenue
            WHERE p_date IS NULL OR rev_date::date = p_date
            GROUP BY fish_name
            ORDER BY fish_revenue DESC
        ) rev
    FULL OUTER JOIN 
        (
            SELECT 
                COALESCE(p_date, CURRENT_DATE) as statement_date,
                expense_cat,
                SUM(expense_amount::numeric) as expense_amount,
                SUM(SUM(expense_amount::numeric)) OVER () as total_expense
            FROM expense_details
            WHERE p_date IS NULL OR expense_date::date = p_date
            GROUP BY expense_cat
            ORDER BY expense_amount DESC
        ) exp ON FALSE;
     
    RETURN NEXT ref1;

END;
$function$
;