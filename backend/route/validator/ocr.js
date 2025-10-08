// routes/validator/ocr.js

const { check } = require('express-validator');
const { parseValidationResults } = require('./validator');

const documentLayouts = [ 'pr-licencia.param', 'us-passport.param', 've-cedula.param', 've-pasaporte.param'];
const validatePost = [
  check('documentLayout').isString().notEmpty().withMessage('Please define a document layout').isIn(documentLayouts).withMessage(`Document layout must be one of the following: ${documentLayouts.join(', ')}`),
  (req, res, next) => {
    return parseValidationResults(req, res, next);
  },
];

module.exports = { validatePost };
