
const db = require('../config/db');

const userModel = {
  async createUser({ phone_number, first_name, last_name }) {
    try {
      const validFields = {
        phone_number,
        first_name,
        last_name,
        created_at: db.fn.now(),
      };

      const filteredFields = Object.fromEntries(
        Object.entries(validFields).filter(([_, value]) => value !== undefined && value !== null)
      );

      const [insertId] = await db('users').insert(filteredFields);
      return { insertId };
    } catch (error) {
      console.error('Error in createUser:', error);
      throw error;
    }
  },

  async getUserByPhone(phone_number) {
    try {
      const user = await db('users')
        .where('phone_number', phone_number)
        .first();
      return user || null;
    } catch (error) {
      console.error('Error in getUserByPhone:', error);
      throw error;
    }
  },
};

module.exports = userModel;
