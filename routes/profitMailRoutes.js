const express = require('express');
const router = express.Router();
const pool = require('../DB/db');

/**
 * GET /profit/email/:date
 * Calls the PostgreSQL function: get_profittomail(currentuser, date)
 * Returns: Profit report data for a specific date for email attachment
 * 
 * Example: GET /profit/email/2026-04-15?currentuser=martin
 */
router.get('/email/:date', async (req, res) => {
  const currentuser = req.query.currentuser || 'system';
  const client = await pool.connect();
  const { date } = req.params;

  try {
    console.log(`\n=== GET /profit/email/${date} API called ===`);
    console.log(`Requested date: ${date}, User: ${currentuser}`);
    
    await client.query('BEGIN');

    // Call the PostgreSQL function: get_profittomail() with currentuser and specific date parameter
    console.log('Executing: SELECT * FROM get_profittomail($1, $2, $3)');
    const selectResult = await client.query('SELECT * FROM get_profittomail($1, $2, $3)', [currentuser, 'ref1', date]);
    console.log('Function executed');

    // Fetch all profit data from cursor
    console.log('Fetching data from ref1 cursor...');
    const result = await client.query('FETCH ALL FROM ref1');
    console.log(`✓ Fetched ${result.rows.length} rows from profit data for date: ${date}`);
    
    if (result.rows.length > 0) {
      console.log('Data for email:', result.rows[0]);
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
