const express = require('express');
const router = express.Router();
const adController = require('../controllers/adController');
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
    if (extname) {
      return cb(null, true);
    }
    cb(new Error('فقط تصاویر JPEG و PNG مجاز هستند'));
  },
  limits: { fileSize: 5 * 1024 * 1024 },
});

router.get('/', adController.getAds);
router.get('/:ad_id', adController.getAdById);
router.post('/', upload.array('images', 5), adController.createAd);
router.put('/:ad_id', upload.array('images', 5), adController.updateAd);
router.delete('/:ad_id', adController.deleteAd);
router.get('/search', adController.searchAds);
router.post('/:ad_id/comments', adController.createComment);
router.get('/:ad_id/comments', adController.getComments);

module.exports = router;