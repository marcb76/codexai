// shared/model/interfaces/ocr-response.model.ts

import { DocumentLayout } from './ocr-request.model';

/** Response of the OCR operation */
export interface OcrResponse {
  documentLayout: DocumentLayout;     // Layout defined for the uploaded document
  documentPictureFilename: string;    // Name of the uploaded file
  documentData: any;                  // JSON with extracted data
  ocrStartProcessing: string;         // ISO date string
  ocrEndProcessing: string;           // ISO date string
  ocrElapsedTime: number;             // Milliseconds
}
// Example usage:
// const response: OcrResponse = {
//   documentLayout: 'passport.param',
//   documentPictureFilename: 'passport.jpg',
//   documentData: { /* extracted data */ },
//   ocrStartProcessing: new Date().toISOString(),
//   ocrEndProcessing: new Date().toISOString(),
//   ocrElapsedTime: 1234
// };