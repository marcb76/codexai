// controller/ping.js

// Import modules
const { StatusCodes, ReasonPhrases } = require('http-status-codes');




// Implement GET for /api/ping
const get = async (req, res) => {
  res.status(StatusCodes.OK).json({
    success: true,
    status: ReasonPhrases.OK,
    message: 'Pong! codexAI backend is alive.'
  });
};

module.exports = { get };
