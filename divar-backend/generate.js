// scripts/generate_hash.js
const bcrypt = require('bcrypt');

async function generateHash(password) {
  const hash = await bcrypt.hash(password, 10);
  console.log('Generated hash:', hash);
}

generateHash('admin');