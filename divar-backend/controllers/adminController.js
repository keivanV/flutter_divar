const db = require('../config/db');
const bcrypt = require('bcrypt');
const moment = require('moment-timezone');


const multer = require('multer');
const path = require('path');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  },
});

const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    const filetypes = /jpeg|jpg|png/;
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = filetypes.test(file.mimetype) || file.mimetype === 'image/jpg';
    console.log('File info:', {
      originalname: file.originalname,
      mimetype: file.mimetype,
      extname: path.extname(file.originalname).toLowerCase(),
    }); // لاگ برای دیباگ
    if (extname && mimetype) {
      return cb(null, true);
    } else {
      const error = new Error('فقط تصاویر JPG/PNG مجاز هستند');
      console.error('File rejected:', error.message, { mimetype: file.mimetype });
      cb(error);
    }
  },
}).single('image');


const adminController = {
  async login(req, res) {
    try {
      const { username, password } = req.body;
      console.log('Login attempt:', { username, password });
      if (!username || !password) {
        return res.status(400).json({ message: 'نام کاربری و رمز عبور الزامی است' });
      }
      const admin = await db('admins').where({ username }).first();
      if (!admin) {
        console.log('Admin not found for username:', username);
        return res.status(401).json({ message: 'نام کاربری یا رمز عبور اشتباه است' });
      }
      const isMatch = await bcrypt.compare(password, admin.password);
      console.log('Password match:', isMatch, 'Stored hash:', admin.password);
      if (!isMatch) {
        return res.status(401).json({ message: 'نام کاربری یا رمز عبور اشتباه است' });
      }
      res.json({ success: true, adminId: admin.admin_id });
    } catch (error) {
      console.error('خطا در لاگین ادمین:', error);
      res.status(500).json({ message: 'خطای سرور' });
    }
  },

  async getUsersCount(req, res) {
    try {
      const adminId = req.headers['x-admin-id'];
      if (!adminId || isNaN(adminId)) {
        return res.status(401).json({ message: 'شناسه ادمین نامعتبر است' });
      }
      const admin = await db('admins').where({ admin_id: adminId }).first();
      if (!admin) {
        return res.status(401).json({ message: 'ادمین نامعتبر است' });
      }
      const { time_period } = req.query;

      // تنظیم منطقه زمانی به تهران
      const tehranTime = moment().tz('Asia/Tehran');
      const today = tehranTime.format('YYYY-MM-DD');

      // دریافت تعداد کل کاربران
      const [{ totalUsers }] = await db('users').count('* as totalUsers');

      let statsQuery;
      let stats = [];

      switch (time_period) {
        case 'day':
          statsQuery = db('users')
            .select(db.raw('HOUR(CONVERT_TZ(created_at, "UTC", "Asia/Tehran")) as hour'))
            .count('* as count')
            .whereRaw('DATE(CONVERT_TZ(created_at, "UTC", "Asia/Tehran")) = ?', [today])
            .groupByRaw('HOUR(CONVERT_TZ(created_at, "UTC", "Asia/Tehran"))')
            .orderBy('hour', 'asc');
          break;
        case 'week':
          const startOfWeek = tehranTime.clone().startOf('week').format('YYYY-MM-DD'); // شروع هفته میلادی
          statsQuery = db('users')
            .select(db.raw('DATE(CONVERT_TZ(created_at, "UTC", "Asia/Tehran")) as date'))
            .count('* as count')
            .whereBetween('created_at', [startOfWeek, today])
            .groupByRaw('DATE(CONVERT_TZ(created_at, "UTC", "Asia/Tehran"))')
            .orderBy('date', 'asc');
          break;
        case 'month':
          statsQuery = db('users')
            .select(db.raw('DATE_FORMAT(CONVERT_TZ(created_at, "UTC", "Asia/Tehran"), "%Y-%m") as date'))
            .count('* as count')
            .where('created_at', '>=', db.raw('DATE_SUB(CURDATE(), INTERVAL 12 MONTH)'))
            .groupByRaw('DATE_FORMAT(CONVERT_TZ(created_at, "UTC", "Asia/Tehran"), "%Y-%m")')
            .orderBy('date', 'desc')
            .limit(12);
          break;
        case 'year':
          statsQuery = db('users')
            .select(db.raw('YEAR(CONVERT_TZ(created_at, "UTC", "Asia/Tehran")) as date'))
            .count('* as count')
            .where('created_at', '>=', db.raw('DATE_SUB(CURDATE(), INTERVAL 5 YEAR)'))
            .groupByRaw('YEAR(CONVERT_TZ(created_at, "UTC", "Asia/Tehran"))')
            .orderBy('date', 'desc')
            .limit(5);
          break;
        default:
          return res.json({ totalUsers: Number(totalUsers) });
      }

      stats = await statsQuery;
      console.log(`User stats for ${time_period}:`, stats);
      res.json({ totalUsers: Number(totalUsers), stats });
    } catch (error) {
      console.error('خطا در دریافت تعداد کاربران:', error);
      res.status(500).json({ message: 'خطای سرور' });
    }
  },

  async getAdsCount(req, res) {
    try {
      const adminId = req.headers['x-admin-id'];
      if (!adminId || isNaN(adminId)) {
        return res.status(401).json({ message: 'شناسه ادمین نامعتبر است' });
      }
      const admin = await db('admins').where({ admin_id: adminId }).first();
      if (!admin) {
        return res.status(401).json({ message: 'ادمین نامعتبر است' });
      }
      const { ad_type, time_period } = req.query;

      // تنظیم منطقه زمانی به تهران
      const tehranTime = moment().tz('Asia/Tehran');
      const today = tehranTime.format('YYYY-MM-DD');
      console.log(`Tehran time: ${tehranTime.format()}, Today: ${today}`);

      // دریافت تعداد کلی آگهی‌ها بر اساس نوع
      let countQuery = db('advertisements')
        .select('ad_type')
        .count('* as count')
        .groupBy('ad_type');
      if (ad_type) {
        countQuery = countQuery.where({ ad_type });
      }
      const adCounts = await countQuery;

      let statsQuery;
      let stats = [];

      switch (time_period) {
        case 'day':
          statsQuery = db('advertisements')
            .select(db.raw('HOUR(created_at) as hour'))
            .count('* as count')
            .whereRaw('DATE(created_at) = ?', [today])
            .groupByRaw('HOUR(created_at)')
            .orderBy('hour', 'asc');
          break;
        case 'week':
          const startOfWeek = tehranTime.clone().startOf('week').format('YYYY-MM-DD');
          statsQuery = db('advertisements')
            .select(db.raw('DATE(created_at) as date'))
            .count('* as count')
            .whereRaw('DATE(created_at) BETWEEN ? AND ?', [startOfWeek, today])
            .groupByRaw('DATE(created_at)')
            .orderBy('date', 'asc');
          break;
        case 'month':
          statsQuery = db('advertisements')
            .select(db.raw('DATE_FORMAT(created_at, "%Y-%m") as date'))
            .count('* as count')
            .whereRaw('created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)')
            .groupByRaw('DATE_FORMAT(created_at, "%Y-%m")')
            .orderBy('date', 'asc');
          break;
        case 'year':
          statsQuery = db('advertisements')
            .select(db.raw('YEAR(created_at) as date'))
            .count('* as count')
            .whereRaw('created_at >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR)')
            .groupByRaw('YEAR(created_at)')
            .orderBy('date', 'asc');
          break;
        default:
          return res.json(adCounts);
      }

      stats = await statsQuery;
      console.log(`Ad stats for ${time_period}:`, stats);
      res.json({ adCounts, stats });
    } catch (error) {
      console.error('خطا در دریافت تعداد آگهی‌ها:', error);
      res.status(500).json({ message: 'خطای سرور' });
    }
  },

  async getCommentsCount(req, res) {
    try {
      const adminId = req.headers['x-admin-id'];
      if (!adminId || isNaN(adminId)) {
        return res.status(401).json({ message: 'شناسه ادمین نامعتبر است' });
      }
      const admin = await db('admins').where({ admin_id: adminId }).first();
      if (!admin) {
        return res.status(401).json({ message: 'ادمین نامعتبر است' });
      }
      const { ad_type } = req.query;
      let query = db('comments')
        .join('advertisements', 'comments.ad_id', 'advertisements.ad_id')
        .select('advertisements.ad_type')
        .count('comments.comment_id as count')
        .groupBy('advertisements.ad_type');
      if (ad_type) {
        query = query.where('advertisements.ad_type', ad_type);
      }
      const counts = await query;
      res.json(counts);
    } catch (error) {
      console.error('خطا در دریافت تعداد نظرات:', error);
      res.status(500).json({ message: 'خطای سرور' });
    }
  },

  async getTopCommentedAd(req, res) {
    try {
      const adminId = req.headers['x-admin-id'];
      if (!adminId || isNaN(adminId)) {
        return res.status(401).json({ message: 'شناسه ادمین نامعتبر است' });
      }
      const admin = await db('admins').where({ admin_id: adminId }).first();
      if (!admin) {
        return res.status(401).json({ message: 'ادمین نامعتبر است' });
      }
      const topAd = await db('comments')
        .join('advertisements', 'comments.ad_id', 'advertisements.ad_id')
        .count('comments.comment_id as comment_count')
        .select('advertisements.ad_id', 'advertisements.title', 'advertisements.ad_type')
        .groupBy('comments.ad_id', 'advertisements.title', 'advertisements.ad_type')
        .orderBy('comment_count', 'desc')
        .first();
      res.json(topAd || {});
    } catch (error) {
      console.error('خطا در دریافت آگهی پرنظر:', error);
      res.status(500).json({ message: 'خطای سرور' });
    }
  },

  async deleteAd(req, res) {
    try {
      const adminId = req.headers['x-admin-id'];
      if (!adminId || isNaN(adminId)) {
        return res.status(401).json({ message: 'شناسه ادمین نامعتبر است' });
      }
      const admin = await db('admins').where({ admin_id: adminId }).first();
      if (!admin) {
        return res.status(401).json({ message: 'ادمین نامعتبر است' });
      }
      const { adId } = req.params;
      const deleted = await db('advertisements').where({ ad_id: adId }).del();
      if (!deleted) {
        return res.status(404).json({ message: 'آگهی یافت نشد' });
      }
      res.json({ message: 'آگهی با موفقیت حذف شد' });
    } catch (error) {
      console.error('خطا در حذف آگهی:', error);
      res.status(500).json({ message: 'خطای سرور' });
    }
  },

  async deleteComment(req, res) {
    try {
      const adminId = req.headers['x-admin-id'];
      if (!adminId || isNaN(adminId)) {
        return res.status(401).json({ message: 'شناسه ادمین نامعتبر است' });
      }
      const admin = await db('admins').where({ admin_id: adminId }).first();
      if (!admin) {
        return res.status(401).json({ message: 'ادمین نامعتبر است' });
      }
      const { commentId } = req.params;
      const deleted = await db('comments').where({ comment_id: commentId }).del();
      if (!deleted) {
        return res.status(404).json({ message: 'نظر یافت نشد' });
      }
      res.json({ message: 'نظر با موفقیت حذف شد' });
    } catch (error) {
      console.error('خطا در حذف نظر:', error);
      res.status(500).json({ message: 'خطای سرور' });
    }
  },

  async getAdsWithCommentCount(req, res) {
    try {
      const adminId = req.headers['x-admin-id'];
      if (!adminId || isNaN(adminId)) {
        return res.status(401).json({ message: 'شناسه ادمین نامعتبر است' });
      }
      const admin = await db('admins').where({ admin_id: adminId }).first();
      if (!admin) {
        return res.status(401).json({ message: 'ادمین نامعتبر است' });
      }
      const ads = await db('advertisements')
        .leftJoin('comments', 'advertisements.ad_id', 'comments.ad_id')
        .select(
          'advertisements.ad_id',
          'advertisements.title',
          'advertisements.ad_type',
          'advertisements.owner_phone_number',
          'advertisements.province_id',
          'advertisements.city_id',
          'advertisements.description',
          'advertisements.price',
          'advertisements.created_at'
        )
        .count('comments.comment_id as comment_count')
        .groupBy(
          'advertisements.ad_id',
          'advertisements.title',
          'advertisements.ad_type',
          'advertisements.owner_phone_number',
          'advertisements.province_id',
          'advertisements.city_id',
          'advertisements.description',
          'advertisements.price',
          'advertisements.created_at'
        );
      res.json(ads);
    } catch (error) {
      console.error('خطا در دریافت آگهی‌ها با تعداد کامنت‌ها:', error);
      res.status(500).json({ message: 'خطای سرور' });
    }
  },

  async getAllComments(req, res) {
    try {
      const adminId = req.headers['x-admin-id'];
      if (!adminId || isNaN(adminId)) {
        return res.status(401).json({ message: 'شناسه ادمین نامعتبر است' });
      }
      const admin = await db('admins').where({ admin_id: adminId }).first();
      if (!admin) {
        return res.status(401).json({ message: 'ادمین نامعتبر است' });
      }
      const { offset = 0 } = req.query;
      const comments = await db('comments')
        .select('comment_id', 'ad_id', 'user_phone_number', 'content', 'created_at')
        .offset(offset)
        .limit(50);
      res.json(comments);
    } catch (error) {
      console.error('خطا در دریافت همه کامنت‌ها:', error);
      res.status(500).json({ message: 'خطای سرور' });
    }
  },

  async getCommentsByAdId(req, res) {
    try {
      console.log("*****************************");
      const adminId = req.headers['x-admin-id'];
      if (!adminId || isNaN(adminId)) {
        return res.status(401).json({ message: 'شناسه ادمین نامعتبر است' });
      }
      const admin = await db('admins').where({ admin_id: adminId }).first();
      if (!admin) {
        return res.status(401).json({ message: 'ادمین نامعتبر است' });
      }
      const { adId } = req.params;
      const parsedAdId = parseInt(adId);
      if (!parsedAdId || isNaN(parsedAdId)) {
        return res.status(400).json({ message: 'شناسه آگهی نامعتبر است' });
      }
      const comments = await db('comments as c')
        .leftJoin('users as u', 'c.user_phone_number', 'u.phone_number')
        .where('c.ad_id', parsedAdId)
        .select(
          'c.comment_id',
          'c.ad_id',
          'c.user_phone_number',
          'u.nickname',
          'c.content',
          'c.created_at'
        )
        .orderBy('c.created_at', 'desc');
      res.status(200).json(comments);
    } catch (error) {
      console.error('خطا در دریافت کامنت‌های آگهی:', error);
      res.status(500).json({ message: `خطای سرور: ${error.message}` });
    }
  },

async getPromoAds(req, res) {
    try {
      const adminId = req.headers['x-admin-id'];
      if (!adminId || isNaN(adminId)) {
        return res.status(401).json({ message: 'شناسه ادمین نامعتبر است' });
      }
      const admin = await db('admins').where({ admin_id: adminId }).first();
      if (!admin) {
        return res.status(401).json({ message: 'ادمین نامعتبر است' });
      }
      const promoAds = await db('promo_ads').select('*').orderBy('created_at', 'desc');
      res.status(200).json(promoAds);
    } catch (error) {
      console.error('خطا در دریافت تبلیغ‌ها:', error);
      res.status(500).json({ message: 'خطای سرور' });
    }
  },

async createPromoAd(req, res) {
  upload(req, res, async (err) => {
    try {
      if (err) {
        console.error('خطای آپلود:', err);
        return res.status(400).json({ message: err.message });
      }
      const adminId = req.headers['x-admin-id'];
      if (!adminId || isNaN(adminId)) {
        return res.status(401).json({ message: 'شناسه ادمین نامعتبر است' });
      }
      const admin = await db('admins').where({ admin_id: adminId }).first();
      if (!admin) {
        return res.status(401).json({ message: 'ادمین نامعتبر است' });
      }
      const { title, ad_type, price, details } = req.body;
      if (!title || !ad_type || !price || !details) {
        return res.status(400).json({ message: 'همه فیلدها الزامی هستند' });
      }
      let image_url = 'http://localhost:5000/uploads/default-promo.jpg';
      if (req.file) {
        image_url = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
      }
      const [id] = await db('promo_ads').insert({
        title,
        ad_type,
        price,
        details,
        image_url,
        created_at: db.fn.now(),
      });
      const newAd = await db('promo_ads').where({ id }).first();
      res.status(201).json(newAd);
    } catch (error) {
      console.error('خطا در ایجاد تبلیغ:', error);
      res.status(500).json({ message: `خطای سرور: ${error.message}` });
    }
  });
},

  async updatePromoAd(req, res) {
    upload(req, res, async (err) => {
      try {
        if (err) {
          return res.status(400).json({ message: err.message });
        }
        const adminId = req.headers['x-admin-id'];
        if (!adminId || isNaN(adminId)) {
          return res.status(401).json({ message: 'شناسه ادمین نامعتبر است' });
        }
        const admin = await db('admins').where({ admin_id: adminId }).first();
        if (!admin) {
          return res.status(401).json({ message: 'ادمین نامعتبر است' });
        }
        const { id } = req.params;
        const { title, ad_type, price, details } = req.body;
        const ad = await db('promo_ads').where({ id }).first();
        if (!ad) {
          return res.status(404).json({ message: 'تبلیغ یافت نشد' });
        }
        let image_url = ad.image_url;
        if (req.file) {
          image_url = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
        }
        await db('promo_ads').where({ id }).update({
          title: title || ad.title,
          ad_type: ad_type || ad.ad_type,
          price: price || ad.price,
          details: details || ad.details,
          image_url,
          updated_at: db.fn.now(),
        });
        const updatedAd = await db('promo_ads').where({ id }).first();
        res.status(200).json(updatedAd);
      } catch (error) {
        console.error('خطا در ویرایش تبلیغ:', error);
        res.status(500).json({ message: 'خطای سرور' });
      }
    });
  },

  async deletePromoAd(req, res) {
    try {
      const adminId = req.headers['x-admin-id'];
      if (!adminId || isNaN(adminId)) {
        return res.status(401).json({ message: 'شناسه ادمین نامعتبر است' });
      }
      const admin = await db('admins').where({ admin_id: adminId }).first();
      if (!admin) {
        return res.status(401).json({ message: 'ادمین نامعتبر است' });
      }
      const { id } = req.params;
      const deleted = await db('promo_ads').where({ id }).del();
      if (!deleted) {
        return res.status(404).json({ message: 'تبلیغ یافت نشد' });
      }
      res.status(200).json({ message: 'تبلیغ با موفقیت حذف شد' });
    } catch (error) {
      console.error('خطا در حذف تبلیغ:', error);
      res.status(500).json({ message: 'خطای سرور' });
    }
  },


};

module.exports = adminController;