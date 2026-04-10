const express = require('express');
const router = express.Router();
const pool = require('../DB/db');

/**
 * GET /profit
 * Calls the PostgreSQL function: get_profit()
 * Returns: Profit report data (date, revenue, expense, profit)
 */
router.get('/', async (req, res) => {
  const client = await pool.connect();

  try {
    console.log('\n=== GET /profit API called ===');
    await client.query('BEGIN');

    // Call the PostgreSQL function: get_profit()
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

module.exports = router;
