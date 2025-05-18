// backend/routes/adminRoutes.js
const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const authMiddleware = require('../middleware/authMiddleware');

// Public route
router.post('/login', adminController.login);

// Protected routes
router.get('/users/count', authMiddleware, adminController.getUsersCount);
router.get('/ads/count', authMiddleware, adminController.getAdsCount);
router.get('/comments/count', authMiddleware, adminController.getCommentsCount);
router.get('/comments/top-ad', authMiddleware, adminController.getTopCommentedAd);
router.delete('/ads/:adId', authMiddleware, adminController.deleteAd);
router.delete('/comments/:commentId', authMiddleware, adminController.deleteComment);
router.get('/ads',authMiddleware , adminController.getAdsWithCommentCount);
router.get('/ads/:adId/comments',authMiddleware, adminController.getCommentsByAdId);
router.get('/comments', authMiddleware, adminController.getAllComments);

module.exports = router;