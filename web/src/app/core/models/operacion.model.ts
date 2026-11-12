import { Pagina } from './propuesta.model';

export type TipoOperacion = 'C' | 'D';

/** Un movimiento de cuenta. Calza con `OperacionDto` de la API. */
export interface Operacion {
  idMovimiento: number;
  idCuenta: number;
  numeroCuenta: string;
  tipoCuenta: string;
  moneda: string;
  idCliente: number;
  rutCliente: string;
  nombreCliente: string;
  segmento: string;
  fecha: string;
  tipo: TipoOperacion;
  concepto: string;
  monto: number;
  montoClp: number;
  referencia: string;
}

/** Totales de TODO el filtro (no de la pagina visible). Los calcula SQL. */
export interface ResumenOperaciones {
  creditos: number;
  debitos: number;
  montoCreditosClp: number;
  montoDebitosClp: number;
  netoClp: number;
}

export interface PaginaOperaciones extends Pagina<Operacion> {
  resumen: ResumenOperaciones;
}
