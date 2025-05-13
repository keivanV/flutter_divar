// Bookmark model
const pool = require('../config/db');

const bookmarkModel = {
  async addBookmark({ user_phone_number, ad_id }) {
    const query = `
      INSERT INTO bookmarks (user_phone_number, ad_id)
      VALUES (?, ?)
    `;
    const [result] = await pool.execute(query, [user_phone_number, ad_id]);
    return result;
  },

  async getBookmarks(user_phone_number) {
    const query = `
      SELECT b.*, a.title, a.ad_type, p.name as province_name, c.name as city_name
      FROM bookmarks b
      JOIN advertisements a ON b.ad_id = a.ad_id
      JOIN provinces p ON a.province_id = p.province_id
      JOIN cities c ON a.city_id = c.city_id
      WHERE b.user_phone_number = ?
    `;
    const [rows] = await pool.execute(query, [user_phone_number]);
    return rows;
  }
};

module.exports = bookmarkModel;