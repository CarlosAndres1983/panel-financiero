import { Injectable, signal } from '@angular/core';

export type TipoNotificacion = 'exito' | 'error' | 'info';

export interface Notificacion {
  id: number;
  tipo: TipoNotificacion;
  texto: string;
}

/** Cola simple de avisos. El layout se encarga de dibujarlos. */
@Injectable({ providedIn: 'root' })
export class NotificacionService {
  private readonly _items = signal<Notificacion[]>([]);
  private contador = 0;

  readonly items = this._items.asReadonly();

  exito(texto: string): void {
    this.agregar('exito', texto);
  }

  error(texto: string): void {
    this.agregar('error', texto);
  }

  info(texto: string): void {
    this.agregar('info', texto);
  }

  cerrar(id: number): void {
    this._items.update((items) => items.filter((n) => n.id !== id));
  }

  private agregar(tipo: TipoNotificacion, texto: string): void {
    const id = ++this.contador;
    this._items.update((items) => [...items, { id, tipo, texto }]);
    setTimeout(() => this.cerrar(id), 4500);
  }
}
