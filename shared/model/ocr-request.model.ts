// shared/model/interfaces/ocr-request.model.ts


// List of supported document types
export const documentTypes = [
  { label: 'España - Passaporte',                                    value: 'passport.param',   disabled: false },
  { label: 'Puerto Rico - Licencia de Conducir',                     value: 'pr-license.param', disabled: false },
  { label: 'Puerto Rico - Plan Médico SSS',                          value: 'pr-sss.param',     disabled: true  },
  { label: 'Estados Unidos - Passaporte',                            value: 'passport.param',   disabled: false },
  { label: 'Estados Unidos - Documento de Autorización de Trabajo',  value: 'us-ead.param',     disabled: true  },
  { label: 'Venezuela - Cédula de Identidad',                        value: 've-cedula.param',  disabled: false },
  { label: 'Venezuela - Pasaporte',                                  value: 'passport.param',   disabled: false },
] as const;


// Document type literal generated automatically from the values
export type DocumentLayout = typeof documentTypes[number]['value'];


// Request for OCR operation
export interface OcrRequest {
  documentLayout: DocumentLayout;   // Document layout name
  documentPicture: File;            // Document image (JPG, PNG, etc.)
}
