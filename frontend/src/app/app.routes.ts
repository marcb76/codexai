import { Routes } from '@angular/router';
import { OcrComponent } from './pages/ocr/ocr.component';
import { SettingsComponent } from './pages/settings/settings.component';

export const routes: Routes = [
  { path: '', redirectTo: 'ocr', pathMatch: 'full' },
  { path: 'ocr', component: OcrComponent },
  { path: 'settings', component: SettingsComponent }
];
