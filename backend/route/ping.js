// routes/ping.js

// Import modules
const express = require('express');
const router = express.Router();
const { get } = require('../controller/ping');





// https://codexai.eniac-corp.com/api/ping
router.get('/', get);

module.exports = router;
