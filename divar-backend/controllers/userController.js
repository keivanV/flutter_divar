
const { body, validationResult } = require('express-validator');
const userModel = require('../models/userModel');

const userController = {
  registerUser: [
    body('phone_number').isLength({ min: 11, max: 11 }).isNumeric().withMessage('Phone number must be 11 digits'),
    body('first_name').isString().notEmpty().withMessage('First name is required'),
    body('last_name').isString().notEmpty().withMessage('Last name is required'),
    async (req, res, next) => {
      try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
          return res.status(400).json({ errors: errors.array() });
        }

        const { phone_number, first_name, last_name } = req.body;
        const existingUser = await userModel.getUserByPhone(phone_number);
        if (existingUser) {
          return res.status(400).json({ message: 'User already exists' });
        }

        const result = await userModel.createUser({ phone_number, first_name, last_name });
        res.status(201).json({ message: 'User registered successfully', insertId: result.insertId });
      } catch (error) {
        console.error('Error in registerUser:', error);
        next(error);
      }
    },
  ],

  getUserProfile: [
    async (req, res, next) => {
      try {
        const { phoneNumber } = req.params;
        const user = await userModel.getUserByPhone(phoneNumber);
        if (!user) {
          return res.status(404).json({ message: 'User not found' });
        }
        res.json(user);
      } catch (error) {
        console.error('Error in getUserProfile:', error);
        next(error);
      }
    },
  ],
};

module.exports = userController;
