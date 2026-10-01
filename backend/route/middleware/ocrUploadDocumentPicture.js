// routes/middleware/ocr-uploadDocumentPicture.js

// Import modules
const { StatusCodes, ReasonPhrases } = require('http-status-codes');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const config = require('../../config');




// Multer basic configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, config.ocrDocumentPictureUploadDirectory);
  },
  filename: (req, file, cb) => {
    // Keep original name with a timestamp prefix to avoid collisions
    cb(null, `${Date.now()}-${file.originalname.replace(/\s+/g, '-')}`);
  }
});


// Multer filter: accept only images and PDFs
const fileFilter = (req, file, cb) => {
  const allowedTypes = ['image/png', 'image/jpeg', 'image/jpg', 'application/pdf'];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only PNG, JPG, JPEG, and PDF are allowed.'));
  }
};


// Multer limit: file max size
const upload = multer({storage, fileFilter, limits: { fileSize: config.ocrDocumentPictureMaxFileSizeInMB * 1024 * 1024 } });




// Multer middleware for upload document picture
const uploadDocumentPicture = (req, res, next) => {
  upload.single('documentPicture')(req, res, (err) => {
    if (err) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        status: ReasonPhrases.BAD_REQUEST,
        errors: [{ msg: err.message }]
      });
    }
    if (!req.file) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        status: ReasonPhrases.BAD_REQUEST,
        errors: [{ msg: 'Please provide a document picture' }]
      });
    }
    next();
  });
};

module.exports = { uploadDocumentPicture };
