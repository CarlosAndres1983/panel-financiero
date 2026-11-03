import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { catchError, throwError } from 'rxjs';
import { ApiError } from './api-error';

export const errorInterceptor: HttpInterceptorFn = (req, next) =>
  next(req).pipe(
    catchError((error: unknown) => {
      if (error instanceof HttpErrorResponse) {
        return throwError(() => new ApiError(mensaje(error), error.status));
      }
      return throwError(() => error);
    }),
  );

function mensaje(error: HttpErrorResponse): string {
  const cuerpo = error.error;

  if (cuerpo && typeof cuerpo === 'object') {
    const obj = cuerpo as Record<string, unknown>;
    const texto = obj['message'] ?? obj['mensaje'] ?? obj['title'];
    if (typeof texto === 'string' && texto.trim()) {
      return texto;
    }
  }

  if (typeof cuerpo === 'string' && cuerpo.trim() && !cuerpo.startsWith('<')) {
    return cuerpo.trim();
  }

  if (error.status === 0) {
    return 'No se pudo conectar con la API. Verifica que el backend esté levantado.';
  }

  if (error.status >= 500) {
    return 'El servidor respondió con un error. Revisa la consola de la API.';
  }

  return error.message || `Error ${error.status} al consultar la API.`;
}
