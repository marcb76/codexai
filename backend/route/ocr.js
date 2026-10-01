// routes/ocr.js

// Import modules
const express = require('express');
const router = express.Router();
const { uploadDocumentPicture } = require('./middleware/ocrUploadDocumentPicture');
const { logRequest } = require('./middleware/logRequest');
const { validatePost } = require('./validator/ocr');
const { post } = require('../controller/ocr');




// https://codexai.mbonet.xyz/api/ocr
router.post('/', uploadDocumentPicture, logRequest, validatePost, post);

module.exports = router;
