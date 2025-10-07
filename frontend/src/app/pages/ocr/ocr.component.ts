import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { HttpClientModule } from '@angular/common/http';
import { ReactiveFormsModule } from '@angular/forms';
import { FormBuilder } from '@angular/forms';
import { FormGroup } from '@angular/forms';
import { Validators } from '@angular/forms';
import { DropdownModule } from 'primeng/dropdown';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';

@Component({
  selector: 'app-ocr',
  standalone: true,
  imports: [
    CommonModule, 
    HttpClientModule,
    ReactiveFormsModule, DropdownModule, ButtonModule, InputTextModule],
  templateUrl: './ocr.component.html',
  styleUrls: ['./ocr.component.scss']
})
export class OcrComponent {
  ocrForm: FormGroup;
  documentTypes = [
    { label: 'pr-licencia',  value: 'pr-licencia.param' },
    { label: 'us-passport',  value: 'us-passport.param' },
    { label: 've-cedula',    value: 've-cedula.param' },
    { label: 've-pasaporte', value: 've-pasaporte.param' },
  ];
  documentPicture: File | null = null;
  documentPictureFilename: string = '';
  documentRead: boolean = false;
  ocrResult: { message: string; detail: string } | null = null;



  constructor(private fb: FormBuilder, private http: HttpClient) {
    this.ocrForm = this.fb.group({
      documentType: ['', Validators.required],
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
    const formData = new FormData();
    formData.append('file', this.documentPicture);
    formData.append('documentType', this.ocrForm.value.documentType);
    this.http.post<any>('/api/ocr', formData).subscribe({
      next: (response) => {
        this.ocrResult = {
          message: response.message || 'OCR completed successfully.',
          detail: response.detail || JSON.stringify(response, null, 2)
        };
      },
      error: (err) => {
        this.ocrResult = {
          message: 'OCR failed.',
          detail: err.message || 'An error occurred during OCR.'
        };
      }
    });
    this.documentRead = true;
  }

  
  onReset(): void {
    this.ocrForm.reset();
    this.documentPicture = null;
    this.documentPictureFilename = '';
    this.documentRead = false;
    this.ocrResult = null;
  }
}