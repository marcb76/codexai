// codexAI.js

// Import modules
const express = require('express');
const https = require('https');
const cors = require('cors');
const fs = require('fs');
const config = require('./config');


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Instanciate and initialize backend
let backend = express();
backend.use(cors());
backend.use(express.json());
backend.use('/api', require('./route'));


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Server main functions
const startServer = async () => {
  // Load environment variables from .env file
  console.log(__filename + ': Server  configuration (loaded via environment):');
  console.log(__filename + `:   debugMode: ${config.debugMode}`);
  console.log(__filename + `:   backendHttpPort: ${config.backendHttpPort}`);
  console.log(__filename + `:   backendHttpsPort: ${config.backendHttpsPort}`);
  console.log(__filename + `:   backendSSLCertificate: ${config.backendSSLCertificate}`);
  console.log(__filename + `:   backendSSLCertificateKey: ${config.backendSSLCertificateKey}`);
  console.log(__filename + `:   backendTimeInSecondsForGracefulShutdown: ${config.backendTimeInSecondsForGracefulShutdown}`);
  console.log(__filename + `:   ocrDocumentPictureUploadDirectory: ${config.ocrDocumentPictureUploadDirectory}`);
  console.log(__filename + `:   ocrDocumentPictureMaxFileSizeInMB: ${config.ocrDocumentPictureMaxFileSizeInMB}`);
  console.log(__filename + `:   ocrHome: ${config.ocrHome}`);
  console.log(__filename + `:   ocrLayouts: ${config.ocrLayouts}`);
  console.log(__filename + `:   ocrCommand: ${config.ocrCommand}`);
  console.log(__filename + `:   ocrCommandTimeout: ${config.ocrCommandTimeout} ms`);
  console.log(__filename + `:   ocrSimulationMode: ${config.ocrSimulationMode}`);
  console.log(__filename + `:   ocrPlatform: ${config.ocrPlatform}`);


  // Load SSL certificate
  console.log(__filename + ': Loading SSL certificate files...');
  console.log(__filename + `:   Certificate: ${config.backendSSLCertificate}`);
  console.log(__filename + `:   Key:         ${config.backendSSLCertificateKey}`);
  const backendSSLOptions = {
    cert: fs.readFileSync(config.backendSSLCertificate),
    key: fs.readFileSync(config.backendSSLCertificateKey),
  };
  console.log(__filename + ': Loaded!');  


  // Start server and redrect all http requests to https via an additional server
  const httpsServer = https.createServer(backendSSLOptions, backend);
  httpsServer.listen(config.backendHttpsPort, () => {
    console.log(__filename + `: HTTPS server running on port ${config.backendHttpsPort}.`);
  });
  const httpRedirection = express();
  httpRedirection.use((req, res) => {
    const redirectURL = `https://${req.hostname}:${config.backendHttpsPort}${req.url}`;
    res.redirect(301, redirectURL);
  });
  const httpServer = httpRedirection.listen(config.backendHttpPort, () => {
    console.log(__filename + `: HTTP server running on port ${config.backendHttpPort}; all requests will be redirected to HTTPS in port ${config.backendHttpsPort}.`);
  });


  // Stop server gracefully
  const stopServer = () => {
    console.log(__filename + `: Stop-Server signal received, trying to stop gracefully...`);
    httpsServer.close(async () => {
      console.log(__filename + ': HTTPS Server stopped... Have a nice day!');
      process.exit(0);
    });

    // Force close server after 10 seconds
    setTimeout(() => {
      console.warn(__filename + `: Could not stop server after ${config.backendTimeInSecondsForGracefulShutdown} seconds, forcefully stop now!`);
      process.exit(1);
    }, config.backendTimeInSecondsForGracefulShutdown * 1000);
  };

  // Listen for TERM and INT signals (kill & Ctrl-C)
  process.on('SIGTERM', stopServer);
  process.on('SIGINT', stopServer);
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Finally, start server
startServer();
