// routes/ocr.js

// Import modules
const express = require('express');
const router = express.Router();
const { logRequest } = require('./middleware/logRequest');
const { uploadDocumentPicture } = require('./middleware/ocr-uploadDocumentPicture');
const { validatePost } = require('./validator/ocr');
const { post } = require('../controller/ocr');




// https://codexai.eniac-corp.com/api/ocr
router.post('/', uploadDocumentPicture, validatePost, post);

module.exports = router;
