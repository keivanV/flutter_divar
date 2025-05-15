
const db = require('../config/db');

async function getProvinces(req, res) {
  try {
    const provincesResult = await db.raw('SELECT province_id, name FROM provinces ORDER BY name');
    const provinces = provincesResult[0];
    res.status(200).json(provinces);
  } catch (error) {
    console.error('Error fetching provinces:', error);
    res.status(500).json({ message: `خطا در دریافت استان‌ها: ${error.message}` });
  }
}

async function getCities(req, res) {
  try {
    const { province_id } = req.query;
    if (!province_id || isNaN(parseInt(province_id))) {
      return res.status(400).json({ message: 'شناسه استان الزامی است' });
    }
    const citiesResult = await db.raw(
      'SELECT city_id, name FROM cities WHERE province_id = ? ORDER BY name',
      [parseInt(province_id)]
    );
    const cities = citiesResult[0];
    res.status(200).json(cities);
  } catch (error) {
    console.error('Error fetching cities:', error);
    res.status(500).json({ message: `خطا در دریافت شهرها: ${error.message}` });
  }
}

module.exports = {
  getProvinces,
  getCities,
};
