export interface Propuesta {
  idPropuesta: number;
  idCuenta: number;
  numeroCuenta: string;
  idCliente: number;
  rutCliente: string;
  nombreCliente: string;
  segmento: string;
  ejecutivo: string;
  flgPep: string | null;
  tipoCuenta: string;
  moneda: string;
  saldoCuenta: number;
  estadoCuenta: string;

  idEstado: number;
  codigoEstado: string;
  estado: string;

  tipoProducto: string;
  monto: number;
  plazoDias: number;
  tasaAnual: number;
  observacion: string | null;
  asesor: string;

  fechaSolicitud: string;
  fechaResolucion: string | null;
  usuarioResolucion: string | null;
}

export interface EstadoPropuesta {
  idEstado: number;
  codigo: string;
  nombre: string;
  orden: number;
}

export interface Pagina<T> {
  items: T[];
  total: number;
  pagina: number;
  tamano: number;
  totalPaginas: number;
}
