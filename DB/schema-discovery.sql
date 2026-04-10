-- ============================================================================
-- SCHEMA DISCOVERY SCRIPT
-- Use this to find the actual table and column names in your database
-- Run each query and share the results
-- ============================================================================

-- Get all tables
SELECT table_name FROM information_schema.tables WHERE table_schema='public';

-- Get expense_details columns
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name='expense_details' ORDER BY ordinal_position;

-- Get expense_header columns (if exists)
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name='expense_header' ORDER BY ordinal_position;

-- Get revenue columns
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name='revenue' ORDER BY ordinal_position;

-- Get employee columns
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name='employee' ORDER BY ordinal_position;

-- Get fishmaster columns
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name='fishmaster' ORDER BY ordinal_position;

-- Get labelmaster columns
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name='labelmaster' ORDER BY ordinal_position;

-- Get users columns
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name='users' ORDER BY ordinal_position;
