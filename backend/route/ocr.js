// routes/ocr.js

// Import modules
const express = require('express');
const router = express.Router();
const { validatePost } = require('./validator/ocr');
const { uploadDocumentPicture } = require('./middleware/ocr-uploadDocumentPicture');
const { post } = require('../controller/ocr');




// https://codexai.eniac-corp.com/api/ocr
router.post('/', validatePost, uploadDocumentPicture, post);

module.exports = router;
