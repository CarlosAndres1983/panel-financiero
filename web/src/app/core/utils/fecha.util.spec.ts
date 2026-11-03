import { fechaISO, haceDiasISO, hoyISO } from './fecha.util';

describe('fecha.util', () => {
  it('convierte una fecha local a yyyy-MM-dd', () => {
    expect(fechaISO(new Date(2026, 10, 3))).toBe('2026-11-03');
  });

  it('hoyISO devuelve el formato del input date', () => {
    expect(hoyISO()).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });

  it('haceDiasISO resta dias', () => {
    const hoy = new Date();
    const esperado = new Date();
    esperado.setDate(hoy.getDate() - 7);
    expect(haceDiasISO(7)).toBe(fechaISO(esperado));
  });
});
