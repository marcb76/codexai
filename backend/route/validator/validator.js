// routes/validator/validator.js

// Import modules
const { StatusCodes, ReasonPhrases } = require('http-status-codes');
const { validationResult } = require('express-validator');
const errorHandler = require('../errorHandler/errorHandler');




// Parse validation results and return errors if any
const parseValidationResults = (req, res, next) => {
  try {
    validationResult(req).throw();
    return next();
  } catch (error) {
    console.error(`**** ERROR ${StatusCodes.BAD_REQUEST} --> BAD_REQUEST: Validation failed.`);
    console.error(error.array());
    console.error(error.stack);
    return res.status(StatusCodes.BAD_REQUEST).json({ status: ReasonPhrases.BAD_REQUEST, errors: error.array() });
  }
};

module.exports = { parseValidationResults };
