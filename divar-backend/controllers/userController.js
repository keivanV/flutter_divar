const db = require('../config/db');

async function registerUser(req, res) {
  try {
    const { phone_number, first_name, last_name, nickname, province_id, city_id } = req.body;

    const missingFields = [];
    if (!phone_number) missingFields.push('phone_number');
    if (!first_name) missingFields.push('first_name');
    if (!last_name) missingFields.push('last_name');
    if (!nickname) missingFields.push('nickname');
    if (!province_id) missingFields.push('province_id');
    if (!city_id) missingFields.push('city_id');

    if (missingFields.length > 0) {
      return res.status(400).json({ 
        message: `فیلدهای الزامی پر نشده‌اند: ${missingFields.join(', ')}`,
        missingFields 
      });
    }

    await db.raw(
      `INSERT INTO users (phone_number, first_name, last_name, nickname, province_id, city_id, account_level)
       VALUES (?, ?, ?, ?, ?, ?, 'LEVEL_1')`,
      [phone_number, first_name, last_name, nickname, province_id, city_id]
    );

    res.status(201).json({ message: 'کاربر با موفقیت ثبت شد' });
  } catch (error) {
    console.error('Error registering user:', error);
    res.status(500).json({ message: `خطا در ثبت کاربر: ${error.message}` });
  }
}

async function getUserProfile(req, res) {
  try {
    const { phoneNumber } = req.params;
    const result = await db.raw(
      `SELECT phone_number, first_name, last_name, nickname, province_id, city_id, account_level, created_at
       FROM users WHERE phone_number = ?`,
      [phoneNumber]
    );

    if (result[0].length === 0) {
      return res.status(404).json({ message: 'کاربر یافت نشد' });
    }

    res.json(result[0][0]);
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ message: `خطا در دریافت پروفایل: ${error.message}` });
  }
}

async function getUserAds(req, res) {
  try {
    const { phoneNumber } = req.params;
    console.log(`Fetching ads for phoneNumber: ${phoneNumber}`);

    // Validate phoneNumber
    if (!phoneNumber) {
      console.error('Phone number is undefined or empty');
      return res.status(400).json({ message: 'شماره تلفن الزامی است' });
    }

    // Fetch basic ad details
    const adsQuery = `
      SELECT 
        a.ad_id, a.title, a.description, a.ad_type, a.price, a.province_id, a.city_id, 
        a.owner_phone_number, a.created_at, a.status,
        p.name AS province_name, c.name AS city_name
      FROM advertisements a
      LEFT JOIN provinces p ON a.province_id = p.province_id
      LEFT JOIN cities c ON a.city_id = c.city_id
      WHERE a.owner_phone_number = ?
      ORDER BY a.created_at DESC
    `;
    const adsResult = await db.raw(adsQuery, [phoneNumber]);
    const ads = adsResult[0];
    console.log(`Found ${ads.length} ads for phoneNumber: ${phoneNumber}`);

    const result = await Promise.all(
      ads.map(async (ad) => {
        // Fetch images
        const imagesQuery = `
          SELECT image_url 
          FROM ad_images 
          WHERE ad_id = ?
        `;
        const imagesResult = await db.raw(imagesQuery, [ad.ad_id]);
        const images = imagesResult[0].map(row => row.image_url).filter(url => url != null);
        console.log(`Fetched ${images.length} images for ad_id: ${ad.ad_id}`);

        // Fetch specific details
        let specificDetails = {};
        if (ad.ad_type === 'REAL_ESTATE') {
          const realEstateQuery = `
            SELECT real_estate_type, area, construction_year, rooms, total_price, 
                   price_per_meter, has_parking, has_storage, has_balcony, deposit, 
                   monthly_rent, floor
            FROM real_estate_ads 
            WHERE ad_id = ?
          `;
          const realEstateResult = await db.raw(realEstateQuery, [ad.ad_id]);
          specificDetails = realEstateResult[0][0] || {};
          if (specificDetails.real_estate_type === 'SALE') {
            specificDetails.deposit = null;
            specificDetails.monthly_rent = null;
          }
          console.log(`Fetched real estate details for ad_id: ${ad.ad_id}`);
        } else if (ad.ad_type === 'VEHICLE') {
          const vehicleQuery = `
            SELECT brand, model, mileage, color, gearbox, base_price, 
                   engine_status, chassis_status, body_status
            FROM vehicle_ads 
            WHERE ad_id = ?
          `;
          const vehicleResult = await db.raw(vehicleQuery, [ad.ad_id]);
          specificDetails = vehicleResult[0][0] || {};
          console.log(`Fetched vehicle details for ad_id: ${ad.ad_id}`);
        }

        return {
          ...ad,
          images,
          ...specificDetails,
        };
      })
    );

    res.json(result);
  } catch (error) {
    console.error('Error fetching user ads:', {
      message: error.message,
      stack: error.stack,
      phoneNumber: req.params.phoneNumber,
    });
    res.status(500).json({ message: `خطا در دریافت آگهی‌های کاربر: ${error.message}` });
  }
}

module.exports = {
  registerUser,
  getUserProfile,
  getUserAds,
};
