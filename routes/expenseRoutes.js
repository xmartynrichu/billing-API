const express = require('express');
const router = express.Router();
const pool = require('../DB/db');

// POST /users
router.post('/', async (req, res) => {
  const expenseData = req.body; // <-- JSON array

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Call function with JSONB
    await client.query(
      'SELECT * FROM insert_expense_details_json($1::jsonb, $2)',
      [
        JSON.stringify(expenseData), // important!
        'ref1'
      ]
    );

    // Fetch cursor result
    const result = await client.query('FETCH ALL IN "ref1"');

    await client.query('CLOSE "ref1"');
    await client.query('COMMIT');

    res.status(201).json({
      message: result.rows[0]?.result || 'Success'
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Insert expense error:', err);

    res.status(500).json({
      error: 'Database error',
      details: err.message
    });
  } finally {
    client.release();
  }
});

// PUT /:id - Update expense with multiple details
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const expenseData = req.body; // <-- JSON array

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Call update function with JSONB
    await client.query(
      'SELECT * FROM update_expense_details_json($1, $2::jsonb, $3)',
      [
        id,
        JSON.stringify(expenseData),
        'ref1'
      ]
    );

    // Fetch cursor result
    const result = await client.query('FETCH ALL IN "ref1"');

    await client.query('CLOSE "ref1"');
    await client.query('COMMIT');

    res.status(200).json({
      message: result.rows[0]?.result || 'Success'
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Update expense error:', err);

    res.status(500).json({
      error: 'Database error',
      details: err.message
    });
  } finally {
    client.release();
  }
});



router.get('/', async (req, res) => {
  const currentuser = req.query.currentuser || 'system';
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    await client.query('SELECT * FROM get_expensereport($1, $2)', [currentuser, 'ref1']);

    const cursorResult = await client.query('FETCH ALL FROM ref1');

    await client.query('CLOSE ref1');
    await client.query('COMMIT');

    res.status(200).json(cursorResult.rows);

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Get expense error:', err);
    res.status(500).json({ error: 'Database error' });
  } finally {
    client.release();
  }
});

router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Call your function
    await client.query(
      'SELECT * FROM delete_expensedetails($1, $2)',
      [id, 'ref1']
    );

    // Fetch cursor result
    const result = await client.query('FETCH ALL FROM ref1');

    // Close cursor
    await client.query('CLOSE ref1');
    await client.query('COMMIT');

    res.status(200).json({ message: result.rows[0].result });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Delete user error:', err);
    res.status(500).json({ error: 'Database error' });
  } finally {
    client.release();
  }
});


module.exports = router;
