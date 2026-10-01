// services/ocr.service.ts

import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { ApiResponse } from '../../../../shared/model/api-response.model';
import { OcrRequest } from '../../../../shared/model/ocr-request.model';
import { OcrResponse } from '../../../../shared/model/ocr-response.model';
import { ApiService } from './api.service';

@Injectable({
  providedIn: 'root'
})
export class OcrService extends ApiService {
  constructor(http: HttpClient) {
    super(http);
  }

  /**
   * Call the OCR in the backend
   * Returns an ApiResponse<OcrResponse>
   */
  runOcr(formData: FormData) {
    return this.post<OcrResponse>('ocr', formData);
  }
}
