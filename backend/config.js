// config.js

// Import modules
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');


// Define OCR engine options
const tecOCRHome = path.resolve(__dirname, './ocr');
const tecOCRLayouts = path.resolve(__dirname, './ocr/layouts');
const tecOCRScript = 'tec-ocr.sh';
const tecOCRSimulationScript = (process.platform === 'win32') ? 'tec-ocr-simulation.bat' : 'tec-ocr-simulation.sh';
const tecOCRCommandTimeout = 30000; // 30 seconds


// Define default configuration and load configuration from .env file
const defaultDebugMode = false;
const defaultBackendHttpPort = 8080;
const defaultBackendHttpsPort = 8443;
const defaultBackendSSLCertificate = '../shared/assets/ssl/eniac-corp.com.crt';
const defaultBackendSSLCertificateKey = '../shared/assets/ssl/eniac-corp.com.key';
const defaultBackendTimeInSecondsForGracefulShutdown = 10;
const defaultOcrDocumentPictureUploadDirectory = '../shared/uploads';
const defaultOcrDocumentPictureMaxFileSizeInMB = 5;
const defaultOcrSimulationMode = false;
dotenv.config();
const config = {
  debugMode: (process.env.DEBUG_MODE === 'true') || defaultDebugMode,
  backendHttpPort: parseInt(process.env.BACKEND_HTTP_PORT || defaultBackendHttpPort, 10),
  backendHttpsPort: parseInt(process.env.BACKEND_HTTPS_PORT || defaultBackendHttpsPort, 10),
  backendSSLCertificate: path.resolve(__dirname, process.env.BACKEND_SSL_CERTIFICATE || defaultBackendSSLCertificate),
  backendSSLCertificateKey: path.resolve(__dirname, process.env.BACKEND_SSL_CERTIFICATE_KEY || defaultBackendSSLCertificateKey),
  backendTimeInSecondsForGracefulShutdown: parseInt(process.env.BACKEND_TIME_IN_SECONDS_FOR_GRACEFUL_SHUTDOWN || defaultBackendTimeInSecondsForGracefulShutdown, 10),
  ocrDocumentPictureUploadDirectory: path.resolve(__dirname, process.env.OCR_DOCUMENT_PICTURE_UPLOAD_DIRECTORY || defaultOcrDocumentPictureUploadDirectory),
  ocrDocumentPictureMaxFileSizeInMB: parseInt(process.env.OCR_DOCUMENT_PICTURE_MAX_FILE_SIZE_IN_MB || defaultOcrDocumentPictureMaxFileSizeInMB, 10),
  ocrHome: tecOCRHome,
  ocrLayouts: tecOCRLayouts,
  ocrCommand: ((process.env.OCR_SIMULATION_MODE === 'true') || defaultOcrSimulationMode) ? path.resolve(tecOCRHome, tecOCRSimulationScript) : path.resolve(tecOCRHome, tecOCRScript),
  ocrCommandTimeout: tecOCRCommandTimeout,
  ocrSimulationMode: (process.env.OCR_SIMULATION_MODE === 'true') || defaultOcrSimulationMode,
  ocrPlatform: process.platform === 'win32' ? 'windows' : 'linux',
};


// Initialize upload directory... remove its contents if it exists, otherwise create it
if (fs.existsSync(config.ocrDocumentPictureUploadDirectory)) {
  const files = fs.readdirSync(config.ocrDocumentPictureUploadDirectory);
  if (files.length > 0) {
    console.log(__filename + `Clearing existing files from upload directory: ${config.ocrDocumentPictureUploadDirectory}`);
    files.forEach((file) => {
      const filePath = path.join(config.ocrDocumentPictureUploadDirectory, file);
      if (fs.lstatSync(filePath).isFile()) {
        fs.unlinkSync(filePath);
      }
    });
    console.log(__filename + 'Upload directory cleared.');
  } 
} else {
  console.log(__filename + `Creating upload directory: ${config.ocrDocumentPictureUploadDirectory}`);
  fs.mkdirSync(config.ocrDocumentPictureUploadDirectory, { recursive: true });
  console.log(__filename + 'Upload directory created.');
}

module.exports = config;
