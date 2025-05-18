const db = require('../config/db');

const authMiddleware = async (req, res, next) => {
  const adminId = req.headers['x-admin-id'];
  if (!adminId || isNaN(adminId)) {
    return res.status(401).json({ message: 'شناسه ادمین نامعتبر است' });
  }
  try {
    const admin = await db('admins').where({ admin_id: adminId }).first();
    if (!admin) {
      return res.status(401).json({ message: 'ادمین نامعتبر است' });
    }
    req.admin = { adminId: admin.admin_id, username: admin.username };
    next();
  } catch (error) {
    console.error('خطا در اعتبارسنجی ادمین:', error);
    res.status(401).json({ message: 'خطای اعتبارسنجی' });
  }
};

module.exports = authMiddleware;