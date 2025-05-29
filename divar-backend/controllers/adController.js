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
    } else if (ad.ad_type === 'DIGITAL') {
      const digitalResult = await db.raw(
        `SELECT brand, model, item_condition
         FROM digital_ads WHERE ad_id = ?`,
        [ad.ad_id]
      );
      specificDetails = digitalResult[0][0] || {};
    } else if (ad.ad_type === 'HOME') {
      const homeResult = await db.raw(
        `SELECT brand, model, item_condition
         FROM home_ads WHERE ad_id = ?`,
        [ad.ad_id]
      );
      specificDetails = homeResult[0][0] || {};
    } else if (ad.ad_type === 'PERSONAL') {
      const personalResult = await db.raw(
        `SELECT brand, model, item_condition
         FROM personal_ads WHERE ad_id = ?`,
        [ad.ad_id]
      );
      specificDetails = personalResult[0][0] || {};
    } else if (ad.ad_type === 'ENTERTAINMENT') {
      const entertainmentResult = await db.raw(
        `SELECT brand, model, item_condition
         FROM entertainment_ads WHERE ad_id = ?`,
        [ad.ad_id]
      );
      specificDetails = entertainmentResult[0][0] || {};
    } else if (ad.ad_type === 'SERVICES') {
      const servicesResult = await db.raw(
        `SELECT service_type, service_duration
         FROM services_ads WHERE ad_id = ?`,
        [ad.ad_id]
      );
      specificDetails = servicesResult[0][0] || {};
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

    // Join with category-specific tables
    if (ad_type === 'REAL_ESTATE') {
      query += ` LEFT JOIN real_estate_ads re ON a.ad_id = re.ad_id `;
    } else if (ad_type === 'VEHICLE') {
      query += ` LEFT JOIN vehicle_ads v ON a.ad_id = v.ad_id `;
    } else if (ad_type === 'DIGITAL') {
      query += ` LEFT JOIN digital_ads d ON a.ad_id = d.ad_id `;
    } else if (ad_type === 'HOME') {
      query += ` LEFT JOIN home_ads h ON a.ad_id = h.ad_id `;
    } else if (ad_type === 'PERSONAL') {
      query += ` LEFT JOIN personal_ads pr ON a.ad_id = pr.ad_id `;
    } else if (ad_type === 'ENTERTAINMENT') {
      query += ` LEFT JOIN entertainment_ads e ON a.ad_id = e.ad_id `;
    } else if (ad_type === 'SERVICES') {
      query += ` LEFT JOIN services_ads s ON a.ad_id = s.ad_id `;
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
        } else if (ad.ad_type === 'DIGITAL') {
          const digitalResult = await db.raw(
            `SELECT brand, model, item_condition
             FROM digital_ads WHERE ad_id = ?`,
            [ad.ad_id]
          );
          specificDetails = digitalResult[0][0] || {};
        } else if (ad.ad_type === 'HOME') {
          const homeResult = await db.raw(
            `SELECT brand, model, item_condition
             FROM home_ads WHERE ad_id = ?`,
            [ad.ad_id]
          );
          specificDetails = homeResult[0][0] || {};
        } else if (ad.ad_type === 'PERSONAL') {
          const personalResult = await db.raw(
            `SELECT brand, model, item_condition
             FROM personal_ads WHERE ad_id = ?`,
            [ad.ad_id]
          );
          specificDetails = personalResult[0][0] || {};
        } else if (ad.ad_type === 'ENTERTAINMENT') {
          const entertainmentResult = await db.raw(
            `SELECT brand, model, item_condition
             FROM entertainment_ads WHERE ad_id = ?`,
            [ad.ad_id]
          );
          specificDetails = entertainmentResult[0][0] || {};
        } else if (ad.ad_type === 'SERVICES') {
          const servicesResult = await db.raw(
            `SELECT service_type, service_duration
             FROM services_ads WHERE ad_id = ?`,
            [ad.ad_id]
          );
          specificDetails = servicesResult[0][0] || {};
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

// Create a new comment
async function createComment(req, res) {
  try {
    const { ad_id } = req.params;
    const { user_phone_number, content } = req.body;

    // Validate input
    const missingFields = [];
    if (!user_phone_number || user_phone_number.trim() === '') missingFields.push('user_phone_number');
    if (!content || content.trim() === '') missingFields.push('content');
    if (!ad_id || isNaN(parseInt(ad_id))) missingFields.push('ad_id');

    if (missingFields.length > 0) {
      return res.status(400).json({
        message: `فیلدهای الزامی پر نشده‌اند: ${missingFields.join(', ')}`,
        missingFields,
      });
    }

    const parsedAdId = parseInt(ad_id);

    // Check if ad exists
    const adCheck = await db.raw('SELECT 1 FROM advertisements WHERE ad_id = ?', [parsedAdId]);
    if (adCheck[0].length === 0) {
      return res.status(404).json({ message: 'آگهی یافت نشد' });
    }

    // Check if user exists
    const userCheck = await db.raw('SELECT 1 FROM users WHERE phone_number = ?', [user_phone_number]);
    if (userCheck[0].length === 0) {
      return res.status(404).json({ message: 'کاربر یافت نشد' });
    }

    await db.raw('START TRANSACTION');

    const commentResult = await db.raw(
      `INSERT INTO comments (ad_id, user_phone_number, content) VALUES (?, ?, ?)`,
      [parsedAdId, user_phone_number, content]
    );

    const commentId = commentResult[0].insertId;

    await db.raw('COMMIT');

    res.status(201).json({ message: 'کامنت با موفقیت ثبت شد', comment_id: commentId });
  } catch (error) {
    await db.raw('ROLLBACK');
    console.error('Error creating comment:', error);
    res.status(500).json({ message: `خطا در ثبت کامنت: ${error.message}` });
  }
}

// Fetch comments for an ad
async function getComments(req, res) {
  try {
    const { ad_id } = req.params;

    console.log("=========================================")

    if (!ad_id || isNaN(parseInt(ad_id))) {
      return res.status(400).json({ message: 'شناسه آگهی نامعتبر است' });
    }

    const parsedAdId = parseInt(ad_id);

    const commentsResult = await db.raw(
      `
      SELECT 
        c.comment_id, c.ad_id, c.user_phone_number, c.content, c.created_at,
        u.nickname
      FROM comments c
      LEFT JOIN users u ON c.user_phone_number = u.phone_number
      WHERE c.ad_id = ?
      ORDER BY c.created_at DESC
      `,
      [parsedAdId]
    );

    const comments = commentsResult[0].map(comment => ({
      comment_id: comment.comment_id,
      ad_id: comment.ad_id,
      user_phone_number: comment.user_phone_number,
      nickname: comment.nickname,
      content: comment.content,
      created_at: comment.created_at,
    }));

    console.log("=======================> " , comments);

    res.status(200).json(comments);
  } catch (error) {
    console.error('Error fetching comments:', error);
    res.status(500).json({ message: `خطا در دریافت کامنت‌ها: ${error.message}` });
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
      item_condition,
      service_type,
      service_duration,
    } = req.body;

    // Validate common fields
    const missingFields = [];
    if (!title || title.trim() === '') missingFields.push('title');
    if (!description || description.trim() === '') missingFields.push('description');
    if (!ad_type || !['REAL_ESTATE', 'VEHICLE', 'DIGITAL', 'HOME', 'SERVICES', 'PERSONAL', 'ENTERTAINMENT'].includes(ad_type)) {
      missingFields.push('ad_type');
    }
    if (!price || isNaN(parseInt(price))) missingFields.push('price');
    if (!province_id || isNaN(parseInt(province_id))) missingFields.push('province_id');
    if (!city_id || isNaN(parseInt(city_id))) missingFields.push('city_id');
    if (!owner_phone_number || owner_phone_number.trim() === '') missingFields.push('owner_phone_number');

    // Validate category-specific fields
    if (ad_type === 'REAL_ESTATE') {
      if (!real_estate_type || !['SALE', 'RENT'].includes(real_estate_type)) missingFields.push('real_estate_type');
      if (!area || isNaN(parseInt(area))) missingFields.push('area');
      if (!construction_year || isNaN(parseInt(construction_year))) missingFields.push('construction_year');
      if (!rooms || isNaN(parseInt(rooms))) missingFields.push('rooms');
      if (!floor || isNaN(parseInt(floor))) missingFields.push('floor');
      if (real_estate_type === 'SALE') {
        if (!total_price || isNaN(parseInt(total_price))) missingFields.push('total_price');
        if (!price_per_meter || isNaN(parseInt(price_per_meter))) missingFields.push('price_per_meter');
      } else if (real_estate_type === 'RENT') {
        if (!deposit || isNaN(parseInt(deposit))) missingFields.push('deposit');
        if (!monthly_rent || isNaN(parseInt(monthly_rent))) missingFields.push('monthly_rent');
      }
    } else if (ad_type === 'VEHICLE') {
      if (!brand || brand.trim() === '') missingFields.push('brand');
      if (!model || model.trim() === '') missingFields.push('model');
      if (!mileage || isNaN(parseInt(mileage))) missingFields.push('mileage');
      if (!color || color.trim() === '') missingFields.push('color');
      if (!gearbox || !['MANUAL', 'AUTOMATIC'].includes(gearbox)) missingFields.push('gearbox');
      if (!base_price || isNaN(parseInt(base_price))) missingFields.push('base_price');
      if (!engine_status || !['HEALTHY', 'NEEDS_REPAIR'].includes(engine_status)) missingFields.push('engine_status');
      if (!chassis_status || !['HEALTHY', 'IMPACTED'].includes(chassis_status)) missingFields.push('chassis_status');
      if (!body_status || !['HEALTHY', 'MINOR_SCRATCH', 'ACCIDENTED'].includes(body_status)) missingFields.push('body_status');
    } else if (['DIGITAL', 'HOME', 'PERSONAL', 'ENTERTAINMENT'].includes(ad_type)) {
      if (!brand || brand.trim() === '') missingFields.push('brand');
      if (!model || model.trim() === '') missingFields.push('model');
      if (!item_condition || !['NEW', 'USED'].includes(item_condition)) missingFields.push('item_condition');
    } else if (ad_type === 'SERVICES') {
      if (!service_type || service_type.trim() === '') missingFields.push('service_type');
      if (service_duration && isNaN(parseInt(service_duration))) missingFields.push('service_duration');
    }

    if (missingFields.length > 0) {
      console.log('Validation failed for fields:', missingFields);
      return res.status(400).json({
        message: `فیلدهای الزامی پر نشده‌اند: ${missingFields.join(', ')}`,
        missingFields,
      });
    }

    const parsedPrice = parseInt(price);
    const parsedProvinceId = parseInt(province_id);
    const parsedCityId = parseInt(city_id);
    const parsedBasePrice = ad_type === 'VEHICLE' ? parseInt(base_price) : null;
    const parsedTotalPrice = ad_type === 'REAL_ESTATE' && real_estate_type === 'SALE' ? parseInt(total_price) : null;
    const parsedDeposit = ad_type === 'REAL_ESTATE' && real_estate_type === 'RENT' ? parseInt(deposit) : null;
    const parsedMonthlyRent = ad_type === 'REAL_ESTATE' && real_estate_type === 'RENT' ? parseInt(monthly_rent) : null;
    const parsedServiceDuration = ad_type === 'SERVICES' && service_duration ? parseInt(service_duration) : null;

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
    if (ad_type === 'REAL_ESTATE' && real_estate_type === 'SALE' && (isNaN(parsedTotalPrice) || parsedTotalPrice < 0)) {
      return res.status(400).json({ message: 'قیمت کل باید یک عدد معتبر باشد' });
    }
    if (ad_type === 'REAL_ESTATE' && real_estate_type === 'RENT') {
      if (isNaN(parsedDeposit) || parsedDeposit < 0) {
        return res.status(400).json({ message: 'ودیعه باید یک عدد معتبر باشد' });
      }
      if (isNaN(parsedMonthlyRent) || parsedMonthlyRent < 0) {
        return res.status(400).json({ message: 'اجاره ماهانه باید یک عدد معتبر باشد' });
      }
    }
    if (ad_type === 'SERVICES' && service_duration && (isNaN(parsedServiceDuration) || parsedServiceDuration <= 0)) {
      return res.status(400).json({ message: 'مدت زمان خدمت باید یک عدد معتبر باشد' });
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
      await db.raw(
        `INSERT INTO real_estate_ads (
          ad_id, real_estate_type, area, construction_year, rooms, total_price, price_per_meter,
          has_parking, has_storage, has_balcony, deposit, monthly_rent, floor
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          ad_id,
          real_estate_type,
          parseInt(area),
          parseInt(construction_year),
          parseInt(rooms),
          real_estate_type === 'SALE' ? parsedTotalPrice : 0,
          real_estate_type === 'SALE' ? parseInt(price_per_meter) : null,
          has_parking === 'true' ? 1 : 0,
          has_storage === 'true' ? 1 : 0,
          has_balcony === 'true' ? 1 : 0,
          real_estate_type === 'RENT' ? parsedDeposit : null,
          real_estate_type === 'RENT' ? parsedMonthlyRent : null,
          parseInt(floor),
        ]
      );
    } else if (ad_type === 'VEHICLE') {
      await db.raw(
        `INSERT INTO vehicle_ads (
          ad_id, mileage, color, brand, model, gearbox, base_price, engine_status, chassis_status, body_status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          ad_id,
          parseInt(mileage),
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
    } else if (ad_type === 'DIGITAL') {
      await db.raw(
        `INSERT INTO digital_ads (ad_id, brand, model, item_condition) VALUES (?, ?, ?, ?)`,
        [ad_id, brand, model, item_condition]
      );
    } else if (ad_type === 'HOME') {
      await db.raw(
        `INSERT INTO home_ads (ad_id, brand, model, item_condition) VALUES (?, ?, ?, ?)`,
        [ad_id, brand, model, item_condition]
      );
    } else if (ad_type === 'PERSONAL') {
      await db.raw(
        `INSERT INTO personal_ads (ad_id, brand, model, item_condition) VALUES (?, ?, ?, ?)`,
        [ad_id, brand, model, item_condition]
      );
    } else if (ad_type === 'ENTERTAINMENT') {
      await db.raw(
        `INSERT INTO entertainment_ads (ad_id, brand, model, item_condition) VALUES (?, ?, ?, ?)`,
        [ad_id, brand, model, item_condition]
      );
    } else if (ad_type === 'SERVICES') {
      await db.raw(
        `INSERT INTO services_ads (ad_id, service_type, service_duration) VALUES (?, ?, ?)`,
        [ad_id, service_type, parsedServiceDuration]
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


async function searchAds(req, res) {
  try {
    const { query, isSuggestion } = req.query;
    console.log('Search request received:', { query, isSuggestion });

    if (!query || query.trim() === '') {
      console.log('Invalid search query: empty or not provided');
      return res.status(400).json({ message: 'عبارت جستجو الزامی است' });
    }

    const searchTerm = `%${query.trim()}%`;
    const limit = isSuggestion === 'true' ? 5 : 10; // Limit suggestions to 5, full search to 10

    await db.raw('SET NAMES utf8mb4');
    const adsResult = await db.raw(
      `
      SELECT 
        a.ad_id, a.title, a.description, a.ad_type, a.price, 
        a.province_id, a.city_id, a.owner_phone_number, a.created_at, a.status,
        p.name AS province_name, c.name AS city_name,
        GROUP_CONCAT(ai.image_url) AS image_urls
      FROM advertisements a
      LEFT JOIN provinces p ON a.province_id = p.province_id
      LEFT JOIN cities c ON a.city_id = c.city_id
      LEFT JOIN ad_images ai ON a.ad_id = ai.ad_id
      WHERE a.title LIKE ? OR a.description LIKE ? OR a.ad_type LIKE ?
      GROUP BY a.ad_id
      ORDER BY a.created_at DESC
      LIMIT ?
      `,
      [searchTerm, searchTerm, searchTerm, limit]
    );

    const ads = adsResult[0];
    console.log('Ads found:', ads.length);

    const result = await Promise.all(
      ads.map(async (ad) => {
        let specificDetails = {};
        if (ad.ad_type === 'REAL_ESTATE') {
          const realEstateResult = await db.raw(
            `
            SELECT real_estate_type, area, construction_year, rooms, total_price,
                   price_per_meter, has_parking, has_storage, has_balcony, deposit,
                   monthly_rent, floor
            FROM real_estate_ads
            WHERE ad_id = ?
            `,
            [ad.ad_id]
          );
          specificDetails = realEstateResult[0][0] || {};
          if (specificDetails.real_estate_type === 'SALE') {
            specificDetails.deposit = null;
            specificDetails.monthly_rent = null;
          }
        } else if (ad.ad_type === 'VEHICLE') {
          const vehicleResult = await db.raw(
            `
            SELECT brand, model, mileage, color, gearbox, base_price,
                   engine_status, chassis_status, body_status
            FROM vehicle_ads
            WHERE ad_id = ?
            `,
            [ad.ad_id]
          );
          specificDetails = vehicleResult[0][0] || {};
        } else if (['DIGITAL', 'HOME', 'PERSONAL', 'ENTERTAINMENT'].includes(ad.ad_type)) {
          const tableName = {
            DIGITAL: 'digital_ads',
            HOME: 'home_ads',
            PERSONAL: 'personal_ads',
            ENTERTAINMENT: 'entertainment_ads',
          }[ad.ad_type];
          const categoryResult = await db.raw(
            `SELECT brand, model, item_condition FROM ${tableName} WHERE ad_id = ?`,
            [ad.ad_id]
          );
          specificDetails = categoryResult[0][0] || {};
        } else if (ad.ad_type === 'SERVICES') {
          const servicesResult = await db.raw(
            `SELECT service_type, service_duration FROM services_ads WHERE ad_id = ?`,
            [ad.ad_id]
          );
          specificDetails = servicesResult[0][0] || {};
        }

        return {
          adId: ad.ad_id, // Corrected from adId
          title: ad.title,
          description: ad.description,
          adType: ad.ad_type,
          price: ad.price,
          provinceId: ad.province_id,
          cityId: ad.city_id,
          ownerPhoneNumber: ad.owner_phone_number,
          createdAt: ad.created_at,
          status: ad.status,
          provinceName: ad.province_name,
          cityName: ad.city_name,
          imageUrls: ad.image_urls ? ad.image_urls.split(',').filter(url => url) : [],
          ...specificDetails,
        };
      })
    );

    console.log('Final response:', result);
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.status(200).json(result);
  } catch (error) {
    console.error('Error searching ads:', {
      error: error.message,
      stack: error.stack,
      query,
      isSuggestion,
    });
    res.status(500).json({ message: `خطا در جستجوی آگهی‌ها: ${error.message}` });
  }
}

async function testSearch(req, res) {
  try {
    await db.raw('SET NAMES utf8mb4');
    const adsResult = await db.raw(
      `
      SELECT 
        a.ad_id, a.title, a.description
      FROM advertisements a
      WHERE a.title LIKE ?
      `,
      ['%آگهی جدید%']
    );
    console.log('Test search results:', adsResult[0]);
    res.status(200).json(adsResult[0]);
  } catch (error) {
    console.error('Test search error:', error);
    res.status(500).json({ message: error.message });
  }
}
async function updateAd(req, res) {
  let parsedAdId;
  try {
    const { ad_id } = req.params;
    console.log('Received updateAd request:', {
      ad_id,
      body: req.body,
      files: req.files,
    });

    // Validate ad_id
    parsedAdId = parseInt(ad_id);
    if (isNaN(parsedAdId)) {
      console.log('Invalid ad_id:', ad_id);
      return res.status(400).json({ message: 'شناسه آگهی نامعتبر است' });
    }

    // Check if req.body is empty and no files are provided
    if (Object.keys(req.body).length === 0 && (!req.files || req.files.length === 0)) {
      console.log('No data provided for update:', { ad_id });
      return res.status(400).json({ message: 'هیچ داده‌ای برای به‌روزرسانی ارائه نشده است' });
    }

    // Fetch existing ad
    const adQuery = `
      SELECT 
        a.title, a.description, a.ad_type, a.price, a.province_id, a.city_id, 
        a.owner_phone_number
      FROM advertisements a
      WHERE a.ad_id = ?
    `;
    const adResult = await db.raw(adQuery, [parsedAdId]);
    if (adResult[0].length === 0) {
      console.log(`Ad not found: ad_id=${parsedAdId}`);
      return res.status(404).json({ message: 'آگهی یافت نشد' });
    }
    const existingAd = adResult[0][0];

    // Fetch existing specific details based on ad_type
    let existingSpecificDetails = {};
    if (existingAd.ad_type === 'REAL_ESTATE') {
      const realEstateQuery = `
        SELECT real_estate_type, area, construction_year, rooms, total_price, 
               price_per_meter, has_parking, has_storage, has_balcony, deposit, 
               monthly_rent, floor
        FROM real_estate_ads WHERE ad_id = ?
      `;
      const realEstateResult = await db.raw(realEstateQuery, [parsedAdId]);
      existingSpecificDetails = realEstateResult[0][0] || {};
    } else if (existingAd.ad_type === 'VEHICLE') {
      const vehicleQuery = `
        SELECT brand, model, mileage, color, gearbox, base_price, 
               engine_status, chassis_status, body_status
        FROM vehicle_ads WHERE ad_id = ?
      `;
      const vehicleResult = await db.raw(vehicleQuery, [parsedAdId]);
      existingSpecificDetails = vehicleResult[0][0] || {};
    } else if (existingAd.ad_type === 'DIGITAL') {
      const digitalQuery = `
        SELECT brand, model, item_condition
        FROM digital_ads WHERE ad_id = ?
      `;
      const digitalResult = await db.raw(digitalQuery, [parsedAdId]);
      existingSpecificDetails = digitalResult[0][0] || {};
    } else if (existingAd.ad_type === 'HOME') {
      const homeQuery = `
        SELECT brand, model, item_condition
        FROM home_ads WHERE ad_id = ?
      `;
      const homeResult = await db.raw(homeQuery, [parsedAdId]);
      existingSpecificDetails = homeResult[0][0] || {};
    } else if (existingAd.ad_type === 'PERSONAL') {
      const personalQuery = `
        SELECT brand, model, item_condition
        FROM personal_ads WHERE ad_id = ?
      `;
      const personalResult = await db.raw(personalQuery, [parsedAdId]);
      existingSpecificDetails = personalResult[0][0] || {};
    } else if (existingAd.ad_type === 'ENTERTAINMENT') {
      const entertainmentQuery = `
        SELECT brand, model, item_condition
        FROM entertainment_ads WHERE ad_id = ?
      `;
      const entertainmentResult = await db.raw(entertainmentQuery, [parsedAdId]);
      existingSpecificDetails = entertainmentResult[0][0] || {};
    } else if (existingAd.ad_type === 'SERVICES') {
      const servicesQuery = `
        SELECT service_type, service_duration
        FROM services_ads WHERE ad_id = ?
      `;
      const servicesResult = await db.raw(servicesQuery, [parsedAdId]);
      existingSpecificDetails = servicesResult[0][0] || {};
    }

    const {
      title = existingAd.title,
      description = existingAd.description,
      ad_type = existingAd.ad_type,
      price = existingAd.price,
      province_id = existingAd.province_id,
      city_id = existingAd.city_id,
      owner_phone_number = existingAd.owner_phone_number,
      real_estate_type = existingSpecificDetails.real_estate_type,
      area = existingSpecificDetails.area,
      construction_year = existingSpecificDetails.construction_year,
      rooms = existingSpecificDetails.rooms,
      total_price = existingSpecificDetails.total_price,
      price_per_meter = existingSpecificDetails.price_per_meter,
      has_parking = existingSpecificDetails.has_parking,
      has_storage = existingSpecificDetails.has_storage,
      has_balcony = existingSpecificDetails.has_balcony,
      deposit = existingSpecificDetails.deposit,
      monthly_rent = existingSpecificDetails.monthly_rent,
      floor = existingSpecificDetails.floor,
      brand = existingSpecificDetails.brand,
      model = existingSpecificDetails.model,
      mileage = existingSpecificDetails.mileage,
      color = existingSpecificDetails.color,
      gearbox = existingSpecificDetails.gearbox,
      base_price = existingSpecificDetails.base_price,
      engine_status = existingSpecificDetails.engine_status,
      chassis_status = existingSpecificDetails.chassis_status,
      body_status = existingSpecificDetails.body_status,
      item_condition = existingSpecificDetails.item_condition,
      service_type = existingSpecificDetails.service_type,
      service_duration = existingSpecificDetails.service_duration,
      existing_images = '[]', // Default to empty array if not provided
    } = req.body;

    // Validate fields
    const missingFields = [];
    if (!title || title.trim() === '') missingFields.push('title');
    if (!description || description.trim() === '') missingFields.push('description');
    if (!ad_type || !['REAL_ESTATE', 'VEHICLE', 'DIGITAL', 'HOME', 'SERVICES', 'PERSONAL', 'ENTERTAINMENT'].includes(ad_type)) {
      missingFields.push('ad_type');
    }
    if (!price || isNaN(parseInt(price))) missingFields.push('price');
    if (!province_id || isNaN(parseInt(province_id))) missingFields.push('province_id');
    if (!city_id || isNaN(parseInt(city_id))) missingFields.push('city_id');
    if (!owner_phone_number || owner_phone_number.trim() === '') missingFields.push('owner_phone_number');

    if (ad_type === 'REAL_ESTATE') {
      if (!real_estate_type || !['SALE', 'RENT'].includes(real_estate_type)) missingFields.push('real_estate_type');
      if (!area || isNaN(parseInt(area))) missingFields.push('area');
      if (!construction_year || isNaN(parseInt(construction_year))) missingFields.push('construction_year');
      if (!rooms || isNaN(parseInt(rooms))) missingFields.push('rooms');
      if (!floor || isNaN(parseInt(floor))) missingFields.push('floor');
      if (real_estate_type === 'SALE') {
        if (!total_price || isNaN(parseInt(total_price))) missingFields.push('total_price');
        if (!price_per_meter || isNaN(parseInt(price_per_meter))) missingFields.push('price_per_meter');
      } else if (real_estate_type === 'RENT') {
        if (!deposit || isNaN(parseInt(deposit))) missingFields.push('deposit');
        if (!monthly_rent || isNaN(parseInt(monthly_rent))) missingFields.push('monthly_rent');
      }
    } else if (ad_type === 'VEHICLE') {
      if (!brand || brand.trim() === '') missingFields.push('brand');
      if (!model || model.trim() === '') missingFields.push('model');
      if (!mileage || isNaN(parseInt(mileage))) missingFields.push('mileage');
      if (!color || color.trim() === '') missingFields.push('color');
      if (!gearbox || !['MANUAL', 'AUTOMATIC'].includes(gearbox)) missingFields.push('gearbox');
      if (!base_price || isNaN(parseInt(base_price))) missingFields.push('base_price');
      if (!engine_status || !['HEALTHY', 'NEEDS_REPAIR'].includes(engine_status)) missingFields.push('engine_status');
      if (!chassis_status || !['HEALTHY', 'IMPACTED'].includes(chassis_status)) missingFields.push('chassis_status');
      if (!body_status || !['HEALTHY', 'MINOR_SCRATCH', 'ACCIDENTED'].includes(body_status)) missingFields.push('body_status');
    } else if (['DIGITAL', 'HOME', 'PERSONAL', 'ENTERTAINMENT'].includes(ad_type)) {
      if (!brand || brand.trim() === '') missingFields.push('brand');
      if (!model || model.trim() === '') missingFields.push('model');
      if (!item_condition || !['NEW', 'USED'].includes(item_condition)) missingFields.push('item_condition');
    } else if (ad_type === 'SERVICES') {
      if (!service_type || service_type.trim() === '') missingFields.push('service_type');
      if (service_duration && isNaN(parseInt(service_duration))) missingFields.push('service_duration');
    }

    if (missingFields.length > 0) {
      console.log('Validation failed:', { missingFields });
      return res.status(400).json({
        message: `فیلدهای الزامی پر نشده‌اند: ${missingFields.join(', ')}`,
        missingFields,
      });
    }

    // Parse numeric fields with safety checks
    const parsedPrice = parseInt(price);
    const parsedProvinceId = parseInt(province_id);
    const parsedCityId = parseInt(city_id);
    const parsedBasePrice = ad_type === 'VEHICLE' ? parseInt(base_price) : null;
    const parsedTotalPrice = ad_type === 'REAL_ESTATE' && real_estate_type === 'SALE' ? parseInt(total_price) : null;
    const parsedPricePerMeter = ad_type === 'REAL_ESTATE' && real_estate_type === 'SALE' ? parseInt(price_per_meter) : null;
    const parsedDeposit = ad_type === 'REAL_ESTATE' && real_estate_type === 'RENT' ? parseInt(deposit) : null;
    const parsedMonthlyRent = ad_type === 'REAL_ESTATE' && real_estate_type === 'RENT' ? parseInt(monthly_rent) : null;
    const parsedServiceDuration = ad_type === 'SERVICES' && service_duration ? parseInt(service_duration) : null;
    const parsedArea = ad_type === 'REAL_ESTATE' ? parseInt(area) : null;
    const parsedConstructionYear = ad_type === 'REAL_ESTATE' ? parseInt(construction_year) : null;
    const parsedRooms = ad_type === 'REAL_ESTATE' ? parseInt(rooms) : null;
    const parsedFloor = ad_type === 'REAL_ESTATE' ? parseInt(floor) : null;
    const parsedMileage = ad_type === 'VEHICLE' ? parseInt(mileage) : null;

    // Validate parsed numeric fields
    if (isNaN(parsedPrice) || parsedPrice < 0) {
      console.log('Invalid price:', price);
      return res.status(400).json({ message: 'قیمت باید یک عدد معتبر باشد' });
    }
    if (isNaN(parsedProvinceId)) {
      console.log('Invalid province_id:', province_id);
      return res.status(400).json({ message: 'شناسه استان باید یک عدد معتبر باشد' });
    }
    if (isNaN(parsedCityId)) {
      console.log('Invalid city_id:', city_id);
      return res.status(400).json({ message: 'شناسه شهر باید یک عدد معتبر باشد' });
    }
    if (ad_type === 'VEHICLE' && (isNaN(parsedBasePrice) || parsedBasePrice < 0)) {
      console.log('Invalid base_price:', base_price);
      return res.status(400).json({ message: 'قیمت پایه باید یک عدد معتبر باشد' });
    }
    if (ad_type === 'REAL_ESTATE' && real_estate_type === 'SALE') {
      if (isNaN(parsedTotalPrice) || parsedTotalPrice < 0) {
        console.log('Invalid total_price:', total_price);
        return res.status(400).json({ message: 'قیمت کل باید یک عدد معتبر باشد' });
      }
      if (isNaN(parsedPricePerMeter) || parsedPricePerMeter < 0) {
        console.log('Invalid price_per_meter:', price_per_meter);
        return res.status(400).json({ message: 'قیمت هر متر باید یک عدد معتبر باشد' });
      }
    }
    if (ad_type === 'REAL_ESTATE' && real_estate_type === 'RENT') {
      if (isNaN(parsedDeposit) || parsedDeposit < 0) {
        console.log('Invalid deposit:', deposit);
        return res.status(400).json({ message: 'ودیعه باید یک عدد معتبر باشد' });
      }
      if (isNaN(parsedMonthlyRent) || parsedMonthlyRent < 0) {
        console.log('Invalid monthly_rent:', monthly_rent);
        return res.status(400).json({ message: 'اجاره ماهانه باید یک عدد معتبر باشد' });
      }
    }
    if (ad_type === 'SERVICES' && service_duration && (isNaN(parsedServiceDuration) || parsedServiceDuration <= 0)) {
      console.log('Invalid service_duration:', service_duration);
      return res.status(400).json({ message: 'مدت زمان خدمت باید یک عدد معتبر باشد' });
    }
    if (ad_type === 'REAL_ESTATE') {
      if (isNaN(parsedArea) || parsedArea <= 0) {
        console.log('Invalid area:', area);
        return res.status(400).json({ message: 'مساحت باید یک عدد معتبر باشد' });
      }
      if (isNaN(parsedConstructionYear) || parsedConstructionYear < 0) {
        console.log('Invalid construction_year:', construction_year);
        return res.status(400).json({ message: 'سال ساخت باید یک عدد معتبر باشد' });
      }
      if (isNaN(parsedRooms) || parsedRooms < 0) {
        console.log('Invalid rooms:', rooms);
        return res.status(400).json({ message: 'تعداد اتاق‌ها باید یک عدد معتبر باشد' });
      }
      if (isNaN(parsedFloor) || parsedFloor < 0) {
        console.log('Invalid floor:', floor);
        return res.status(400).json({ message: 'طبقه باید یک عدد معتبر باشد' });
      }
    }
    if (ad_type === 'VEHICLE' && (isNaN(parsedMileage) || parsedMileage < 0)) {
      console.log('Invalid mileage:', mileage);
      return res.status(400).json({ message: 'کیلومتر باید یک عدد معتبر باشد' });
    }

    // Validate foreign keys
    const provinceCheck = await db.raw('SELECT 1 FROM provinces WHERE province_id = ?', [parsedProvinceId]);
    if (provinceCheck[0].length === 0) {
      console.log('Province not found:', parsedProvinceId);
      return res.status(400).json({ message: 'استان با شناسه مشخص‌شده یافت نشد' });
    }
    const cityCheck = await db.raw('SELECT 1 FROM cities WHERE city_id = ?', [parsedCityId]);
    if (cityCheck[0].length === 0) {
      console.log('City not found:', parsedCityId);
      return res.status(400).json({ message: 'شهر با شناسه مشخص‌شده یافت نشد' });
    }

    // Handle boolean fields
    const boolToInt = (value) => (value === true || value === 'true' ? 1 : 0);
    const parsedHasParking = ad_type === 'REAL_ESTATE' ? boolToInt(has_parking) : null;
    const parsedHasStorage = ad_type === 'REAL_ESTATE' ? boolToInt(has_storage) : null;
    const parsedHasBalcony = ad_type === 'REAL_ESTATE' ? boolToInt(has_balcony) : null;

    // Handle images
    if (existing_images || (req.files && req.files.length > 0)) {
      console.log('Processing images for ad_id:', parsedAdId);
      console.log('Existing images input:', existing_images);
      console.log('New images count:', req.files ? req.files.length : 0);

      // Validate total images
      let existingImageUrls = [];
      if (existing_images) {
        try {
          existingImageUrls = JSON.parse(existing_images);
          if (!Array.isArray(existingImageUrls)) {
            throw new Error('existing_images must be an array');
          }
          for (const imageUrl of existingImageUrls) {
            if (!imageUrl || (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://'))) {
              throw new Error(`Invalid image URL: ${imageUrl}`);
            }
          }
        } catch (e) {
          console.error('Error parsing existing_images:', { error: e.message, input: existing_images });
          return res.status(400).json({ message: `فرمت existing_images نامعتبر است: ${e.message}` });
        }
      }

      const newImages = req.files || [];
      const totalImages = existingImageUrls.length + newImages.length;
      console.log('Total images:', { existing: existingImageUrls.length, new: newImages.length });

      if (totalImages > 5) {
        console.log('Too many images:', { existingImages: existingImageUrls.length, newImages: newImages.length });
        return res.status(400).json({ message: 'حداکثر ۵ تصویر مجاز است' });
      }
      if (totalImages === 0) {
        console.log('No images provided:', { ad_id: parsedAdId });
        return res.status(400).json({ message: 'حداقل یک تصویر الزامی است' });
      }

      // Delete existing images
      console.log('Deleting existing images for ad_id:', parsedAdId);
      const deleteImagesResult = await db.raw(`DELETE FROM ad_images WHERE ad_id = ?`, [parsedAdId]);
      console.log('Images deleted:', { affectedRows: deleteImagesResult[0].affectedRows });

      const baseUrl = process.env.BASE_URL || 'http://localhost:5000';

      // Insert existing images
      for (const imageUrl of existingImageUrls) {
        console.log('Inserting existing image:', imageUrl);
        await db.raw(`INSERT INTO ad_images (ad_id, image_url) VALUES (?, ?)`, [parsedAdId, imageUrl]);
      }

      // Insert new images
      for (const file of newImages) {
        const imageUrl = `${baseUrl}/uploads/${file.filename}`;
        console.log('Inserting new image:', imageUrl);
        await db.raw(`INSERT INTO ad_images (ad_id, image_url) VALUES (?, ?)`, [parsedAdId, imageUrl]);
      }
    }

    await db.raw('START TRANSACTION');
    console.log('Started transaction for ad_id:', parsedAdId);

    // Update advertisements table
    const updateAdResult = await db.raw(
      `UPDATE advertisements 
       SET title = ?, description = ?, ad_type = ?, price = ?, province_id = ?, city_id = ?, owner_phone_number = ?
       WHERE ad_id = ?`,
      [title, description, ad_type, parsedPrice, parsedProvinceId, parsedCityId, owner_phone_number, parsedAdId]
    );
    console.log('Advertisements update:', { affectedRows: updateAdResult[0].affectedRows });

    if (updateAdResult[0].affectedRows === 0) {
      await db.raw('ROLLBACK');
      console.log(`No rows updated in advertisements: ad_id=${parsedAdId}`);
      return res.status(404).json({ message: 'آگهی یافت نشد یا هیچ تغییری اعمال نشد' });
    }

    // Update category-specific tables
    if (ad_type === 'REAL_ESTATE') {
      const realEstateCheck = await db.raw('SELECT 1 FROM real_estate_ads WHERE ad_id = ?', [parsedAdId]);
      if (realEstateCheck[0].length === 0) {
        await db.raw('ROLLBACK');
        console.log(`Real estate ad not found: ad_id=${parsedAdId}`);
        return res.status(404).json({ message: 'آگهی املاک یافت نشد' });
      }

      const realEstateUpdateResult = await db.raw(
        `UPDATE real_estate_ads 
         SET real_estate_type = ?, area = ?, construction_year = ?, rooms = ?, 
             total_price = ?, price_per_meter = ?, has_parking = ?, has_storage = ?, 
             has_balcony = ?, deposit = ?, monthly_rent = ?, floor = ?
         WHERE ad_id = ?`,
        [
          real_estate_type,
          parsedArea,
          parsedConstructionYear,
          parsedRooms,
          real_estate_type === 'SALE' ? parsedTotalPrice : 0,
          real_estate_type === 'SALE' ? parsedPricePerMeter : null,
          parsedHasParking,
          parsedHasStorage,
          parsedHasBalcony,
          real_estate_type === 'RENT' ? parsedDeposit : null,
          real_estate_type === 'RENT' ? parsedMonthlyRent : null,
          parsedFloor,
          parsedAdId,
        ]
      );
      console.log('Real estate update:', { affectedRows: realEstateUpdateResult[0].affectedRows });
    } else if (ad_type === 'VEHICLE') {
      const vehicleCheck = await db.raw('SELECT 1 FROM vehicle_ads WHERE ad_id = ?', [parsedAdId]);
      if (vehicleCheck[0].length === 0) {
        await db.raw('ROLLBACK');
        console.log(`Vehicle ad not found: ad_id=${parsedAdId}`);
        return res.status(404).json({ message: 'آگهی خودرو یافت نشد' });
      }

      const vehicleUpdateResult = await db.raw(
        `UPDATE vehicle_ads 
         SET brand = ?, model = ?, mileage = ?, color = ?, gearbox = ?, base_price = ?, 
             engine_status = ?, chassis_status = ?, body_status = ?
         WHERE ad_id = ?`,
        [
          brand,
          model,
          parsedMileage,
          color,
          gearbox,
          parsedBasePrice,
          engine_status,
          chassis_status,
          body_status,
          parsedAdId,
        ]
      );
      console.log('Vehicle update:', { affectedRows: vehicleUpdateResult[0].affectedRows });
    } else if (['DIGITAL', 'HOME', 'PERSONAL', 'ENTERTAINMENT'].includes(ad_type)) {
      const tableName = {
        DIGITAL: 'digital_ads',
        HOME: 'home_ads',
        PERSONAL: 'personal_ads',
        ENTERTAINMENT: 'entertainment_ads',
      }[ad_type];
      const categoryCheck = await db.raw(`SELECT 1 FROM ${tableName} WHERE ad_id = ?`, [parsedAdId]);
      if (categoryCheck[0].length === 0) {
        await db.raw('ROLLBACK');
        console.log(`${ad_type} ad not found: ad_id=${parsedAdId}`);
        return res.status(404).json({ message: `آگهی ${ad_type} یافت نشد` });
      }

      const categoryUpdateResult = await db.raw(
        `UPDATE ${tableName} 
         SET brand = ?, model = ?, item_condition = ?
         WHERE ad_id = ?`,
        [brand, model, item_condition, parsedAdId]
      );
      console.log(`${ad_type} update:`, { affectedRows: categoryUpdateResult[0].affectedRows });
    } else if (ad_type === 'SERVICES') {
      const servicesCheck = await db.raw('SELECT 1 FROM services_ads WHERE ad_id = ?', [parsedAdId]);
      if (servicesCheck[0].length === 0) {
        await db.raw('ROLLBACK');
        console.log(`Services ad not found: ad_id=${parsedAdId}`);
        return res.status(404).json({ message: 'آگهی خدمات یافت نشد' });
      }

      const servicesUpdateResult = await db.raw(
        `UPDATE services_ads 
         SET service_type = ?, service_duration = ?
         WHERE ad_id = ?`,
        [service_type, parsedServiceDuration, parsedAdId]
      );
      console.log('Services update:', { affectedRows: servicesUpdateResult[0].affectedRows });
    }

    console.log('Committing transaction for ad_id:', parsedAdId);
    await db.raw('COMMIT');
    console.log('Transaction committed successfully for ad_id:', parsedAdId);
    res.status(200).json({ message: 'آگهی با موفقیت ویرایش شد' });
  } catch (error) {
    await db.raw('ROLLBACK');
    console.error('Error updating ad:', {
      message: error.message,
      stack: error.stack,
      ad_id: parsedAdId || req.params.ad_id,
      body: req.body,
      files: req.files ? req.files : null,
    });
    res.status(500).json({ message: `خطا در ویرایش آگهی: ${error.message}` });
  }
}
// Delete an ad
async function deleteAd(req, res) {
  try {
    const { ad_id } = req.params;
    console.log(`Deleting ad with ad_id: ${ad_id}`);

    const parsedAdId = parseInt(ad_id);
    if (isNaN(parsedAdId)) {
      console.error('Invalid ad_id:', ad_id);
      return res.status(400).json({ message: 'شناسه آگهی نامعتبر است' });
    }

    await db.raw('START TRANSACTION');

    // Delete related records
    await db.raw(`DELETE FROM ad_images WHERE ad_id = ?`, [parsedAdId]);
    await db.raw(`DELETE FROM real_estate_ads WHERE ad_id = ?`, [parsedAdId]);
    await db.raw(`DELETE FROM vehicle_ads WHERE ad_id = ?`, [parsedAdId]);
    await db.raw(`DELETE FROM digital_ads WHERE ad_id = ?`, [parsedAdId]);
    await db.raw(`DELETE FROM home_ads WHERE ad_id = ?`, [parsedAdId]);
    await db.raw(`DELETE FROM personal_ads WHERE ad_id = ?`, [parsedAdId]);
    await db.raw(`DELETE FROM entertainment_ads WHERE ad_id = ?`, [parsedAdId]);
    await db.raw(`DELETE FROM services_ads WHERE ad_id = ?`, [parsedAdId]);

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
  searchAds,
  createComment,
  getComments,

};