-- ============================================================================
-- DASHBOARD FUNCTIONS - GENERIC VERSION
-- Uses most common column naming conventions
-- ============================================================================

DROP FUNCTION IF EXISTS get_dashboard_stats() CASCADE;
DROP FUNCTION IF EXISTS get_dashboard_analytics() CASCADE;
DROP FUNCTION IF EXISTS get_dashboard_complete() CASCADE;

-- ============================================================================
-- FUNCTION 1: get_dashboard_stats()
-- ============================================================================
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS TABLE (
  stat_name VARCHAR,
  stat_count BIGINT,
  stat_value NUMERIC
) AS $$
BEGIN
  -- Employee count
  RETURN QUERY
  SELECT 'employees'::VARCHAR, COUNT(*)::BIGINT, COUNT(*)::NUMERIC 
  FROM employee;

  -- Expense count - from expense_header table (safer for summing)
  RETURN QUERY
  SELECT 'expenses'::VARCHAR, 
         COUNT(*)::BIGINT, 
         COALESCE(SUM(
           CASE 
             WHEN expense_total IS NOT NULL THEN expense_total::NUMERIC
             WHEN expense_amount IS NOT NULL THEN expense_amount::NUMERIC
             ELSE 0 
           END
         ), 0)::NUMERIC
  FROM expense_header;

  -- Fish count
  RETURN QUERY
  SELECT 'fish'::VARCHAR, COUNT(*)::BIGINT, COUNT(*)::NUMERIC
  FROM fishmaster;

  -- Label count
  RETURN QUERY
  SELECT 'labels'::VARCHAR, COUNT(*)::BIGINT, COUNT(*)::NUMERIC
  FROM labelmaster;

  -- Revenue count - sum from revenue table
  RETURN QUERY
  SELECT 'revenue'::VARCHAR, 
         COUNT(*)::BIGINT, 
         COALESCE(SUM(
           CASE 
             WHEN fish_sold IS NOT NULL THEN fish_sold::NUMERIC
             WHEN amount IS NOT NULL THEN amount::NUMERIC
             ELSE 0 
           END
         ), 0)::NUMERIC
  FROM revenue;

  -- User count
  RETURN QUERY
  SELECT 'users'::VARCHAR, COUNT(*)::BIGINT, COUNT(*)::NUMERIC
  FROM users;

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Dashboard stats error: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION 2: get_dashboard_analytics()
-- ============================================================================
CREATE OR REPLACE FUNCTION get_dashboard_analytics()
RETURNS TABLE (
  data_type VARCHAR,
  data_json JSONB
) AS $$
DECLARE
  v_monthly_trend JSONB;
  v_expense_by_category JSONB;
  v_revenue_by_fish JSONB;
  v_kpi JSONB;
