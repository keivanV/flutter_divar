const db = require('../config/db');



// Get ad by ID
async function getAdById(req, res) {
  try {
    const { ad_id } = req.params;
    const query = `
      SELECT 
        a.ad_id, a.title, a.description, a.ad_type, a.price, a.province_id, a.city_id, 
        a.owner_phone_number, a.created_at, a.status,
        p.name AS province_name, c.name AS city_name
      FROM advertisements a
      LEFT JOIN provinces p ON a.province_id = p.province_id
      LEFT JOIN cities c ON a.city_id = c.city_id
      WHERE a.ad_id = ?
    `;
    const params = [ad_id];

    const adResult = await db.raw(query, params);
    const ads = adResult[0];

    if (ads.length === 0) {
      return res.status(404).json({ message: 'آگهی یافت نشد' });
    }

    const ad = ads[0];

    const imagesQuery = `
      SELECT image_url 
      FROM ad_images 
      WHERE ad_id = ?
    `;
    const imagesResult = await db.raw(imagesQuery, [ad.ad_id]);
    const images = imagesResult[0].map(row => row.image_url).filter(url => url != null);

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
      if (specificDetails.real_estate_type === 'SALE') {
        specificDetails.deposit = null;
        specificDetails.monthly_rent = null;
      }
    } else if (ad.ad_type === 'VEHICLE') {
      const vehicleResult = await db.raw(
        `SELECT brand, model, mileage, color, gearbox, base_price, 
                engine_status, chassis_status, body_status
         FROM vehicle_ads WHERE ad_id = ?`,
        [ad.ad_id]
      );
      specificDetails = vehicleResult[0][0] || {};
    }

    const result = {
      ...ad,
      images,
      ...specificDetails,
    };

    res.json(result);
  } catch (error) {
    console.error('Error fetching ad by ID:', error);
    res.status(500).json({ message: `خطا در دریافت آگهی: ${error.message}` });
  }
}



// Get all ads
async function getAds(req, res) {
  try {
    const { ad_type, province_id, city_id, sort_by } = req.query;
    let query = `
      SELECT 
        a.ad_id, a.title, a.description, a.ad_type, a.price, a.province_id, a.city_id, 
        a.owner_phone_number, a.created_at, a.status,
        p.name AS province_name, c.name AS city_name
      FROM advertisements a
      LEFT JOIN provinces p ON a.province_id = p.province_id
      LEFT JOIN cities c ON a.city_id = c.city_id
    `;
    const params = [];

    if (ad_type === 'REAL_ESTATE') {
      query += ` LEFT JOIN real_estate_ads re ON a.ad_id = re.ad_id `;
    } else if (ad_type === 'VEHICLE') {
      query += ` LEFT JOIN vehicle_ads v ON a.ad_id = v.ad_id `;
    }

    if (ad_type) {
      query += ` WHERE a.ad_type = ?`;
      params.push(ad_type);
    }
    if (province_id) {
      query += ` ${ad_type ? 'AND' : 'WHERE'} a.province_id = ?`;
      params.push(province_id);
    }
    if (city_id) {
      query += ` ${ad_type || province_id ? 'AND' : 'WHERE'} a.city_id = ?`;
      params.push(city_id);
    }

    query += ` GROUP BY a.ad_id`;

    if (sort_by === 'price_asc') {
      query += ` ORDER BY a.price IS NULL, a.price ASC, a.created_at DESC`;
    } else if (sort_by === 'price_desc') {
      query += ` ORDER BY a.price IS NULL, a.price DESC, a.created_at DESC`;
    } else if (sort_by === 'newest') {
      query += ` ORDER BY a.created_at DESC`;
    } else if (sort_by === 'oldest') {
      query += ` ORDER BY a.created_at ASC`;
    } else {
      query += ` ORDER BY a.created_at DESC`;
    }

    const adsResult = await db.raw(query, params);
    const ads = adsResult[0];

    const result = await Promise.all(
      ads.map(async (ad) => {
        const imagesQuery = `
          SELECT image_url 
          FROM ad_images 
          WHERE ad_id = ?
        `;
        const imagesResult = await db.raw(imagesQuery, [ad.ad_id]);
        const images = imagesResult[0].map(row => row.image_url).filter(url => url != null);

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
          if (specificDetails.real_estate_type === 'SALE') {
            specificDetails.deposit = null;
            specificDetails.monthly_rent = null;
          }
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
          images,
          ...specificDetails,
        };
      })
    );

    res.json(result);
  } catch (error) {
    console.error('Error fetching ads:', error);
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
      ad_type,
      price,
      province_id,
      city_id,
      owner_phone_number,
      description,
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

    const parsedPrice = parseInt(price);
    const parsedProvinceId = parseInt(province_id);
    const parsedCityId = parseInt(city_id);
    const parsedBasePrice = ad_type === 'VEHICLE' ? parseInt(base_price) : null;
    const parsedTotalPrice = ad_type === 'REAL_ESTATE' ? parseInt(total_price) : null;

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
    if (ad_type === 'REAL_ESTATE' && (isNaN(parsedTotalPrice) || parsedTotalPrice < 0)) {
      return res.status(400).json({ message: 'قیمت کل باید یک عدد معتبر باشد' });
    }

    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ message: 'حداقل یک تصویر برای آگهی الزامی است' });
    }

    await db.raw('START TRANSACTION');

    const adResult = await db.raw(
      `INSERT INTO advertisements (title, ad_type, status, owner_phone_number, province_id, city_id, description, price)
       VALUES (?, ?, 'PENDING', ?, ?, ?, ?, ?)`,
      [title, ad_type, owner_phone_number, parsedProvinceId, parsedCityId, description, parsedPrice]
    );
    const ad_id = adResult[0].insertId;

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

    if (ad_type === 'REAL_ESTATE') {
      if (!real_estate_type || !area || !rooms || !total_price || !price_per_meter || floor === undefined) {
        throw new Error('فیلدهای الزامی املاک پر نشده‌اند');
      }
      const parsedDeposit = real_estate_type === 'RENT' ? parseInt(deposit) || null : null;
      const parsedMonthlyRent = real_estate_type === 'RENT' ? parseInt(monthly_rent) || null : null;
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
          parsedTotalPrice,
          parseInt(price_per_meter) || null,
          has_parking === 'true' ? 1 : 0,
          has_storage === 'true' ? 1 : 0,
          has_balcony === 'true' ? 1 : 0,
          parsedDeposit,
          parsedMonthlyRent,
          parseInt(floor) || null,
        ]
      );
    } else if (ad_type === 'VEHICLE') {
      if (!brand || !model || !mileage || !color || !gearbox || !base_price || !engine_status || !chassis_status || !body_status) {
        throw new Error('فیلدهای الزامی خودرو پر نشده‌اند');
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
    console.error('Error creating ad:', error);
    res.status(500).json({ message: `خطا در ثبت آگهی: ${error.message}` });
  }
}

