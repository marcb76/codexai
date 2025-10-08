// shared/model/interfaces/ocr-request.model.ts


// List of supported document types
export const documentTypes = [
  { label: 'Puerto Rico - Licencia de Conducir',  value: 'pr-licencia.param'  },
  { label: 'USA - Passaporte',                    value: 'us-passport.param'  },
  { label: 'Venezuela - Cédula de Identidad',     value: 've-cedula.param'    },
  { label: 'Venezuela - Pasaporte',               value: 've-pasaporte.param' },
] as const;


// Document type literal generated automatically from the values
export type DocumentLayout = typeof documentTypes[number]['value'];


// Request for OCR operation
export interface OcrRequest {
  documentLayout: DocumentLayout;   // Document layout name
  documentPicture: File;            // Document image (JPG, PNG, etc.)
}
