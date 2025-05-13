const fs = require('fs');
const path = require('path');

const projectStructure = {
  'config': {
    'db.js': '// Database configuration\n'
  },
  'controllers': {
    'userController.js': '// User controller\n',
    'adController.js': '// Advertisement controller\n',
    'bookmarkController.js': '// Bookmark controller\n'
  },
  'middleware': {
    'errorHandler.js': '// Error handling middleware\n'
  },
  'models': {
    'userModel.js': '// User model\n',
    'adModel.js': '// Advertisement model\n',
    'bookmarkModel.js': '// Bookmark model\n'
  },
  'routes': {
    'userRoutes.js': '// User routes\n',
    'adRoutes.js': '// Advertisement routes\n',
    'bookmarkRoutes.js': '// Bookmark routes\n'
  },
  '.env': '# Environment variables\nDB_HOST=localhost\nDB_USER=your_mysql_user\nDB_PASSWORD=your_mysql_password\nDB_NAME=divar_app\nPORT=3000\n',
  'server.js': '// Main server file\n',
  'package.json': JSON.stringify({
    name: 'divar-backend',
    version: '1.0.0',
    description: 'Backend for a Divar-like application',
    main: 'server.js',
    scripts: {
      start: 'node server.js',
      dev: 'nodemon server.js'
    },
    dependencies: {
      dotenv: '^16.0.3',
      express: '^4.18.2',
      'express-validator': '^7.0.1',
      mysql2: '^3.2.0'
    },
    devDependencies: {
      nodemon: '^2.0.22'
    }
  }, null, 2),
  'README.md': '# Divar Backend\n\nBackend for a Divar-like application using Node.js, Express, and MySQL.\n\n## Setup\n\n1. Clone the repository\n2. Install dependencies: `npm install`\n3. Create a `.env` file and configure it\n4. Ensure MySQL is running and the database is set up\n5. Run the server: `npm start` or `npm run dev`\n'
};

function createStructure(basePath, structure) {
  Object.keys(structure).forEach((key) => {
    const fullPath = path.join(basePath, key);

    if (typeof structure[key] === 'object') {
      // ایجاد پوشه
      fs.mkdirSync(fullPath, { recursive: true });
      createStructure(fullPath, structure[key]);
    } else {
      fs.writeFileSync(fullPath, structure[key]);
    }
  });
}

const projectPath = path.join(process.cwd(), 'divar-backend');
fs.mkdirSync(projectPath, { recursive: true });
createStructure(projectPath, projectStructure);

console.log('Project structure created successfully in divar-backend!');