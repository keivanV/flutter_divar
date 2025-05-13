// Bookmark controller
const { body, validationResult } = require('express-validator');
const bookmarkModel = require('../models/bookmarkModel');

const bookmarkController = {
  addBookmark: [
    body('user_phone_number').isLength({ min: 11, max: 11 }).isNumeric().withMessage('User phone number must be 11 digits'),
    body('ad_id').isInt().withMessage('Ad ID must be an integer'),
    async (req, res, next) => {
      try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
          return res.status(400).json({ errors: errors.array() });
        }

        const bookmarkData = req.body;
        const result = await bookmarkModel.addBookmark(bookmarkData);
        res.status(201).json({ message: 'Bookmark added successfully', insertId: result.insertId });
      } catch (error) {
        next(error);
      }
    }
  ],

  getBookmarks: async (req, res, next) => {
    try {
      const { user_phone_number } = req.params;
      const bookmarks = await bookmarkModel.getBookmarks(user_phone_number);
      res.json(bookmarks);
    } catch (error) {
      next(error);
    }
  }
};

module.exports = bookmarkController;