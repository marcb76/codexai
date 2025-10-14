// controller/ocr.js

// Import modules
const { StatusCodes, ReasonPhrases } = require('http-status-codes');
const fs = require('fs');
const config = require('../config');
const e = require('express');



// Implement POST for /api/ocr
/**
 * Mock OCR processing controller
 * Assumes req.file is valid and req.body.documentLayout is validated
 */
const post = async (req, res) => {
  try {
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


    // Start OCR processing
    if (config.debugMode)
      console.log(__filename + `:   [DEBUG] Starting OCR processing...`);
    const ocrStartProcessing = new Date();


    // Simulate OCR processing
    // For demonstration purposes, we will mock the OCR result
    // When OCR is implemented, replace this section with actual OCR logic
    // Here the actual OCR processing logic would be implemented
    //// In the meantime, simulate a delay for OCR processing (e.g., 250 ms)
    await new Promise(resolve => setTimeout(resolve, 250));
    //// Randomly decide if OCR should fail (for testing frontend error handling)
    const simulateError = Math.random() < 0.125; // 12.5% chance


    // OCR processing completed
    const ocrEndProcessing = new Date();
    if (config.debugMode)
      console.log(__filename + `:   [DEBUG] OCR processing completed in ${ocrEndProcessing - ocrStartProcessing} ms`);


    // Delete the uploaded file after processing
    try {
      await fs.promises.unlink(file.path);
      if (config.debugMode) console.log(__filename + `:   [DEBUG] Temporary file ${file.path} deleted after OCR processing.`);
    } catch (err) {
      console.error(__filename + `:   [ERROR] Failed to delete temporary file ${file.path} after OCR processing:`, err);
    }


    if (simulateError) {
      // Simulated OCR error response
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        status: ReasonPhrases.BAD_REQUEST,
        message: 'OCR failed due to invalid document or unreadable content',
        errorCode: 'OCR_INVALID_FILE',
        errors: [
          { msg: 'The uploaded document could not be read' },
          { msg: 'Please check the document and try again' }
        ],
        ocrStartProcessing,
        ocrEndProcessing,
        ocrElapsedTime: ocrEndProcessing - ocrStartProcessing
      });
    }    


    // No OCR error simulated... proceed to build a mocked successful OCR result
    const ocrResultMock = {
      documentLayout,
      documentPictureFilename: file.originalname,
      documentData: {
        field1: 'Valor de ejemplo',
        field2: 1234
      },
      ocrStartProcessing,
      ocrEndProcessing,
      ocrElapsedTime: ocrEndProcessing - ocrStartProcessing
    };

    
    // Build response
    res.status(StatusCodes.OK).json({
      success: true,
      status: ReasonPhrases.OK,
      message: 'OCR executed successfully (mock)',
      data: ocrResultMock
    });
  } catch (error) {
    console.error('Error in OCR controller:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      status: ReasonPhrases.INTERNAL_SERVER_ERROR,
      message: 'Unexpected error during OCR processing',
      errors: [{ msg: error.message }]
    });
  }
};

module.exports = { post };
