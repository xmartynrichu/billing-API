-- ============================================================================
-- DASHBOARD FUNCTION
-- Purpose: Return all dashboard statistics and analytics data
-- Returns: Dashboard counts and analytics in a single function call
-- ============================================================================

-- 1. DROP existing function if it exists
DROP FUNCTION IF EXISTS get_dashboard_stats() CASCADE;
DROP FUNCTION IF EXISTS get_dashboard_analytics() CASCADE;
DROP FUNCTION IF EXISTS get_dashboard_complete() CASCADE;

-- ============================================================================
-- FUNCTION 1: get_dashboard_stats()
-- Returns: Dashboard counts (employees, expenses, fish, labels, revenue, users)
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

  -- Expense count (sum of all expenses from expense_header)
  RETURN QUERY
  SELECT 'expenses'::VARCHAR, COUNT(*)::BIGINT, COALESCE(SUM(eh.expense_total::NUMERIC), 0)::NUMERIC
  FROM expense_header eh;

  -- Fish count
  RETURN QUERY
  SELECT 'fish'::VARCHAR, COUNT(*)::BIGINT, COUNT(*)::NUMERIC
  FROM fishmaster;

  -- Label count
  RETURN QUERY
  SELECT 'labels'::VARCHAR, COUNT(*)::BIGINT, COUNT(*)::NUMERIC
  FROM labelmaster;

  -- Revenue count (sum of all revenue)
  RETURN QUERY
  SELECT 'revenue'::VARCHAR, COUNT(*)::BIGINT, COALESCE(SUM(r.fish_sold::NUMERIC), 0)::NUMERIC
  FROM revenue r;

  -- User count
  RETURN QUERY
  SELECT 'users'::VARCHAR, COUNT(*)::BIGINT, COUNT(*)::NUMERIC
  FROM users;

