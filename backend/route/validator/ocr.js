// routes/validator/ocr.js

const { check } = require('express-validator');
const { parseValidationResults } = require('./validator');

const documentLayouts = [ 'passport.param', 'pr-license.param', 'pr-sss.param', 'us-ead.param', 've-cedula.param' ];
const validatePost = [
  check('documentLayout').isString().notEmpty().withMessage('Please define a document layout').isIn(documentLayouts).withMessage(`Document layout must be one of the following: ${documentLayouts.join(', ')}`),
  (req, res, next) => {
    return parseValidationResults(req, res, next);
  },
];

module.exports = { validatePost };
