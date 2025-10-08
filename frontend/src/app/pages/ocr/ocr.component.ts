// /pages/ocr/ocr.component.ts

import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';
import { FormBuilder } from '@angular/forms';
import { FormGroup } from '@angular/forms';
import { Validators } from '@angular/forms';
import { DropdownModule } from 'primeng/dropdown';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { TextareaModule } from 'primeng/textarea';

import { documentTypes as sharedDocumentTypes } from '../../../../../shared/model/ocr-request.model';
import { DocumentLayout } from '../../../../../shared/model/ocr-request.model';
import { OcrRequest } from '../../../../../shared/model/ocr-request.model';
import { OcrResponse } from '../../../../../shared/model/ocr-response.model';
import { ApiResponse } from '../../../../../shared/model/api-response.model';
import { OcrService } from '../../services/ocr.service';

@Component({
  selector: 'app-ocr',
  standalone: true,
  imports: [
    CommonModule, 
    ReactiveFormsModule, 
    DropdownModule, 
    ButtonModule, 
    InputTextModule,
    TextareaModule
  ],
  templateUrl: './ocr.component.html',
  styleUrls: ['./ocr.component.scss']
})
export class OcrComponent {
  ocrForm: FormGroup;
  documentTypes = [...sharedDocumentTypes];
  documentLayout: DocumentLayout | null = null;
  documentPicture: File | null = null;
  documentPictureFilename: string = '';
  documentRead: boolean = false;

  ocrServiceInvoked: boolean = false; 
  ocrServiceInvokedSuccess: boolean = false;
  ocrServiceInvokedError: boolean = false;
  ocrServiceInvokedAt: Date | null = null;
  ocrServiceCompletedAt: Date | null = null;
  ocrServiceResponse: ApiResponse<OcrResponse> | null = null;




  constructor(private fb: FormBuilder, private ocrService: OcrService) {
    this.ocrForm = this.fb.group({
      documentLayout: ['', Validators.required],
      documentPicture: [null, Validators.required]
    });
  }


  onDocumentPictureSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.documentPicture = input.files[0];
      this.documentPictureFilename = this.documentPicture.name;
      this.ocrForm.patchValue({ documentPicture: this.documentPicture });
    }
  }


  onRunOCR(): void {
    if (!this.documentPicture || this.ocrForm.invalid) return;
    this.documentRead = false;
    this.ocrServiceInvoked = true;
    this.ocrServiceInvokedAt = new Date();
    this.ocrServiceCompletedAt = null;
    this.ocrServiceResponse = null;
    const request: OcrRequest = {
      documentLayout: this.ocrForm.value.documentLayout,
      documentPicture: this.documentPicture
    };

    // Call the OCR service
    this.ocrService.runOcr(request).subscribe({
      next: (response: ApiResponse<OcrResponse>) => {
        // No errors in HTTP, check the response
        if (response.success && response.data) {
          // OCR successful... parse the data
          this.documentRead = true;
          this.ocrServiceInvokedSuccess = true;
          this.ocrServiceInvokedError = false;
          this.ocrServiceCompletedAt = new Date();
          this.ocrServiceResponse = response;
        } else {
          // OCR failed... show the errors
          this.documentRead = false;
          this.ocrServiceInvokedSuccess = false;
          this.ocrServiceInvokedError = true;
          this.ocrServiceCompletedAt = new Date();
          this.ocrServiceResponse = response;
        }
      },
      error: (err) => {
        // Network or unexpected HTTP error
        this.documentRead = false;
        this.ocrServiceInvokedSuccess = false;
        this.ocrServiceInvokedError = true;
        this.ocrServiceCompletedAt = new Date();
        this.ocrServiceResponse = {
          success: false,
          status: err.status || 0,
          message:
            err.status === 0
              ? 'Cannot reach the OCR service. The server might be offline or there is a network issue.'
              : err.error?.message || err.message || 'An unexpected error occurred.',
          errorCode: err.error?.errorCode,
          errors: err.error?.errors || [],
        };
      }
    });
  }
  
  
  onReset(): void {
    this.ocrForm.reset();
    this.documentPicture = null;
    this.documentPictureFilename = '';
    this.documentRead = false;
    this.ocrServiceInvoked = false;
    this.ocrServiceInvokedSuccess = false;
    this.ocrServiceInvokedError = false;
    this.ocrServiceInvokedAt = null;
    this.ocrServiceCompletedAt = null;
    this.ocrServiceResponse = null;
  }
} 