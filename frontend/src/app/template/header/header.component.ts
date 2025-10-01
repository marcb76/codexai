import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MenubarModule } from 'primeng/menubar';
import { MenuItem } from 'primeng/api';
import { environment } from '../../../environments/environments';

@Component({
  selector: 'app-header',
  imports: [CommonModule, RouterModule, MenubarModule],
  templateUrl: './header.component.html',
  styleUrl: './header.component.scss'
})
export class HeaderComponent {
  appName = environment.appName;
  items: MenuItem[] = [
    { label: 'Home', icon: 'pi pi-fw pi-home', routerLink: '/' },
    { label: 'Settings', icon: 'pi pi-fw pi-cog', routerLink: '/settings' },
  ];
}
