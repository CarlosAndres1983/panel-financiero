/** Fecha local en formato `yyyy-MM-dd` (lo que espera un input type=date). */
export function fechaISO(fecha: Date): string {
  const anio = fecha.getFullYear();
  const mes = String(fecha.getMonth() + 1).padStart(2, '0');
  const dia = String(fecha.getDate()).padStart(2, '0');
  return `${anio}-${mes}-${dia}`;
}

export function hoyISO(): string {
  return fechaISO(new Date());
}

export function haceDiasISO(dias: number): string {
  const fecha = new Date();
  fecha.setDate(fecha.getDate() - dias);
  return fechaISO(fecha);
}
