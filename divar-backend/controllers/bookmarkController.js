
const mysql = require('mysql2/promise');

// MySQL connection pool
const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: 'root',
  database: 'divar_app',
});

exports.addBookmark = async (req, res, next) => {
  try {
    const { user_phone_number, ad_id } = req.body;
    if (!user_phone_number || !ad_id) {
      return res.status(400).json({ error: 'user_phone_number and ad_id are required' });
    }
    console.log(`Adding bookmark for user: ${user_phone_number}, ad_id: ${ad_id}`);
    
    // Check for duplicate bookmark
    const [existing] = await pool.query(
      'SELECT bookmark_id FROM bookmarks WHERE user_phone_number = ? AND ad_id = ?',
      [user_phone_number, ad_id]
    );
    if (existing.length > 0) {
      return res.status(400).json({ error: 'Bookmark already exists' });
    }
    
    const [result] = await pool.query(
      'INSERT INTO bookmarks (user_phone_number, ad_id) VALUES (?, ?)',
      [user_phone_number, ad_id]
    );
    res.status(201).json({ message: 'Bookmark added', bookmark_id: result.insertId });
  } catch (err) {
    console.error('Error adding bookmark:', err);
    next(err);
  }
};

exports.getBookmarks = async (req, res, next) => {
  try {
    const { user_phone_number } = req.params;
    console.log(`Fetching bookmarks for user: ${user_phone_number}`);
    const [bookmarks] = await pool.query(
      `SELECT b.bookmark_id, a.*, GROUP_CONCAT(i.image_url) as images
       FROM advertisements a
       INNER JOIN bookmarks b ON a.ad_id = b.ad_id
       LEFT JOIN ad_images i ON a.ad_id = i.ad_id
       WHERE b.user_phone_number = ?
       GROUP BY b.bookmark_id, a.ad_id`,
      [user_phone_number]
    );
    res.json(bookmarks.map(ad => ({
      ...ad,
      images: ad.images ? ad.images.split(',') : [],
      bookmark_id: ad.bookmark_id,
    })));
  } catch (err) {
    console.error('Error fetching bookmarks:', err);
    next(err);
  }
};

exports.deleteBookmark = async (req, res, next) => {
  try {
    const { bookmarkId } = req.params;
    console.log(`Deleting bookmark_id: ${bookmarkId}`);
    const [result] = await pool.query(
      'DELETE FROM bookmarks WHERE bookmark_id = ?',
      [bookmarkId]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Bookmark not found' });
    }
    res.json({ message: 'Bookmark removed' });
  } catch (err) {
    console.error('Error deleting bookmark:', err);
    next(err);
  }
};
