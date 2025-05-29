const express = require('express');
const multer = require('multer');
const path = require('path');
const errorHandler = require('./middleware/errorHandler');
const userRoutes = require('./routes/userRoutes');
const adminRoutes = require('./routes/adminRoutes');
const adRoutes = require('./routes/adRoutes');
const bookmarkRoutes = require('./routes/bookmarkRoutes');
const db = require('./config/db'); // Import db
const locationRoutes = require('./routes/locationRoutes');
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
    console.log(`File: ${file.originalname}, MIME: ${file.mimetype}, Ext: ${path.extname(file.originalname).toLowerCase()}, Ext Valid: ${extname}`);
    if (extname) {
      return cb(null, true);
    }
    cb(new Error('فقط تصاویر JPEG و PNG مجاز هستند'));
  },
  limits: { fileSize: 5 * 1024 * 1024 }, // حداکثر 5MB
});

app.use(express.json());


const fs = require('fs');
const uploadDir = './uploads';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}


app.use('/uploads', express.static('uploads'));
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/ads', adRoutes);
app.use('/api/bookmarks', bookmarkRoutes);
app.use('/api', locationRoutes); 


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


app.get('/api/promo-ad', async (req, res, next) => {
  try {
    console.log('درخواست تبلیغ پرموشنال');
    const ads = await db('promo_ads').select('*');
    if (ads.length === 0) {
      return res.status(404).json({ error: 'هیچ تبلیغی یافت نشد' });
    }
    const randomAd = ads[Math.floor(Math.random() * ads.length)];
    res.status(200).json(randomAd);
  } catch (error) {
    console.error('خطا در دریافت تبلیغ:', error);
    next(error);
  }
});

app.use(errorHandler);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});