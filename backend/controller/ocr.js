// controller/ocr.js

// Import modules
const { StatusCodes, ReasonPhrases } = require('http-status-codes');




// Implement POST for /api/ocr
/**
 * Mock OCR processing controller
 * Assumes req.file is valid and req.body.documentLayout is validated
 */
const post = async (req, res) => {
  try {
    // Get input data (already validated)
    const documentLayout = req.body.documentLayout;
    const file = req.file;


    // Simulate OCR processing
    const ocrStartProcessing = new Date();


    // For demonstration purposes, we will mock the OCR result
    // When OCR is implemented, replace this section with actual OCR logic
    // Here the actual OCR processing logic would be implemented
    //// In the meantime, simulate a delay for OCR processing (e.g., 250 ms)
    await new Promise(resolve => setTimeout(resolve, 250));
    //// Randomly decide if OCR should fail (for testing frontend error handling)
    const simulateError = Math.random() < 0.5; // 50% chance
    const ocrEndProcessing = new Date();


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
