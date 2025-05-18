
const express = require('express');
const router = express.Router();
const { getAds, getAdById, createAd, updateAd, deleteAd, searchAds , createComment , getComments } = require('../controllers/adController');
const multer = require('multer');
const path = require('path');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  },
});

// File filter to allow only images
const fileFilter = (req, file, cb) => {
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
  console.log(`File MIME type: ${file.mimetype}, Original name: ${file.originalname}, Extension: ${path.extname(file.originalname).toLowerCase()}`);
  if (allowedTypes.includes(file.mimetype.toLowerCase())) {
    cb(null, true);
  } else {
    cb(new Error('فقط فایل‌های تصویری (JPEG, PNG, GIF) مجاز هستند'), false);
  }
};

// Configure multer with limits and file filter
const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB file size limit
    files: 5, // Maximum 5 files per upload
  },
}).array('images', 5);

// Routes
router.get('/', getAds);
router.get('/search', searchAds);
router.get('/:ad_id', getAdById);
router.post('/', upload, createAd);
router.put('/:ad_id', updateAd);
router.delete('/:ad_id', deleteAd);
router.post('/:ad_id/comments', createComment);
router.get('/:ad_id/comments', getComments);


module.exports = router;
