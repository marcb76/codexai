// routes/middleware/logRequest.js

const logRequest = (req, res, next) => {
  console.log('=== Incoming Request ===');
  console.log('Headers:', req.headers);
  console.log('Body:', req.body);
  console.log('File:', req.file);
  console.log('Files:', req.files);
  next();
};

module.exports = { logRequest };