// controller/ocr.js

// Import modules
const { StatusCodes, ReasonPhrases } = require('http-status-codes');
const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');
const { promisify } = require('util');
const execFileAsync = promisify(execFile);
const config = require('../config');




// Implement POST for /api/ocr
/**
 * Mock OCR processing controller
 * Assumes req.file is valid and req.body.documentLayout is validated
 */
const post = async (req, res) => {
  // Get request details (already validated by middleware)
  const documentLayout = req.body.documentLayout;
  const file = req.file;
  const jsonFilename = file.path + '.json';
  if (config.debugMode) {
    console.log(__filename + `:   [DEBUG] New document request:`);
    console.log(__filename + `:   [DEBUG]   Layout: ${documentLayout}`);
    console.log(__filename + `:   [DEBUG]   Image:  ${file.originalname} (${file.mimetype}, ${file.size} bytes)`);
    console.log(__filename + `:   [DEBUG]           ${file.path}`);
    console.log(__filename + `:   [DEBUG]   JSON:   ${jsonFilename}`);
  }


  try {
    // Start OCR processing
    if (config.debugMode)
      console.log(__filename + `:   [DEBUG] Starting OCR processing...`);
    const ocrStartProcessing = new Date();


    // If OCR simulation mode is enabled, simulate an OCR processign error randomly
    if (config.ocrSimulationMode) {
      // Simulate OCR processing
      // For demonstration purposes, we will mock the OCR result
      await new Promise(resolve => setTimeout(resolve, 250));
      //// Randomly decide if OCR should fail (for testing frontend error handling)
      const simulateError = Math.random() < 0.25; // 25% chance
      if (simulateError) {
        // Simulated OCR error response
        const ocrEndProcessing = new Date();
        throw new Error('Unexpected error during OCR processing (simulated)', { cause: new Error('Simulated OCR processing error for testing purposes.') });
      }    
    }


    // Invoke the OCR command-line tool
    try {
      const ocrCommand = config.ocrCommand;
      const ocrLayouts = config.ocrLayouts;
      if (config.debugMode)
        console.log(__filename + ':   [DEBUG] Invoking OCR ' + (config.ocrSimulationMode ? 'SIMULATION' : '') + ` command: ${ocrCommand} --image=${file.path} --layout=${ocrLayouts}/${documentLayout} --output=${jsonFilename} --quiet`);
      const { stdout, stderr } = await execFileAsync(ocrCommand, [
        `--image=${file.path}`,
        `--layout=${ocrLayouts}/${documentLayout}`,
        `--output=${jsonFilename}`,
        `--quiet`
      ], 
      { 
        timeout: config.ocrCommandTimeout, 
        shell: config.ocrPlatform === 'windows' ? true : false,
        cwd: path.dirname(ocrCommand)
      });
      if (config.debugMode) {
        console.log(__filename + `:   [DEBUG] OCR command output:       ${stdout}`);
        if (stderr) console.error(__filename + `:   [DEBUG] OCR command error output: ${stderr}`);
      }
    } catch (error) {
      throw new Error('OCR command execution failed.', { cause: error });
    }


    // Read and parse the OCR result from the generated JSON file
    let ocrResult;
    try {
      const jsonData = await fs.promises.readFile(jsonFilename, 'utf-8');
      ocrResult = JSON.parse(jsonData);
    } catch (error) {
      throw new Error('Failed to read or parse OCR result JSON file.', { cause: error });
    }


    // Delete temporary files... only in not-debug mode
    if (!config.debugMode) {
      try {
        await fs.promises.unlink(jsonFilename);
      } catch (error) {
        throw new Error('Failed to delete temporary JSON file.', { cause: error });
      }
      try {
        await fs.promises.unlink(file.path);
      } catch (error) {
        throw new Error('Failed to delete temporary image file.', { cause: error });
      }
    }
    else {
      console.log(__filename + `:   [DEBUG] Temporary files ${jsonFilename} and ${file.path} retained (debug mode).`);
    }


    // OCR processing completed
    const ocrEndProcessing = new Date();
    if (config.debugMode)
      console.log(__filename + `:   [DEBUG] OCR processing completed in ${ocrEndProcessing - ocrStartProcessing} ms`);



    // Build response
    const ocrResponse = {
      documentLayout,
      documentPictureFilename: file.originalname,
      documentData: ocrResult,
      ocrStartProcessing,
      ocrEndProcessing,
      ocrElapsedTime: ocrEndProcessing - ocrStartProcessing
    };


    // Send response
    res.status(StatusCodes.OK).json({
      success: true,
      status: ReasonPhrases.OK,
      message: 'OCR executed successfully (mock)',
      data: ocrResponse
    });
  } catch (error) {
    console.error(__filename + `:   [ERROR] OCR processing failed:`, error);
    // Delete temporary files... only in not-debug mode
    if (!config.debugMode) {
      if (fs.existsSync(jsonFilename)) {
        try {
          fs.unlinkSync(jsonFilename);
        } catch (error) {
          console.error(__filename + `:   [ERROR] Failed to delete temporary JSON file ${jsonFilename}:`, error);
        }
      }
      if (fs.existsSync(file.path)) {
        try {
          fs.unlinkSync(file.path);
        } catch (error) {
          console.error(__filename + `:   [ERROR] Failed to delete temporary image file ${file.path}:`, error);
        }
      }
    }
    else
      console.log(__filename + `:   [DEBUG] Temporary files ${jsonFilename} and ${file.path} retained (debug mode).`);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      status: ReasonPhrases.INTERNAL_SERVER_ERROR,
      message: 'Unexpected error during OCR processing.',
      errorCode: "OCR_PROCESSING_ERROR",
      errors: [{ msg: error.message }]
    });
  }
};

module.exports = { post };
