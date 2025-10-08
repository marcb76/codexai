// shared/model/api-response.model.ts


// Standardized API response structure
export interface ApiResponse<T> {
  success: boolean;           // ✅ true: ok, false: error
  status: number;             // ✅ HTTP code: 200, 400, 500...
  message: string;            // ✅ Human-readable message
  data?: T;                   // ✅ Actual response (if applicable)
  errorCode?: string;         // ❗️ Internal code: VALIDATION_ERROR, etc.
  errors?: ValidationError[]; // ❗️ List of detailed errors (optional)
}
export interface ValidationError {
  field: string;
  message: string;
}


// Example usage:
// const response: ApiResponse<User> = {
//   success: true,
//   status: 200,
//   message: 'User retrieved successfully',
//   data: { id: 1, name: 'John Doe', email: 'john.doe@example.com' }
// };
// const errorResponse: ApiResponse<null> = {
//   success: false,
//   status: 400,
//   message: 'Validation failed',
//   errorCode: 'VALIDATION_ERROR',
//   errors: [
//     { field: 'email', message: 'Email is required' },
//     { field: 'name', message: 'Name must be at least 2 characters long' }
//   ]
// };