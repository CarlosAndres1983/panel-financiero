import { HttpClient, HttpParams } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { API_URL } from '@core/api';
import { PaginaOperaciones } from '@core/models/operacion.model';

export interface FiltrosOperacion {
  fechaDesde: string;
  fechaHasta: string;
  /** '' = todos, 'C' = creditos, 'D' = debitos */
  tipo: string;
  texto: string;
  pagina: number;
  tamano: number;
}

@Injectable({ providedIn: 'root' })
export class OperacionService {
  private readonly http = inject(HttpClient);

  buscar(filtros: FiltrosOperacion): Observable<PaginaOperaciones> {
    let params = new HttpParams()
      .set('fechaDesde', filtros.fechaDesde)
      .set('fechaHasta', filtros.fechaHasta)
      .set('pagina', filtros.pagina)
      .set('tamano', filtros.tamano);

    if (filtros.tipo) {
      params = params.set('tipo', filtros.tipo);
    }

    if (filtros.texto.trim()) {
      params = params.set('texto', filtros.texto.trim());
    }

    return this.http.get<PaginaOperaciones>(`${API_URL}/operaciones`, { params });
  }
}
