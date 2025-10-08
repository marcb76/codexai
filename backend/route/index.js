// routes/index.js

// Import modules
const express = require('express');
const router = express.Router();
const fs = require('fs');




// Dynamically load all routes in this folder
const ROUTES_PATH = __dirname;
const removeFileExtension = (fileName) => {
  return fileName.split('.').shift();
};
console.log(__filename + ': Loading routes...');
fs.readdirSync(ROUTES_PATH).forEach((file) => {
  const fileName = removeFileExtension(file);
  if (fileName !== 'index' && fileName !== 'validator' && fileName !== 'middleware') {
    console.log(__filename + `:   ${fileName}`);
    router.use(`/${fileName}`, require(`./${fileName}`));
  }
});
console.log(__filename + ': Routes loaded!');

module.exports = router;