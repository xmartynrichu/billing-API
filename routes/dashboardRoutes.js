const express = require('express');
const router = express.Router();
const pool = require('../DB/db');

/**
 * GET /dashboard
 * Calls the PostgreSQL function: get_dashboard()
 * Returns: Dashboard statistics (employees, expenses, fish, labels, revenue, users)
 */
router.get('/', async (req, res) => {
  const currentuser = req.query.currentuser || 'system';
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Execute the function - it returns 7 cursors (6 counts + 1 combined chart)
    await client.query(
      'SELECT get_dashboard($1, $2, $3, $4, $5, $6, $7, $8)',
      [currentuser, 'expcount', 'revcount', 'empcount', 'fiscount', 'lblcount', 'usrcount', 'combined_chart']
    );

    // Fetch each cursor
    const expcount = await client.query('FETCH ALL FROM expcount');
    const revcount = await client.query('FETCH ALL FROM revcount');
    const empcount = await client.query('FETCH ALL FROM empcount');
    const fiscount = await client.query('FETCH ALL FROM fiscount');
    const lblcount = await client.query('FETCH ALL FROM lblcount');
    const usrcount = await client.query('FETCH ALL FROM usrcount');
    const chartData = await client.query('FETCH ALL FROM combined_chart');

    await client.query('COMMIT');

    // Return data in the format expected by frontend
    const response = {
      empcount: empcount.rows,
      expcount: expcount.rows,
      fiscount: fiscount.rows,
      lblcount: lblcount.rows,
      revcount: revcount.rows,
      usrcount: usrcount.rows,
      chartData: chartData.rows
    };

    res.status(200).json(response);

  } catch (err) {
    try {
      await client.query('ROLLBACK');
    } catch (rollbackErr) {
      console.error('Rollback error:', rollbackErr);
    }
    
    console.error('Dashboard API error:', err.message);
    
    // Return default data so frontend doesn't break
    res.status(200).json({
      empcount: [{ value: 0 }],
      expcount: [{ value: 0 }],
      fiscount: [{ value: 0 }],
      lblcount: [{ value: 0 }],
      revcount: [{ value: 0 }],
      usrcount: [{ value: 0 }],
      chartData: []
    });
  } finally {
    client.release();
  }
});


module.exports = router;
