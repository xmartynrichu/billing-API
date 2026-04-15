const express = require('express');
const router = express.Router();
const pool = require('../DB/db');

/**
 * GET /profit
 * Calls the PostgreSQL function: get_profit()
 * Returns: All profit report data (date, revenue, expense, profit)
 * Note: To filter by date, use GET /profit/email/:date endpoint
 */
router.get('/', async (req, res) => {
  const client = await pool.connect();

  try {
    console.log('\n=== GET /profit API called ===');
    console.log('Fetching ALL profit data from database...');
    await client.query('BEGIN');

    // Call the PostgreSQL function: get_profit() - returns all dates
    console.log('Executing: SELECT * FROM get_profit(\'ref1\')');
    const selectResult = await client.query('SELECT * FROM get_profit($1)', ['ref1']);
    console.log('Function executed');

    // Fetch all profit data from cursor
    console.log('Fetching data from ref1 cursor...');
    const result = await client.query('FETCH ALL FROM ref1');
    console.log(`✓ Fetched ${result.rows.length} rows from profit data`);
    
    if (result.rows.length > 0) {
      console.log('Sample data:', result.rows[0]);
    } else {
      console.log('⚠ No profit data found in database');
    }

    // Close cursor
    await client.query('CLOSE ref1');
    await client.query('COMMIT');

    console.log('✓ Profit API response sent successfully\n');
    res.status(200).json(result.rows);

  } catch (err) {
    try {
      await client.query('ROLLBACK');
    } catch (rollbackErr) {
      console.error('Rollback failed:', rollbackErr.message);
    }
    console.error('❌ Get profit error:', err.message);
    console.error('Error code:', err.code);
    console.error('Full error:', err);
    res.status(500).json({ error: 'Database error', details: err.message });
  } finally {
    client.release();
  }
});

/**
 * GET /profit/email/:date
 * Calls the PostgreSQL function: get_profittomail(date)
 * Returns: Profit report data for a specific date for email attachment
 * 
 * Used by: Mail service to get fresh profit data for email generation
 * Example: GET /profit/email/2026-04-15
 */
router.get('/email/:date', async (req, res) => {
  const client = await pool.connect();
  const { date } = req.params;

  try {
    console.log(`\n=== GET /profit/email/${date} API called ===`);
    console.log(`Requested date for email: ${date}`);
    
    await client.query('BEGIN');

    // Call the PostgreSQL function: get_profittomail(ref1, date) with specific date parameter
    console.log('Executing: SELECT * FROM get_profittomail(\'ref1\', $1)');
    const selectResult = await client.query('SELECT * FROM get_profittomail($1, $2)', ['ref1', date]);
    console.log('Function executed');

    // Fetch all profit data from cursor
    console.log('Fetching data from ref1 cursor...');
    const result = await client.query('FETCH ALL FROM ref1');
    console.log(`✓ Fetched ${result.rows.length} rows from profit data for date: ${date}`);
    
    if (result.rows.length > 0) {
      console.log('Email profit data:', result.rows[0]);
    } else {
      console.log(`⚠ No profit data found for date: ${date}`);
    }

    // Close cursor
    await client.query('CLOSE ref1');
    await client.query('COMMIT');

    console.log('✓ Profit email data API response sent successfully\n');
    res.status(200).json(result.rows);

  } catch (err) {
    try {
      await client.query('ROLLBACK');
    } catch (rollbackErr) {
      console.error('Rollback failed:', rollbackErr.message);
    }
    console.error('❌ Get profit for email error:', err.message);
    console.error('Error code:', err.code);
    console.error('Full error:', err);
    res.status(500).json({ error: 'Database error', details: err.message });
  } finally {
    client.release();
  }
});

module.exports = router;
