const db = require('../config/db');

// Get all ads
async function getAds(req, res) {
  try {
    const { ad_type, province_id, city_id, sort_by } = req.query;
    let query = `
      SELECT 
        a.ad_id, a.title, a.description, a.ad_type, a.price, a.province_id, a.city_id, 
        a.owner_phone_number, a.created_at, a.status,
        p.name AS province_name, c.name AS city_name,
        COALESCE(JSON_ARRAYAGG(i.image_url), '[]') AS images
      FROM advertisements a
      LEFT JOIN provinces p ON a.province_id = p.province_id
      LEFT JOIN cities c ON a.city_id = c.city_id
      LEFT JOIN ad_images i ON a.ad_id = i.ad_id
    `;
    const params = [];

    if (ad_type === 'REAL_ESTATE') {
      query += `
        LEFT JOIN real_estate_ads re ON a.ad_id = re.ad_id
      `;
    } else if (ad_type === 'VEHICLE') {
      query += `
        LEFT JOIN vehicle_ads v ON a.ad_id = v.ad_id
      `;
    }

    if (ad_type) {
      query += ` AND a.ad_type = ?`;
      params.push(ad_type);
    }
    if (province_id) {
      query += ` AND a.province_id = ?`;
      params.push(province_id);
    }
    if (city_id) {
      query += ` AND a.city_id = ?`;
      params.push(city_id);
    }

    query += ` GROUP BY a.ad_id`;

    if (sort_by === 'price_asc') {
      query += ` ORDER BY a.price ASC`;
    } else if (sort_by === 'price_desc') {
      query += ` ORDER BY a.price DESC`;
    } else {
      query += ` ORDER BY a.created_at DESC`;
    }

    const adsResult = await db.raw(query, params);
    const ads = adsResult[0];

    const result = await Promise.all(
      ads.map(async (ad) => {
        let specificDetails = {};
        if (ad.ad_type === 'REAL_ESTATE') {
          const realEstateResult = await db.raw(
            `SELECT real_estate_type, area, construction_year, rooms, total_price, 
                    price_per_meter, has_parking, has_storage, has_balcony, deposit, 
                    monthly_rent, floor
             FROM real_estate_ads WHERE ad_id = ?`,
            [ad.ad_id]
          );
          specificDetails = realEstateResult[0][0] || {};
        } else if (ad.ad_type === 'VEHICLE') {
          const vehicleResult = await db.raw(
            `SELECT brand, model, mileage, color, gearbox, base_price, 
                    engine_status, chassis_status, body_status
             FROM vehicle_ads WHERE ad_id = ?`,
            [ad.ad_id]
          );
          specificDetails = vehicleResult[0][0] || {};
        }
        return {
          ...ad,
          images: ad.images ? (() => {
            try {
              const parsed = JSON.parse(ad.images);
              return Array.isArray(parsed) ? parsed.filter(url => url !== null) : [];
            } catch (e) {
              console.error(`Failed to parse images for ad_id ${ad.ad_id}:`, e.message);
              return [];
            }
          })() : [],
          ...specificDetails,
        };
      })
    );

    res.json(result);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: `خطا در دریافت آگهی‌ها: ${error.message}` });
  }
}