// Update an ad
async function updateAd(req, res) {
  try {
    const { ad_id } = req.params;
    const { title, description, price } = req.body;

    const missingFields = [];
    if (!title || title.trim() === '') missingFields.push('title');
    if (!description || description.trim() === '') missingFields.push('description');
    if (!price || isNaN(parseInt(price))) missingFields.push('price');

    if (missingFields.length > 0) {
      return res.status(400).json({ 
        message: `فیلدهای الزامی پر نشده‌اند: ${missingFields.join(', ')}`,
        missingFields 
      });
    }

    const parsedPrice = parseInt(price);

    await db.raw('START TRANSACTION');

    const updateResult = await db.raw(
      `UPDATE advertisements 
       SET title = ?, description = ?, price = ?
       WHERE ad_id = ?`,
      [title, description, parsedPrice, ad_id]
    );

    if (updateResult[0].affectedRows === 0) {
      await db.raw('ROLLBACK');
      return res.status(404).json({ message: 'آگهی یافت نشد' });
    }

    await db.raw('COMMIT');
    res.json({ message: 'آگهی با موفقیت ویرایش شد' });
  } catch (error) {
    await db.raw('ROLLBACK');
    console.error('Error updating ad:', error);
    res.status(500).json({ message: `خطا در ویرایش آگهی: ${error.message}` });
  }
}

// Delete an ad
async function deleteAd(req, res) {
  try {
    const { ad_id } = req.params;
    console.log(`Deleting ad with ad_id: ${ad_id}`);

    // Validate ad_id
    const parsedAdId = parseInt(ad_id);
    if (isNaN(parsedAdId)) {
      console.error('Invalid ad_id:', ad_id);
      return res.status(400).json({ message: 'شناسه آگهی نامعتبر است' });
    }

    await db.raw('START TRANSACTION');

    // Delete related records
    await db.raw(`DELETE FROM ad_images WHERE ad_id = ?`, [parsedAdId]);
    console.log(`Deleted ad_images for ad_id: ${parsedAdId}`);
    await db.raw(`DELETE FROM real_estate_ads WHERE ad_id = ?`, [parsedAdId]);
    console.log(`Deleted real_estate_ads for ad_id: ${parsedAdId}`);
    await db.raw(`DELETE FROM vehicle_ads WHERE ad_id = ?`, [parsedAdId]);
    console.log(`Deleted vehicle_ads for ad_id: ${parsedAdId}`);

    // Delete advertisement
    const deleteResult = await db.raw(
      `DELETE FROM advertisements WHERE ad_id = ?`,
      [parsedAdId]
    );

    if (deleteResult[0].affectedRows === 0) {
      await db.raw('ROLLBACK');
      console.log(`No ad found with ad_id: ${parsedAdId}`);
      return res.status(404).json({ message: 'آگهی یافت نشد' });
    }

    await db.raw('COMMIT');
    console.log(`Successfully deleted ad with ad_id: ${parsedAdId}`);
    res.json({ message: 'آگهی با موفقیت حذف شد' });
  } catch (error) {
    await db.raw('ROLLBACK');
    console.error('Error deleting ad:', {
      message: error.message,
      stack: error.stack,
      ad_id: req.params.ad_id,
    });
    res.status(500).json({ message: `خطا در حذف آگهی: ${error.message}` });
  }
}

module.exports = {
  getAds,
  getAdById,
  createAd,
  updateAd,
  deleteAd,
};
