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
    const { query } = req.query;
    console.log('Received query:', query);
    console.log('Query hex:', Buffer.from(query, 'utf8').toString('hex'));
    if (!query || query.trim() === '') {
      console.log('Empty or invalid query received');
      return res.status(400).json({ message: 'عبارت جستجو الزامی است' });
    }

    const searchQuery = `%${query.trim()}%`;
    console.log('Processed search query:', searchQuery);
    console.log('Search query hex:', Buffer.from(searchQuery, 'utf8').toString('hex'));

    await db.raw('SET NAMES utf8mb4');
    const adsResult = await db.raw(
      `
      SELECT 
        a.ad_id, a.title, a.description, a.ad_type, a.price, 
        a.province_id, a.city_id, a.owner_phone_number, a.created_at, a.status,
        p.name AS province_name, c.name AS city_name,
        HEX(a.title) AS title_hex,
        HEX(a.description) AS description_hex
      FROM advertisements a
      LEFT JOIN provinces p ON a.province_id = p.province_id
      LEFT JOIN cities c ON a.city_id = c.city_id
      WHERE a.title LIKE ? OR a.description LIKE ?
      ORDER BY a.created_at DESC
      `,
      [searchQuery, searchQuery]
    );
    const ads = adsResult[0];
    console.log('Ads found:', ads.length);
    console.log('Ads data:', ads);

    const result = await Promise.all(
      ads.map(async (ad) => {
        const imagesResult = await db.raw(
          'SELECT image_url FROM ad_images WHERE ad_id = ?',
          [ad.ad_id]
        );
        const imageUrls = imagesResult[0].map((img) => img.image_url).filter((url) => url != null);
        console.log(`Images for ad ${ad.ad_id}:`, imageUrls);

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
        }

        return {
          ad_id: ad.ad_id,
          title: ad.title,
          description: ad.description,
          ad_type: ad.ad_type,
          price: ad.price,
          province_id: ad.province_id,
          city_id: ad.city_id,
          owner_phone_number: ad.owner_phone_number,
          created_at: ad.created_at,
          status: ad.status,
          province_name: ad.province_name,
          city_name: ad.city_name,
          images: imageUrls,
          title_hex: ad.title_hex,
          description_hex: ad.description_hex,
          ...specificDetails,
        };
      })
    );

    console.log('Final response:', result);
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.status(200).json(result);
  } catch (error) {
    console.error('Error searching ads:', error);
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
    try {
      const { ad_id } = req.params;
      const {
        title,
        description,
        ad_type,
        price,
        base_price,
        total_price,
        deposit,
        monthly_rent,
        real_estate_type,
        owner_phone_number,
        brand,
        model,
        item_condition,
        service_type,
        service_duration,
      } = req.body;

      const missingFields = [];
      if (!title || title.trim() === '') missingFields.push('title');
      if (!description || description.trim() === '') missingFields.push('description');
      if (!ad_type || !['REAL_ESTATE', 'VEHICLE', 'DIGITAL', 'HOME', 'SERVICES', 'PERSONAL', 'ENTERTAINMENT'].includes(ad_type)) {
        missingFields.push('ad_type');
      }
      if (!owner_phone_number || owner_phone_number.trim() === '') missingFields.push('owner_phone_number');

      if (ad_type === 'REAL_ESTATE') {
        if (!real_estate_type || !['SALE', 'RENT'].includes(real_estate_type)) missingFields.push('real_estate_type');
        if (real_estate_type === 'SALE' && (!total_price || isNaN(parseInt(total_price)))) missingFields.push('total_price');
        if (real_estate_type === 'RENT') {
          if (!deposit || isNaN(parseInt(deposit))) missingFields.push('deposit');
          if (!monthly_rent || isNaN(parseInt(monthly_rent))) missingFields.push('monthly_rent');
        }
      } else if (ad_type === 'VEHICLE' && (!base_price || isNaN(parseInt(base_price)))) {
        missingFields.push('base_price');
      } else if (['DIGITAL', 'HOME', 'PERSONAL', 'ENTERTAINMENT'].includes(ad_type)) {
        if (!brand || brand.trim() === '') missingFields.push('brand');
        if (!model || model.trim() === '') missingFields.push('model');
        if (!item_condition || !['NEW', 'USED'].includes(item_condition)) missingFields.push('item_condition');
      } else if (ad_type === 'SERVICES') {
        if (!service_type || service_type.trim() === '') missingFields.push('service_type');
        if (service_duration && isNaN(parseInt(service_duration))) missingFields.push('service_duration');
      }

      if (!price || isNaN(parseInt(price))) missingFields.push('price');

      if (missingFields.length > 0) {
        return res.status(400).json({
          message: `فیلدهای الزامی پر نشده‌اند: ${missingFields.join(', ')}`,
          missingFields,
        });
      }

      const parsedAdId = parseInt(ad_id);
      const parsedPrice = parseInt(price);
      const parsedBasePrice = ad_type === 'VEHICLE' ? parseInt(base_price) : null;
      const parsedTotalPrice = ad_type === 'REAL_ESTATE' && real_estate_type === 'SALE' ? parseInt(total_price) : null;
      const parsedDeposit = ad_type === 'REAL_ESTATE' && real_estate_type === 'RENT' ? parseInt(deposit) : null;
      const parsedMonthlyRent = ad_type === 'REAL_ESTATE' && real_estate_type === 'RENT' ? parseInt(monthly_rent) : null;
      const parsedServiceDuration = ad_type === 'SERVICES' && service_duration ? parseInt(service_duration) : null;

      if (isNaN(parsedAdId)) {
        return res.status(400).json({ message: 'شناسه آگهی نامعتبر است' });
      }
      if (isNaN(parsedPrice) || parsedPrice < 0) {
        return res.status(400).json({ message: 'قیمت باید یک عدد معتبر و غیرمنفی باشد' });
      }
      if (ad_type === 'VEHICLE' && (isNaN(parsedBasePrice) || parsedBasePrice < 0)) {
        return res.status(400).json({ message: 'قیمت پایه باید یک عدد معتبر و غیرمنفی باشد' });
      }
      if (ad_type === 'REAL_ESTATE' && real_estate_type === 'SALE' && (isNaN(parsedTotalPrice) || parsedTotalPrice < 0)) {
        return res.status(400).json({ message: 'قیمت کل باید یک عدد معتبر و غیرمنفی باشد' });
      }
      if (ad_type === 'REAL_ESTATE' && real_estate_type === 'RENT') {
        if (isNaN(parsedDeposit) || parsedDeposit < 0) {
          return res.status(400).json({ message: 'ودیعه باید یک عدد معتبر و غیرمنفی باشد' });
        }
        if (isNaN(parsedMonthlyRent) || parsedMonthlyRent < 0) {
          return res.status(400).json({ message: 'اجاره ماهیانه باید یک عدد معتبر و غیرمنفی باشد' });
        }
      }
      if (ad_type === 'SERVICES' && service_duration && (isNaN(parsedServiceDuration) || parsedServiceDuration <= 0)) {
        return res.status(400).json({ message: 'مدت زمان خدمت باید یک عدد معتبر باشد' });
      }

      await db.raw('START TRANSACTION');

      // Update the advertisements table
      const updateAdResult = await db.raw(
        `UPDATE advertisements 
        SET title = ?, description = ?, price = ?, ad_type = ?, owner_phone_number = ?
        WHERE ad_id = ?`,
        [title, description, parsedPrice, ad_type, owner_phone_number, parsedAdId]
      );

      if (updateAdResult[0].affectedRows === 0) {
        await db.raw('ROLLBACK');
        return res.status(404).json({ message: 'آگهی یافت نشد' });
      }

      // Update category-specific tables
      if (ad_type === 'REAL_ESTATE') {
        if (realEstateType === 'SALE') {
          await db.raw(
            `UPDATE realEstateAds 
            SET totalPriceId = ?, deposit = NULL, monthlyRentPrice = NULL
          WHERE adId = ?`,
            [parsedTotalPrice, parsedAdId]
          );
        } else if (realEstateType === 'RENT') {
          await db.raw(
            `UPDATE realEstateAds 
            SET deposit = ?, monthlyRentPrice = ?, totalPrice = NULL
          WHERE adId = ?`,
            [parsedDeposit, parsedMonthlyRent, parsedAdId]
          );
        }
      } else if (ad_type === 'VEHICLE') {
        await db.raw(
          `UPDATE vehiclesAds 
          SET basePrice = ?
          WHERE adId = ?`,
          [parsedBasePrice, parsedAdId]
        );
      } else if (ad_type === 'DIGITAL') {
        await db.raw(
          `UPDATE digital_ads SET brand = ?, model = ?, item_condition = ? WHERE ad_id = ?`,
          [brand, model, item_condition, parsedAdId]
        );
      } else if (ad_type === 'HOME') {
        await db.raw(
          `UPDATE home_ads SET brand = ?, model = ?, item_condition = ? WHERE ad_id = ?`,
          [brand, model, item_condition, parsedAdId]
        );
      } else if (ad_type === 'PERSONAL') {
        await db.raw(
          `UPDATE personal_ads SET brand = ?, model = ?, item_condition = ? WHERE ad_id = ?`,
          [brand, model, item_condition, parsedAdId]
        );
      } else if (ad_type === 'ENTERTAINMENT') {
        await db.raw(
            `UPDATE entertainment_ads SET brand = ?, model = ?, item_condition = ? ad_id = ?`,
            [brand, model, item_condition, parsedAdId]
          );
      } else if (ad_type === 'SERVICES') {
        await db.raw(
          `UPDATE services_ads SET service_type = ?, service_duration = ? WHERE ad_id = ?`,
          [service_type, parsedServiceDuration, parsedAdId]
        );
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