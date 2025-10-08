// services/api.service.ts

import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';
import { ApiResponse } from '../../../../shared/model/api-response.model';


@Injectable({
  providedIn: 'root'
})
export class ApiService {
  protected readonly baseUrl = environment.backendAPIUrl;
  constructor(protected http: HttpClient) {}


  /**
   * Generic GET
   * @param endpoint Relative endpoint path
   * @param params Optional query params
   */
  get<T>(endpoint: string, params?: HttpParams): Observable<ApiResponse<T>> {
    return this.http.get<ApiResponse<T>>(`${this.baseUrl}/${endpoint}`, { params });
  }

  /**
   * Generic POST
   * @param endpoint Relative endpoint path
   * @param body Body of the request (can be FormData or JSON)
   */
  post<T>(endpoint: string, body: any | FormData): Observable<ApiResponse<T>> {
    return this.http.post<ApiResponse<T>>(`${this.baseUrl}/${endpoint}`, body);
  }

  /**
   * Generic PUT
   * @param endpoint Relative endpoint path
   * @param body Body of the request (can be FormData or JSON)
   */
  put<T>(endpoint: string, body: any | FormData): Observable<ApiResponse<T>> {
    return this.http.put<ApiResponse<T>>(`${this.baseUrl}/${endpoint}`, body);
  }

  /**
   * Generic DELETE
   * @param endpoint Relative endpoint path
   */
  delete<T>(endpoint: string): Observable<ApiResponse<T>> {
    return this.http.delete<ApiResponse<T>>(`${this.baseUrl}/${endpoint}`);
  }
}
