const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

router.post('/', userController.registerUser);
router.get('/:phoneNumber', userController.getUserProfile);

module.exports = router;