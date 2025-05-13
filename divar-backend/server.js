const express = require('express');
const multer = require('multer');
const path = require('path');
const errorHandler = require('./middleware/errorHandler');
const userRoutes = require('./routes/userRoutes');
const adRoutes = require('./routes/adRoutes');
const bookmarkRoutes = require('./routes/bookmarkRoutes');
const cors = require('cors');
require('dotenv').config();

const app = express();

app.use(cors());

// Debug middleware to log incoming requests
app.use((req, res, next) => {
  console.log(`Request received: ${req.method} ${req.url}`);
  console.log('Headers:', req.headers);
  console.log('Body (pre-multer):', req.body);
  next();
});

// تنظیمات Multer برای ذخیره فایل‌ها
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/'); // پوشه‌ای برای ذخیره تصاویر
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
    console.log(`File: ${file.originalname}, MIME: ${file.mimetype}, Ext: ${path.extname(file.originalname).toLowerCase()}, Ext Valid: ${extname}`);
    if (extname) {
      return cb(null, true);
    }
    cb(new Error('فقط تصاویر JPEG و PNG مجاز هستند'));
  },
  limits: { fileSize: 5 * 1024 * 1024 }, // حداکثر 5MB
});

app.use(express.json());

// ایجاد پوشه uploads اگر وجود نداشته باشد
const fs = require('fs');
const uploadDir = './uploads';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

// ارائه فایل‌های استاتیک از پوشه uploads
app.use('/uploads', express.static('uploads'));

app.use('/api/users', userRoutes);
app.use('/api/ads', adRoutes);
app.use('/api/bookmarks', bookmarkRoutes);

// مسیر آپلود تصاویر
app.post('/api/upload', upload.single('image'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'هیچ فایلی آپلود نشد' });
    }
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
    console.log('Image uploaded:', imageUrl);
    res.status(200).json({ imageUrl });
  } catch (error) {
    next(error);
  }
});

app.use(errorHandler);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});