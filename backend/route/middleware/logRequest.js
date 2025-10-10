// routes/middleware/logRequest.js

const config = require('../../config');



// Middleware to log incoming requests for debugging
const logRequest = (req, res, next) => {
  if (config.debugMode) {
    console.log(__filename + `:   [DEBUG] New request on ${req.method} ${req.url}:`);
    console.log(__filename + `:   [DEBUG]   Headers: ${JSON.stringify(req.headers, null, 2)}`);
    console.log(__filename + `:   [DEBUG]   Body: ${JSON.stringify(req.body, null, 2)}`);
    console.log(__filename + `:   [DEBUG]   File: ${JSON.stringify(req.file, null, 2)}`);
    console.log(__filename + `:   [DEBUG]   Files: ${JSON.stringify(req.files, null, 2)}`);
  }
  next();
};

module.exports = { logRequest };