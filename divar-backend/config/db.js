
const knex = require('knex')({
  client: 'mysql2',
  connection: {
    host: 'localhost',
    user: 'root',
    password: 'root',
    database: 'divar_app',
    charset: 'utf8mb4',
    collation: 'utf8mb4_unicode_ci'

  },
  pool: { min: 0, max: 10 },
  
});

module.exports = knex;
