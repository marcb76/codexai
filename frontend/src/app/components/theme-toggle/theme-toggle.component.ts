import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ButtonModule } from 'primeng/button';
import { ThemeService } from '../../services/theme.service';

@Component({
  selector: 'app-theme-toggle',
  standalone: true,
  imports: [CommonModule, ButtonModule],
  template: `
    <button 
      type="button" 
      class="p-button p-button-text p-button-rounded"
      (click)="toggleTheme()"
      [title]="isDarkMode ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro'"
      pButton
      [icon]="isDarkMode ? 'pi pi-moon' : 'pi pi-sun'"
    >
    </button>
  `
})
export class ThemeToggleComponent {
  isDarkMode = false;

  constructor(private themeService: ThemeService) {
    this.themeService.isDarkMode$.subscribe(isDark => {
      this.isDarkMode = isDark;
    });
  }

  toggleTheme(): void {
    this.themeService.toggleTheme();
  }
}

