// config.js

// Import modules
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');


// Define OCR engine options
const tecOCRHome = path.resolve(__dirname, './ocr');
const tecOCRLayouts = path.resolve(__dirname, './ocr/layouts');
const tecOCRScript = 'tec-ocr.sh';
const tecOCRSimulationScript = 'tec-ocr-simulation.bat';
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


// Initialize upload directory... remove it if it exists and create a new one
if (fs.existsSync(config.ocrDocumentPictureUploadDirectory)) {
  fs.rmSync(config.ocrDocumentPictureUploadDirectory, { recursive: true, force: true });
}
fs.mkdirSync(config.ocrDocumentPictureUploadDirectory, { recursive: true });

module.exports = config;
