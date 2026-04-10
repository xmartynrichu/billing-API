const express = require('express');
const router = express.Router();
const pool = require('../DB/db');



router.post('/', async (req, res) => {
  const {
    user_name,
    user_id,
    pass_wrd,
    dateofbirth,
    mobile_number,
    email_id,
    createdby
  } = req.body;

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    await client.query(
      'SELECT * FROM insert_userdetails($1,$2,$3,$4,$5,$6,$7,$8)',
      [
        user_name,
        user_id,
        pass_wrd,
        dateofbirth,
        mobile_number,
        email_id,
        createdby,
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

// GET /users
router.get('/', async (req, res) => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    await client.query('SELECT * FROM get_userdetails($1)', ['ref1']);

    const cursorResult = await client.query('FETCH ALL FROM ref1');

    await client.query('CLOSE ref1');
    await client.query('COMMIT');

    res.status(200).json(cursorResult.rows);

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Get users error:', err);
    res.status(500).json({ error: 'Database error' });
  } finally {
    client.release();
  }
});

// DELETE /users/:id
router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Call your function
    await client.query(
      'SELECT * FROM delete_userdetails($1, $2)',
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



router.post('/usercheck', async (req, res) => {
  const {
    username,
  
    pwd  
   
  } = req.body;

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    await client.query(
      'SELECT * FROM check_userdetails($1,$2,$3)',
      [
        username,
        pwd,
       
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
    console.error('Check user error:', err);
    res.status(500).json({ error: 'Database error' });
  } finally {
    client.release();
  }
});




module.exports = router;

module.exports = router;
