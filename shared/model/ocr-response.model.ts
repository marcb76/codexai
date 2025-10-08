// shared/model/interfaces/ocr-response.model.ts

import { DocumentLayout } from './ocr-request.model';

/** Response of the OCR operation */
export interface OcrResponse {
  documentLayout: DocumentLayout;     // Layout usado en el OCR
  documentData: any;                  // JSON con los datos extraídos
  ocrStartProcessing: string;         // ISO date string
  ocrEndProcessing: string;           // ISO date string
  ocrElapsedTime: number;             // Milisegundos
}
// Example usage:
// const response: OcrResponse = {
//   documentLayout: 'us-passport.param',
//   documentData: { /* extracted data */ },
//   ocrStartProcessing: new Date().toISOString(),
//   ocrEndProcessing: new Date().toISOString(),
//   ocrElapsedTime: 1234
// };