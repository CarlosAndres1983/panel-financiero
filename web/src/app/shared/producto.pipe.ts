import { Pipe, PipeTransform } from '@angular/core';

/** Convierte FONDOS_MUTUOS en "Fondos Mutuos" para mostrarlo en pantalla. */
@Pipe({ name: 'producto' })
export class ProductoPipe implements PipeTransform {
  transform(tipo: string | null | undefined): string {
    if (!tipo) {
      return '—';
    }

    return tipo
      .replaceAll('_', ' ')
      .toLowerCase()
      .replace(/\b\w/g, (letra) => letra.toUpperCase());
  }
}
