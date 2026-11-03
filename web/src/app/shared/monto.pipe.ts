import { Pipe, PipeTransform } from '@angular/core';

/** Formatea un monto segun la moneda de la cuenta (CLP sin decimales, USD con 2). */
@Pipe({ name: 'monto' })
export class MontoPipe implements PipeTransform {
  transform(valor: number | null | undefined, moneda = 'CLP'): string {
    if (valor === null || valor === undefined || Number.isNaN(valor)) {
      return '—';
    }

    return new Intl.NumberFormat('es-CL', {
      style: 'currency',
      currency: moneda,
      maximumFractionDigits: moneda === 'CLP' ? 0 : 2,
      minimumFractionDigits: moneda === 'CLP' ? 0 : 2,
    }).format(valor);
  }
}
