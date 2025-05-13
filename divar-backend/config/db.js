
const knex = require('knex')({
  client: 'mysql2',
  connection: {
    host: 'localhost',
    user: 'root',
    password: 'root',
    database: 'divar_app',
  },
  pool: { min: 0, max: 10 },
});

module.exports = knex;
