// src/environments/environment.ts

export const environment = {
  // Production flag - never true in this file
  production: false,

  // Application information
  appName: 'codexAI',
  appMoto: 'AI-Powered document scanning solution',
  appVersion: 'v0.0.2 (Experimental)',

  // Backend configuration
  backendServer: 'codexai.eniac-corp.com',
  backendPort: 8443,
  backendUseHttps: true,
  backendAPITimeout: 15000, // in milliseconds
  get backendAPIUrl(): string {
    return (this.backendUseHttps ? 'https' : 'http') + '://' + this.backendServer + ':' + this.backendPort + '/api';
  }
};
