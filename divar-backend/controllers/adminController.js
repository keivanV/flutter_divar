const db = require('../config/db');
const bcrypt = require('bcrypt');

const adminController = {
  async login(req, res) {
    try {
      const { username, password } = req.body;
      console.log('Login attempt:', { username, password }); // Added
      if (!username || !password) {
        return res.status(400).json({ message: 'نام کاربری و رمز عبور الزامی است' });
      }
      const admin = await db('admins').where({ username }).first();
      if (!admin) {
        console.log('Admin not found for username:', username); // Added
        return res.status(401).json({ message: 'نام کاربری یا رمز عبور اشتباه است' });
      }
      const isMatch = await bcrypt.compare(password, admin.password_hash);
      console.log('Password match:', isMatch, 'Stored hash:', admin.password_hash); // Added
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
      const [{ count }] = await db('users').count('* as count');
      res.json({ totalUsers: Number(count) });
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
      const { ad_type } = req.query;
      let query = db('advertisements')
        .select('ad_type')
        .count('* as count')
        .groupBy('ad_type');
      if (ad_type) {
        query = query.where({ ad_type });
      }
      const counts = await query;
      res.json(counts);
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

  // متد جدید برای دریافت آگهی‌ها با تعداد کامنت‌ها
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
        .limit(50); // Limit to prevent large responses
        res.json(comments);
    } catch (error) {
        console.error('خطا در دریافت همه کامنت‌ها:', error);
        res.status(500).json({ message: 'خطای سرور' });
    }
    },



  // متد جدید برای دریافت کامنت‌های یک آگهی
  async getCommentsByAdId(req, res) {
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
      const comments = await db('comments')
        .where({ ad_id: adId })
        .select('comment_id', 'ad_id', 'user_phone_number', 'content', 'created_at');
      res.json(comments);
    } catch (error) {
      console.error('خطا در دریافت کامنت‌های آگهی:', error);
      res.status(500).json({ message: 'خطای سرور' });
    }
  },
};

module.exports = adminController;