END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION 2: get_dashboard_analytics()
-- Returns: Monthly trends, expense breakdown, revenue breakdown, and KPIs
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
  -- Get monthly revenue vs expenses trend (last 12 months)
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
      SUM(r.fish_sold::NUMERIC) as revenue_sum,
      (SELECT COALESCE(SUM(eh.expense_total::NUMERIC), 0) 
       FROM expense_header eh
       WHERE DATE_TRUNC('month', eh.expense_date) = DATE_TRUNC('month', r.rev_date)) as expense_sum
    FROM revenue r
    WHERE r.rev_date >= NOW() - INTERVAL '12 months'
    GROUP BY DATE_TRUNC('month', r.rev_date)
    LIMIT 12
  ) monthly_data;

  RETURN QUERY SELECT 'monthlyTrend'::VARCHAR, v_monthly_trend;

  -- Get expense breakdown by category (last 3 months)
  SELECT COALESCE(
    JSONB_AGG(
      JSONB_BUILD_OBJECT(
        'label_name', COALESCE(ed.expense_cat, 'Uncategorized'),
        'amount', COALESCE(SUM(ed.expense_amount::NUMERIC), 0),
        'percentage', ROUND(
          100.0 * COALESCE(SUM(ed.expense_amount::NUMERIC), 0) / 
          NULLIF((SELECT SUM(expense_amount::NUMERIC) FROM expense_details WHERE expense_date >= NOW() - INTERVAL '3 months'), 0),
          2
        )
      )
      ORDER BY SUM(ed.expense_amount::NUMERIC) DESC NULLS LAST
    ),
    '[]'::JSONB
  ) INTO v_expense_by_category
  FROM expense_details ed
  WHERE ed.expense_date >= NOW() - INTERVAL '3 months'
  GROUP BY COALESCE(ed.expense_cat, 'Uncategorized');

  RETURN QUERY SELECT 'expenseByCategory'::VARCHAR, v_expense_by_category;

  -- Get revenue breakdown by fish type (last 3 months)
  SELECT COALESCE(
    JSONB_AGG(
      JSONB_BUILD_OBJECT(
        'fishname', COALESCE(r.fish_name, 'Unknown'),
        'entries', COUNT(*)::INTEGER,
        'revenue', COALESCE(SUM(r.fish_sold::NUMERIC), 0),
        'quantity_sold', COALESCE(SUM(r.fish_qty::NUMERIC), 0)
      )
      ORDER BY SUM(r.fish_sold::NUMERIC) DESC NULLS LAST
    ),
    '[]'::JSONB
  ) INTO v_revenue_by_fish
  FROM revenue r
  WHERE r.rev_date >= NOW() - INTERVAL '3 months'
  GROUP BY r.fish_name;

  RETURN QUERY SELECT 'revenueByFish'::VARCHAR, v_revenue_by_fish;

  -- Get current month KPIs
  SELECT JSONB_BUILD_OBJECT(
    'monthlyRevenue', COALESCE(SUM(CASE 
      WHEN EXTRACT(MONTH FROM r.rev_date) = EXTRACT(MONTH FROM NOW())
      AND EXTRACT(YEAR FROM r.rev_date) = EXTRACT(YEAR FROM NOW())
      THEN r.fish_sold::NUMERIC 
      ELSE 0 
    END), 0)::NUMERIC,
    'monthlyExpense', COALESCE((
      SELECT SUM(eh.expense_total::NUMERIC)
      FROM expense_header eh
      WHERE EXTRACT(MONTH FROM eh.expense_date) = EXTRACT(MONTH FROM NOW())
      AND EXTRACT(YEAR FROM eh.expense_date) = EXTRACT(YEAR FROM NOW())
    ), 0)::NUMERIC,
    'monthlyProfit', (
      COALESCE(SUM(CASE 
        WHEN EXTRACT(MONTH FROM r.rev_date) = EXTRACT(MONTH FROM NOW())
        AND EXTRACT(YEAR FROM r.rev_date) = EXTRACT(YEAR FROM NOW())
        THEN r.fish_sold::NUMERIC 
        ELSE 0 
      END), 0) -
      COALESCE((
        SELECT SUM(eh.expense_total::NUMERIC)
        FROM expense_header eh
        WHERE EXTRACT(MONTH FROM eh.expense_date) = EXTRACT(MONTH FROM NOW())
        AND EXTRACT(YEAR FROM eh.expense_date) = EXTRACT(YEAR FROM NOW())
      ), 0)
    )::NUMERIC,
    'profitMargin', CASE
      WHEN COALESCE(SUM(CASE 
        WHEN EXTRACT(MONTH FROM r.rev_date) = EXTRACT(MONTH FROM NOW())
        AND EXTRACT(YEAR FROM r.rev_date) = EXTRACT(YEAR FROM NOW())
        THEN r.fish_sold::NUMERIC 
        ELSE 0 
      END), 0) > 0
      THEN ROUND(
        ((COALESCE(SUM(CASE 
          WHEN EXTRACT(MONTH FROM r.rev_date) = EXTRACT(MONTH FROM NOW())
          AND EXTRACT(YEAR FROM r.rev_date) = EXTRACT(YEAR FROM NOW())
          THEN r.fish_sold::NUMERIC 
          ELSE 0 
        END), 0) -
        COALESCE((
          SELECT SUM(eh.expense_total::NUMERIC)
          FROM expense_header eh
          WHERE EXTRACT(MONTH FROM eh.expense_date) = EXTRACT(MONTH FROM NOW())
          AND EXTRACT(YEAR FROM eh.expense_date) = EXTRACT(YEAR FROM NOW())
        ), 0)) / 
        COALESCE(SUM(CASE 
          WHEN EXTRACT(MONTH FROM r.rev_date) = EXTRACT(MONTH FROM NOW())
          AND EXTRACT(YEAR FROM r.rev_date) = EXTRACT(YEAR FROM NOW())
          THEN r.fish_sold::NUMERIC 
          ELSE 0 
        END), 0)) * 100, 2)
      ELSE 0
    END
  ) INTO v_kpi
  FROM revenue r
  WHERE EXTRACT(YEAR FROM r.rev_date) = EXTRACT(YEAR FROM NOW());

  RETURN QUERY SELECT 'kpi'::VARCHAR, v_kpi;

  -- Return empty sets if any error occurs
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
-- Returns: All dashboard data (counts + analytics) in optimized format
-- ============================================================================
CREATE OR REPLACE FUNCTION get_dashboard_complete()
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_counts JSONB;
BEGIN
  -- Get all counts in JSON format
  SELECT JSONB_OBJECT_AGG(stat_name, JSONB_BUILD_OBJECT('value', stat_count, 'amount', stat_value))
  INTO v_counts
  FROM get_dashboard_stats();

  -- Get all analytics data
  WITH analytics AS (
    SELECT data_type, data_json FROM get_dashboard_analytics()
  )
  SELECT JSONB_OBJECT_AGG(data_type, data_json) INTO v_result FROM analytics;

  -- Combine counts into result
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