BEGIN
  -- Monthly revenue vs expenses trend
  SELECT COALESCE(
    JSONB_AGG(
      JSONB_BUILD_OBJECT(
        'month', TO_CHAR(month_data, 'YYYY-MM-DD'),
        'revenue', COALESCE(revenue_sum, 0),
        'expense', COALESCE(expense_sum, 0),
        'profit', COALESCE(revenue_sum, 0) - COALESCE(expense_sum, 0)
      )
      ORDER BY month_data DESC
    ),
    '[]'::JSONB
  ) INTO v_monthly_trend
  FROM (
    SELECT 
      DATE_TRUNC('month', r.rev_date)::date as month_data,
      SUM(
        CASE 
          WHEN r.fish_sold IS NOT NULL THEN r.fish_sold::NUMERIC
          WHEN r.amount IS NOT NULL THEN r.amount::NUMERIC
          ELSE 0 
        END
      ) as revenue_sum,
      (SELECT COALESCE(SUM(
        CASE 
          WHEN eh.expense_total IS NOT NULL THEN eh.expense_total::NUMERIC
          WHEN eh.expense_amount IS NOT NULL THEN eh.expense_amount::NUMERIC
          ELSE 0 
        END
      ), 0) 
       FROM expense_header eh
       WHERE DATE_TRUNC('month', eh.expense_date) = DATE_TRUNC('month', r.rev_date)) as expense_sum
    FROM revenue r
    WHERE r.rev_date >= NOW() - INTERVAL '12 months'
    GROUP BY DATE_TRUNC('month', r.rev_date)
  ) monthly_data;

  RETURN QUERY SELECT 'monthlyTrend'::VARCHAR, v_monthly_trend;

  -- Expense breakdown by category
  SELECT COALESCE(
    JSONB_AGG(
      JSONB_BUILD_OBJECT(
        'label_name', COALESCE(
          CASE 
            WHEN ed.expense_cat IS NOT NULL THEN ed.expense_cat
            WHEN ed.category IS NOT NULL THEN ed.category
            ELSE 'Uncategorized'
          END,
          'Uncategorized'
        ),
        'amount', expense_sum,
        'percentage', CASE 
          WHEN total_expenses > 0 THEN ROUND((expense_sum / total_expenses) * 100, 2)
          ELSE 0 
        END
      )
      ORDER BY expense_sum DESC NULLS LAST
    ),
    '[]'::JSONB
  ) INTO v_expense_by_category
  FROM (
    SELECT 
      COALESCE(ed.expense_cat, ed.category, 'Uncategorized') as category_name,
      SUM(CASE 
        WHEN ed.expense_amount IS NOT NULL THEN ed.expense_amount::NUMERIC
        WHEN ed.amount IS NOT NULL THEN ed.amount::NUMERIC
        ELSE 0 
      END) as expense_sum,
      (SELECT SUM(CASE 
        WHEN expense_amount IS NOT NULL THEN expense_amount::NUMERIC
        WHEN amount IS NOT NULL THEN amount::NUMERIC
        ELSE 0 
      END) FROM expense_details WHERE expense_date >= NOW() - INTERVAL '3 months') as total_expenses
    FROM expense_details ed
    WHERE ed.expense_date >= NOW() - INTERVAL '3 months'
    GROUP BY COALESCE(ed.expense_cat, ed.category, 'Uncategorized')
  ) expenses;

  RETURN QUERY SELECT 'expenseByCategory'::VARCHAR, v_expense_by_category;

  -- Revenue breakdown by fish type
  SELECT COALESCE(
    JSONB_AGG(
      JSONB_BUILD_OBJECT(
        'fishname', COALESCE(r.fish_name, 'Unknown'),
        'entries', COUNT(*)::INTEGER,
        'revenue', COALESCE(SUM(
          CASE 
            WHEN r.fish_sold IS NOT NULL THEN r.fish_sold::NUMERIC
            WHEN r.amount IS NOT NULL THEN r.amount::NUMERIC
            ELSE 0 
          END
        ), 0),
        'quantity_sold', COALESCE(SUM(
          CASE 
            WHEN r.fish_qty IS NOT NULL THEN r.fish_qty::NUMERIC
            WHEN r.quantity IS NOT NULL THEN r.quantity::NUMERIC
            ELSE 0 
          END
        ), 0)
      )
      ORDER BY SUM(CASE 
        WHEN r.fish_sold IS NOT NULL THEN r.fish_sold::NUMERIC
        WHEN r.amount IS NOT NULL THEN r.amount::NUMERIC
        ELSE 0 
      END) DESC NULLS LAST
    ),
    '[]'::JSONB
  ) INTO v_revenue_by_fish
  FROM revenue r
  WHERE r.rev_date >= NOW() - INTERVAL '3 months'
  GROUP BY r.fish_name;

  RETURN QUERY SELECT 'revenueByFish'::VARCHAR, v_revenue_by_fish;

  -- KPI data
  SELECT JSONB_BUILD_OBJECT(
    'monthlyRevenue', COALESCE(monthly_rev, 0),
    'monthlyExpense', COALESCE(monthly_exp, 0),
    'monthlyProfit', COALESCE(monthly_rev, 0) - COALESCE(monthly_exp, 0),
    'profitMargin', CASE 
      WHEN COALESCE(monthly_rev, 0) > 0 
      THEN ROUND(((COALESCE(monthly_rev, 0) - COALESCE(monthly_exp, 0)) / COALESCE(monthly_rev, 0)) * 100, 2)
      ELSE 0
    END
  ) INTO v_kpi
  FROM (
    SELECT 
      SUM(CASE 
        WHEN r.fish_sold IS NOT NULL THEN r.fish_sold::NUMERIC
        WHEN r.amount IS NOT NULL THEN r.amount::NUMERIC
        ELSE 0 
      END) as monthly_rev,
      (SELECT SUM(
        CASE 
          WHEN eh.expense_total IS NOT NULL THEN eh.expense_total::NUMERIC
          WHEN eh.expense_amount IS NOT NULL THEN eh.expense_amount::NUMERIC
          ELSE 0 
        END
      ) FROM expense_header eh
       WHERE EXTRACT(MONTH FROM eh.expense_date) = EXTRACT(MONTH FROM NOW())
       AND EXTRACT(YEAR FROM eh.expense_date) = EXTRACT(YEAR FROM NOW())) as monthly_exp
    FROM revenue r
    WHERE EXTRACT(MONTH FROM r.rev_date) = EXTRACT(MONTH FROM NOW())
    AND EXTRACT(YEAR FROM r.rev_date) = EXTRACT(YEAR FROM NOW())
  ) kpi_data;

  RETURN QUERY SELECT 'kpi'::VARCHAR, v_kpi;

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Dashboard analytics error: %', SQLERRM;
  RETURN QUERY SELECT 'monthlyTrend'::VARCHAR, '[]'::JSONB;
  RETURN QUERY SELECT 'expenseByCategory'::VARCHAR, '[]'::JSONB;
  RETURN QUERY SELECT 'revenueByFish'::VARCHAR, '[]'::JSONB;
  RETURN QUERY SELECT 'kpi'::VARCHAR, JSONB_BUILD_OBJECT(
    'monthlyRevenue', 0,
    'monthlyExpense', 0,
    'monthlyProfit', 0,
    'profitMargin', 0
  );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION 3: get_dashboard_complete()
-- ============================================================================
CREATE OR REPLACE FUNCTION get_dashboard_complete()
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_counts JSONB;
BEGIN
  SELECT JSONB_OBJECT_AGG(stat_name, JSONB_BUILD_OBJECT('value', stat_count, 'amount', stat_value))
  INTO v_counts
  FROM get_dashboard_stats();

  WITH analytics AS (
    SELECT data_type, data_json FROM get_dashboard_analytics()
  )
  SELECT JSONB_OBJECT_AGG(data_type, data_json) INTO v_result FROM analytics;

  v_result := v_result || JSONB_BUILD_OBJECT('counts', v_counts);
  RETURN v_result;

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Dashboard complete error: %', SQLERRM;
  RETURN JSONB_BUILD_OBJECT(
    'error', 'Failed to fetch dashboard data',
    'message', SQLERRM
  );
END;
$$ LANGUAGE plpgsql;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_revenue_rev_date ON revenue(rev_date);
CREATE INDEX IF NOT EXISTS idx_expense_header_expense_date ON expense_header(expense_date);
CREATE INDEX IF NOT EXISTS idx_expense_details_expense_date ON expense_details(expense_date);

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_dashboard_stats() TO PUBLIC;
GRANT EXECUTE ON FUNCTION get_dashboard_analytics() TO PUBLIC;
GRANT EXECUTE ON FUNCTION get_dashboard_complete() TO PUBLIC;
