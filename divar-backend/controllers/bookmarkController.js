const db = require('../config/db');

async function addBookmark(req, res) {
  try {
    const { user_phone_number, ad_id } = req.body;
    if (!user_phone_number || !ad_id) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    const result = await db.raw(
      'INSERT INTO bookmarks (user_phone_number, ad_id) VALUES (?, ?)',
      [user_phone_number, ad_id]
    );
    res.status(201).json({ message: 'Bookmark added', bookmark_id: result[0].insertId });
  } catch (error) {
    console.error('Error adding bookmark:', error);
    res.status(500).json({ error: error.message });
  }
}

async function getBookmarks(req, res) {
  try {
    const { user_phone_number } = req.params;
    const bookmarksResult = await db.raw(
      `
      SELECT 
        b.bookmark_id, b.ad_id, a.title, a.description, a.ad_type, a.price, 
        a.province_id, a.city_id, a.owner_phone_number, a.created_at, a.status,
        p.name AS province_name, c.name AS city_name
      FROM bookmarks b
      JOIN advertisements a ON b.ad_id = a.ad_id
      LEFT JOIN provinces p ON a.province_id = p.province_id
      LEFT JOIN cities c ON a.city_id = c.city_id
      WHERE b.user_phone_number = ?
      `,
      [user_phone_number]
    );
    const bookmarks = bookmarksResult[0];

    const result = await Promise.all(
      bookmarks.map(async (bookmark) => {
        // Fetch images
        const imagesResult = await db.raw(
          'SELECT image_url FROM ad_images WHERE ad_id = ?',
          [bookmark.ad_id]
        );
        const imageUrls = imagesResult[0].map((img) => img.image_url).filter((url) => url != null);

        // Fetch type-specific details
        let specificDetails = {};
        if (bookmark.ad_type === 'REAL_ESTATE') {
          const realEstateResult = await db.raw(
            `
            SELECT real_estate_type, area, construction_year, rooms, total_price, 
                   price_per_meter, has_parking, has_storage, has_balcony, deposit, 
                   monthly_rent, floor
            FROM real_estate_ads
            WHERE ad_id = ?
            `,
            [bookmark.ad_id]
          );
          specificDetails = realEstateResult[0][0] || {};
          if (specificDetails.real_estate_type === 'SALE') {
            specificDetails.deposit = null;
            specificDetails.monthly_rent = null;
          }
        } else if (bookmark.ad_type === 'VEHICLE') {
          const vehicleResult = await db.raw(
            `
            SELECT brand, model, mileage, color, gearbox, base_price, 
                   engine_status, chassis_status, body_status
            FROM vehicle_ads
            WHERE ad_id = ?
            `,
            [bookmark.ad_id]
          );
          specificDetails = vehicleResult[0][0] || {};
        }

        return {
          bookmark_id: bookmark.bookmark_id,
          ad_id: bookmark.ad_id,
          title: bookmark.title,
          description: bookmark.description,
          ad_type: bookmark.ad_type,
          price: bookmark.price,
          province_id: bookmark.province_id,
          city_id: bookmark.city_id,
          owner_phone_number: bookmark.owner_phone_number,
          created_at: bookmark.created_at,
          status: bookmark.status,
          province_name: bookmark.province_name,
          city_name: bookmark.city_name,
          images: imageUrls,
          ...specificDetails,
        };
      })
    );

    res.json(result);
  } catch (error) {
    console.error('Error fetching bookmarks:', error);
    res.status(500).json({ error: error.message });
  }
}

async function deleteBookmark(req, res) {
  try {
    const { bookmarkId } = req.params;
    const result = await db.raw(
      'DELETE FROM bookmarks WHERE bookmark_id = ?',
      [bookmarkId]
    );
    if (result[0].affectedRows === 0) {
      return res.status(404).json({ error: 'Bookmark not found' });
    }
    res.json({ message: 'Bookmark deleted' });
  } catch (error) {
    console.error('Error deleting bookmark:', error);
    res.status(500).json({ error: error.message });
  }
}

module.exports = { addBookmark, getBookmarks, deleteBookmark };
