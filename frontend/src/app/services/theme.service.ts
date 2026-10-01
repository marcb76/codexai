import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ThemeService {
  private isDarkMode = new BehaviorSubject<boolean>(false);
  public isDarkMode$ = this.isDarkMode.asObservable();

  constructor() {
    // Set the saved theme preference from localStorage if available
    const savedTheme = localStorage.getItem('darkMode');
    if (savedTheme !== null) {
      this.isDarkMode.next(JSON.parse(savedTheme));
    }
    this.applyTheme();
  }

  toggleTheme(): void {
    this.isDarkMode.next(!this.isDarkMode.value);
    this.applyTheme();
    localStorage.setItem('darkMode', JSON.stringify(this.isDarkMode.value));
  }

  applyTheme(): void {
    const isDark = this.isDarkMode.value;

    // Apply dark class for Tailwind CSS
    if (isDark) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }

  getCurrentTheme(): boolean {
    return this.isDarkMode.value;
  }
}
