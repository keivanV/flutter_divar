
const express = require('express');
const router = express.Router();
const locationController = require('../controllers/locationController');

router.get('/provinces', locationController.getProvinces);
router.get('/cities', locationController.getCities);

module.exports = router;
