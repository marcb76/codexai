// config.js

// Import modules
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');




// Define default configuration and load configuration from .env file
const defaultBackendHttpPort = 8080;
const defaultBackendHttpsPort = 8443;
const defaultBackendSSLCertificate = '../shared/assets/ssl/eniac-corp.com.crt';
const defaultBackendSSLCertificateKey = '../shared/assets/ssl/eniac-corp.com.key';
const defaultBackendTimeInSecondsForGracefulShutdown = 10;
const defaultOcrDocumentPictureUploadDirectory = '../shared/uploads';
const defaultOcrDocumentPictureMaxFileSizeInMB = 5;
dotenv.config();
const config = {
  backendHttpPort: parseInt(process.env.BACKEND_HTTP_PORT || defaultBackendHttpPort, 10),
  backendHttpsPort: parseInt(process.env.BACKEND_HTTPS_PORT || defaultBackendHttpsPort, 10),
  backendSSLCertificate: path.resolve(__dirname, process.env.BACKEND_SSL_CERTIFICATE || defaultBackendSSLCertificate),
  backendSSLCertificateKey: path.resolve(__dirname, process.env.BACKEND_SSL_CERTIFICATE_KEY || defaultBackendSSLCertificateKey),
  backendTimeInSecondsForGracefulShutdown: parseInt(process.env.BACKEND_TIME_IN_SECONDS_FOR_GRACEFUL_SHUTDOWN || defaultBackendTimeInSecondsForGracefulShutdown, 10),
  ocrDocumentPictureUploadDirectory: path.resolve(__dirname, process.env.OCR_DOCUMENT_PICTURE_UPLOAD_DIRECTORY || defaultOcrDocumentPictureUploadDirectory),
  ocrDocumentPictureMaxFileSizeInMB: parseInt(process.env.OCR_DOCUMENT_PICTURE_MAX_FILE_SIZE_IN_MB || defaultOcrDocumentPictureMaxFileSizeInMB, 10),
};


// Create upload directory if it doesn't exist
if (!fs.existsSync(config.ocrDocumentPictureUploadDirectory)) {
  fs.mkdirSync(config.ocrDocumentPictureUploadDirectory, { recursive: true });
}

module.exports = config;
