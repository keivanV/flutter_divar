
const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

router.post('/', userController.registerUser);
router.get('/:phoneNumber', userController.getUserProfile);
router.get('/:phoneNumber/ads', userController.getUserAds);
router.get('/:phoneNumber/comments', userController.getUserComments); 
router.post('/ads/by-ids', userController.getAdsByIds);

module.exports = router;
