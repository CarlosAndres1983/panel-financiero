import { Propuesta } from './propuesta.model';

export interface SerieDia {
  fecha: string;
  cantidad: number;
  monto: number;
}

export interface EstadoResumen {
  codigo: string;
  estado: string;
  cantidad: number;
  monto: number;
}

export interface Dashboard {
  saldoTotal: number;
  cuentasActivas: number;
  propuestasPendientes: number;
  montoPendiente: number;
  movimientosHoy: number;
  montoMovimientosHoy: number;
  serie: SerieDia[];
  porEstado: EstadoResumen[];
  ultimas: Propuesta[];
}
