
const express = require('express');
const router = express.Router();
const bookmarkController = require('../controllers/bookmarkController');

router.post('/', bookmarkController.addBookmark);
router.get('/:user_phone_number', bookmarkController.getBookmarks);
router.delete('/:bookmarkId', bookmarkController.deleteBookmark);

module.exports = router;