// Create a new ad
async function createAd(req, res) {
  try {
    console.log('Received ad creation request:', {
      body: req.body,
      files: req.files,
    });

    const {
      title,
      description,
      ad_type,
      price,
      province_id,
      city_id,
      owner_phone_number,
      real_estate_type,
      area,
      construction_year,
      rooms,
      total_price,
      price_per_meter,
      has_parking,
      has_storage,
      has_balcony,
      deposit,
      monthly_rent,
      floor,
      brand,
      model,
      mileage,
      color,
      gearbox,
      base_price,
      engine_status,
      chassis_status,
      body_status,
    } = req.body;

    // Validate required fields with detailed logging
    const missingFields = [];
    if (!title || title.trim() === '') missingFields.push('title');
    if (!description || description.trim() === '') missingFields.push('description');
    if (!ad_type || !['VEHICLE', 'REAL_ESTATE'].includes(ad_type)) missingFields.push('ad_type');
    if (!price || isNaN(parseInt(price))) missingFields.push('price');
    if (!province_id || isNaN(parseInt(province_id))) missingFields.push('province_id');
    if (!city_id || isNaN(parseInt(city_id))) missingFields.push('city_id');
    if (!owner_phone_number || owner_phone_number.trim() === '') missingFields.push('owner_phone_number');

    if (missingFields.length > 0) {
      console.log('Validation failed for fields:', missingFields);
      return res.status(400).json({ 
        message: `فیلدهای الزامی پر نشده‌اند: ${missingFields.join(', ')}`,
        missingFields 
      });
    }

    // Convert string fields to appropriate types
    const parsedPrice = parseInt(price);
    const parsedProvinceId = parseInt(province_id);
    const parsedCityId = parseInt(city_id);
    const parsedBasePrice = ad_type === 'VEHICLE' ? parseInt(base_price) : null;

    // Additional validation
    if (isNaN(parsedPrice) || parsedPrice < 0) {
      return res.status(400).json({ message: 'قیمت باید یک عدد معتبر باشد' });
    }
    if (isNaN(parsedProvinceId)) {
      return res.status(400).json({ message: 'شناسه استان باید یک عدد معتبر باشد' });
    }
    if (isNaN(parsedCityId)) {
      return res.status(400).json({ message: 'شناسه شهر باید یک عدد معتبر باشد' });
    }
    if (ad_type === 'VEHICLE' && (isNaN(parsedBasePrice) || parsedBasePrice < 0)) {
      return res.status(400).json({ message: 'قیمت پایه باید یک عدد معتبر باشد' });
    }

    // Validate image uploads
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ message: 'حداقل یک تصویر برای آگهی الزامی است' });
    }

    // Start a transaction
    await db.raw('START TRANSACTION');

    // Insert into advertisements table
    const adResult = await db.raw(
      `INSERT INTO advertisements (title, ad_type, status, owner_phone_number, province_id, city_id, description, price)
       VALUES (?, ?, 'PENDING', ?, ?, ?, ?, ?)`,
      [title, ad_type, owner_phone_number, parsedProvinceId, parsedCityId, description, parsedPrice]
    );
    const ad_id = adResult[0].insertId;

    // Handle images
    const baseUrl = process.env.BASE_URL || 'http://localhost:5000';
    const imageUrls = req.files.map(file => `${baseUrl}/uploads/${file.filename}`);
    for (const imageUrl of imageUrls) {
      if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
        throw new Error(`URL تصویر نامعتبر است: ${imageUrl}`);
      }
      await db.raw(
        `INSERT INTO ad_images (ad_id, image_url) VALUES (?, ?)`,
        [ad_id, imageUrl]
      );
    }

    // Handle specific ad types
    if (ad_type === 'REAL_ESTATE') {
      if (!real_estate_type || !area || !rooms || !total_price || !price_per_meter || floor === undefined) {
        throw new Error('فیلدهای الزامی املاک (نوع معامله، مساحت، تعداد اتاق، قیمت کل، قیمت هر متر، طبقه) پر نشده‌اند');
      }
      await db.raw(
        `INSERT INTO real_estate_ads (
          ad_id, real_estate_type, area, construction_year, rooms, total_price, price_per_meter,
          has_parking, has_storage, has_balcony, deposit, monthly_rent, floor
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          ad_id,
          real_estate_type,
          parseInt(area) || null,
          parseInt(construction_year) || null,
          parseInt(rooms) || null,
          parseInt(total_price) || null,
          parseInt(price_per_meter) || null,
          has_parking === 'true' ? 1 : 0,
          has_storage === 'true' ? 1 : 0,
          has_balcony === 'true' ? 1 : 0,
          parseInt(deposit) || null,
          parseInt(monthly_rent) || null,
          parseInt(floor) || null,
        ]
      );
    } else if (ad_type === 'VEHICLE') {
      if (!brand || !model || !mileage || !color || !gearbox || !base_price || !engine_status || !chassis_status || !body_status) {
        throw new Error('فیلدهای الزامی خودرو (برند، مدل، کارکرد، رنگ، گیربکس، قیمت پایه، وضعیت موتور، وضعیت شاسی، وضعیت بدنه) پر نشده‌اند');
      }
      await db.raw(
        `INSERT INTO vehicle_ads (
          ad_id, mileage, color, brand, model, gearbox, base_price, engine_status, chassis_status, body_status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          ad_id,
          parseInt(mileage) || null,
          color,
          brand,
          model,
          gearbox,
          parsedBasePrice,
          engine_status,
          chassis_status,
          body_status,
        ]
      );
    }

    await db.raw('COMMIT');
    res.status(201).json({ message: 'آگهی با موفقیت ثبت شد', ad_id, images: imageUrls });
  } catch (error) {
    await db.raw('ROLLBACK');
    console.error('Error details:', {
      message: error.message,
      stack: error.stack,
      body: req.body,
      files: req.files,
    });
    res.status(500).json({ message: `خطا در ثبت آگهی: ${error.message}` });
  }
}

module.exports = {
  getAds,
  createAd,
};