-- ============================================================================
-- Create indexes for better query performance
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_revenue_rev_date ON revenue(rev_date);
CREATE INDEX IF NOT EXISTS idx_expense_header_expense_date ON expense_header(expense_date);
CREATE INDEX IF NOT EXISTS idx_expense_details_expense_date ON expense_details(expense_date);

-- ============================================================================
-- Grant permissions (adjust user as needed)
-- ============================================================================
GRANT EXECUTE ON FUNCTION get_dashboard_stats() TO PUBLIC;
GRANT EXECUTE ON FUNCTION get_dashboard_analytics() TO PUBLIC;
GRANT EXECUTE ON FUNCTION get_dashboard_complete() TO PUBLIC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION 2: get_dashboard_analytics()
-- Returns: Monthly trends, expense breakdown, revenue breakdown, and KPIs
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
  -- Get monthly revenue vs expenses trend (last 12 months)
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
      SUM(r.fish_sold) as revenue_sum,
      (SELECT COALESCE(SUM(ed.expense_amount), 0) 
       FROM expense_details ed
       WHERE DATE_TRUNC('month', ed.expense_date) = DATE_TRUNC('month', r.rev_date)) as expense_sum
    FROM revenue r
    WHERE r.rev_date >= NOW() - INTERVAL '12 months'
    GROUP BY DATE_TRUNC('month', r.rev_date)
    LIMIT 12
  ) monthly_data;

  RETURN QUERY SELECT 'monthlyTrend'::VARCHAR, v_monthly_trend;

  -- Get expense breakdown by category (last 3 months)
  SELECT COALESCE(
    JSONB_AGG(
      JSONB_BUILD_OBJECT(
        'label_name', COALESCE(lm.label_name, 'Uncategorized'),
        'amount', COALESCE(SUM(ed.expense_amount), 0),
        'percentage', ROUND(
          100.0 * COALESCE(SUM(ed.expense_amount), 0) / 
          NULLIF((SELECT SUM(expense_amount) FROM expense_details WHERE expense_date >= NOW() - INTERVAL '3 months'), 0),
          2
        )
      )
      ORDER BY SUM(ed.expense_amount) DESC NULLS LAST
    ),
    '[]'::JSONB
  ) INTO v_expense_by_category
  FROM expense_details ed
  LEFT JOIN labelmaster lm ON ed.header_id = lm.id
  WHERE ed.expense_date >= NOW() - INTERVAL '3 months'
  GROUP BY COALESCE(lm.label_name, 'Uncategorized'), lm.id;

  RETURN QUERY SELECT 'expenseByCategory'::VARCHAR, v_expense_by_category;

  -- Get revenue breakdown by fish type (last 3 months)
  SELECT COALESCE(
    JSONB_AGG(
      JSONB_BUILD_OBJECT(
        'fishname', COALESCE(r.fish_name, 'Unknown'),
        'entries', COUNT(*)::INTEGER,
        'revenue', COALESCE(SUM(r.fish_sold), 0),
        'quantity_sold', COALESCE(SUM(r.fish_qty), 0)
      )
      ORDER BY SUM(r.fish_sold) DESC NULLS LAST
    ),
    '[]'::JSONB
  ) INTO v_revenue_by_fish
  FROM revenue r
  WHERE r.rev_date >= NOW() - INTERVAL '3 months'
  GROUP BY r.fish_name;

  RETURN QUERY SELECT 'revenueByFish'::VARCHAR, v_revenue_by_fish;

  -- Get current month KPIs
  SELECT JSONB_BUILD_OBJECT(
    'monthlyRevenue', COALESCE(SUM(CASE 
      WHEN EXTRACT(MONTH FROM r.rev_date) = EXTRACT(MONTH FROM NOW())
      AND EXTRACT(YEAR FROM r.rev_date) = EXTRACT(YEAR FROM NOW())
      THEN r.fish_sold 
      ELSE 0 
    END), 0)::NUMERIC,
    'monthlyExpense', COALESCE((
      SELECT SUM(ed.expense_amount)
      FROM expense_details ed
      WHERE EXTRACT(MONTH FROM ed.expense_date) = EXTRACT(MONTH FROM NOW())
      AND EXTRACT(YEAR FROM ed.expense_date) = EXTRACT(YEAR FROM NOW())
    ), 0)::NUMERIC,
    'monthlyProfit', (
      COALESCE(SUM(CASE 
        WHEN EXTRACT(MONTH FROM r.rev_date) = EXTRACT(MONTH FROM NOW())
        AND EXTRACT(YEAR FROM r.rev_date) = EXTRACT(YEAR FROM NOW())
        THEN r.fish_sold 
        ELSE 0 
      END), 0) -
      COALESCE((
        SELECT SUM(ed.expense_amount)
        FROM expense_details ed
        WHERE EXTRACT(MONTH FROM ed.expense_date) = EXTRACT(MONTH FROM NOW())
        AND EXTRACT(YEAR FROM ed.expense_date) = EXTRACT(YEAR FROM NOW())
      ), 0)
    )::NUMERIC,
    'profitMargin', CASE
      WHEN COALESCE(SUM(CASE 
        WHEN EXTRACT(MONTH FROM r.rev_date) = EXTRACT(MONTH FROM NOW())
        AND EXTRACT(YEAR FROM r.rev_date) = EXTRACT(YEAR FROM NOW())
        THEN r.fish_sold 
        ELSE 0 
      END), 0) > 0
      THEN ROUND(
        ((COALESCE(SUM(CASE 
          WHEN EXTRACT(MONTH FROM r.rev_date) = EXTRACT(MONTH FROM NOW())
          AND EXTRACT(YEAR FROM r.rev_date) = EXTRACT(YEAR FROM NOW())
          THEN r.fish_sold 
          ELSE 0 
        END), 0) -
        COALESCE((
          SELECT SUM(ed.expense_amount)
          FROM expense_details ed
          WHERE EXTRACT(MONTH FROM ed.expense_date) = EXTRACT(MONTH FROM NOW())
          AND EXTRACT(YEAR FROM ed.expense_date) = EXTRACT(YEAR FROM NOW())
        ), 0)) / 
        COALESCE(SUM(CASE 
          WHEN EXTRACT(MONTH FROM r.rev_date) = EXTRACT(MONTH FROM NOW())
          AND EXTRACT(YEAR FROM r.rev_date) = EXTRACT(YEAR FROM NOW())
          THEN r.fish_sold 
          ELSE 0 
        END), 0)) * 100, 2)
      ELSE 0
    END
  ) INTO v_kpi
  FROM revenue r
  WHERE EXTRACT(YEAR FROM r.rev_date) = EXTRACT(YEAR FROM NOW());

  RETURN QUERY SELECT 'kpi'::VARCHAR, v_kpi;

  -- Return empty sets if any error occurs
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
-- Returns: All dashboard data (counts + analytics) in optimized format
-- ============================================================================
CREATE OR REPLACE FUNCTION get_dashboard_complete()
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_counts JSONB;
  v_monthly_trend JSONB;
  v_expense_by_category JSONB;
  v_revenue_by_fish JSONB;
  v_kpi JSONB;
BEGIN
  -- Get all counts in JSON format
  SELECT JSONB_OBJECT_AGG(stat_name, JSONB_BUILD_OBJECT('value', stat_count, 'amount', stat_value))
  INTO v_counts
  FROM get_dashboard_stats();

  -- Get all analytics data
  WITH analytics AS (
    SELECT data_type, data_json FROM get_dashboard_analytics()
  )
  SELECT JSONB_OBJECT_AGG(data_type, data_json) INTO v_result FROM analytics;

  -- Combine counts into result
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

-- ============================================================================
-- Create indexes for better query performance
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_revenue_rev_date ON revenue(rev_date);
CREATE INDEX IF NOT EXISTS idx_expense_details_expense_date ON expense_details(expense_date);
CREATE INDEX IF NOT EXISTS idx_expense_details_header_id ON expense_details(header_id);

-- ============================================================================
-- Grant permissions (adjust user as needed)
-- ============================================================================
GRANT EXECUTE ON FUNCTION get_dashboard_stats() TO PUBLIC;
GRANT EXECUTE ON FUNCTION get_dashboard_analytics() TO PUBLIC;
GRANT EXECUTE ON FUNCTION get_dashboard_complete() TO PUBLIC;
