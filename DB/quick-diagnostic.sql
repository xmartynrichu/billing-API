-- ============================================================================
-- QUICK DIAGNOSTIC TO FIND CORRECT COLUMN NAMES
-- ============================================================================
-- Run this query to see all columns in expense-related tables

-- See all columns in expense_details with their data types
\d expense_details

-- See all columns in expense_header with their data types  
\d expense_header

-- Test what columns actually exist by selecting one row
SELECT * FROM expense_details LIMIT 1;

SELECT * FROM expense_header LIMIT 1;

-- Get column info
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name IN ('expense_details', 'expense_header') 
ORDER BY table_name, ordinal_position;
