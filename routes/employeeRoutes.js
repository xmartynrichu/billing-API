const express = require('express');
const router = express.Router();
const pool = require('../DB/db');

// POST /users
router.post('/', async (req, res) => {
  const {
     entryby,
        empname,
        empdesignation,    
      empsalary,empdob,empmobile,emplocation,empemail,
  } = req.body;

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    await client.query(
      'SELECT * FROM insert_employeemaster($1,$2,$3,$4,$5,$6,$7,$8,$9)',
      [
        entryby,
        empname,
        empdesignation,    
      empsalary,empdob,empmobile,emplocation,empemail,
        'ref1'
      ]
    );

    const result = await client.query('FETCH ALL FROM ref1');

    await client.query('CLOSE ref1');
    await client.query('COMMIT');

    res.status(201).json({
      message: result.rows[0].result
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Insert user error:', err);
    res.status(500).json({ error: 'Database error' });
  } finally {
    client.release();
  }
});

// GET /employees
router.get('/', async (req, res) => {
  const currentuser = req.query.currentuser || 'system';
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    await client.query('SELECT * FROM get_employeedetails($1, $2)', [currentuser, 'ref1']);

    const cursorResult = await client.query('FETCH ALL FROM ref1');

    await client.query('CLOSE ref1');
    await client.query('COMMIT');

    res.status(200).json(cursorResult.rows);

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Get employees error:', err);
    res.status(500).json({ error: 'Database error' });
  } finally {
    client.release();
  }
});

// PUT /employees/:id
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const {
    entryby,
    empname,
    empdesignation,
    empsalary,
    empdob,
    empmobile,
    emplocation,
    empemail
  } = req.body;

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    await client.query(
      'SELECT * FROM update_employeemaster($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)',
      [
        id,
        entryby,
        empname,
        empdesignation,
        empsalary,
        empdob,
        empmobile,
        emplocation,
        empemail,
        'ref1'
      ]
    );

    const result = await client.query('FETCH ALL FROM ref1');

    await client.query('CLOSE ref1');
    await client.query('COMMIT');

    res.status(200).json({
      message: result.rows[0].result
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Update employee error:', err);
    res.status(500).json({ error: 'Database error' });
  } finally {
    client.release();
  }
});

// DELETE /employees/:id
router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Call your function
    await client.query(
      'SELECT * FROM delete_employeedetails($1, $2)',
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
