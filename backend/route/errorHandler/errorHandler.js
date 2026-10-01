const { StatusCodes } = require('http-status-codes');

const errorHandler = (res, context, code = StatusCodes.INTERNAL_SERVER_ERROR, err) => {
  console.error(`**** ERROR ${code} --> ${context}:`);
  console.error(err.stack);
  res.status(code).send({ code: code, message: err.message });
};

module.exports = errorHandler;
