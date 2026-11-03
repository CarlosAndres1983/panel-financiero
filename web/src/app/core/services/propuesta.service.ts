import { HttpClient, HttpParams } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { API_URL } from '@core/api';
import { EstadoPropuesta, Pagina, Propuesta } from '@core/models/propuesta.model';

export interface FiltrosPropuesta {
  fechaDesde: string;
  fechaHasta: string;
  estado: string;
  texto: string;
  pagina: number;
  tamano: number;
}

export type AccionPropuesta = 'APROBAR' | 'RECHAZAR';

export interface RespuestaResolucion {
  idPropuesta: number;
  codigoEstado: string;
  estado: string;
  usuario: string;
  comentario: string | null;
}

@Injectable({ providedIn: 'root' })
export class PropuestaService {
  private readonly http = inject(HttpClient);

  buscar(filtros: FiltrosPropuesta): Observable<Pagina<Propuesta>> {
    let params = new HttpParams()
      .set('fechaDesde', filtros.fechaDesde)
      .set('fechaHasta', filtros.fechaHasta)
      .set('pagina', filtros.pagina)
      .set('tamano', filtros.tamano);

    if (filtros.estado) {
      params = params.set('estado', filtros.estado);
    }

    if (filtros.texto.trim()) {
      params = params.set('texto', filtros.texto.trim());
    }

    return this.http.get<Pagina<Propuesta>>(`${API_URL}/propuestas`, { params });
  }

  estados(): Observable<EstadoPropuesta[]> {
    return this.http.get<EstadoPropuesta[]>(`${API_URL}/propuestas/estados`);
  }

  resolver(
    idPropuesta: number,
    accion: AccionPropuesta,
    usuario: string,
    comentario: string,
  ): Observable<RespuestaResolucion> {
    return this.http.post<RespuestaResolucion>(`${API_URL}/propuestas/${idPropuesta}/resolver`, {
      accion,
      usuario,
      comentario,
    });
  }
}
