import { MontoPipe } from './monto.pipe';

describe('MontoPipe', () => {
  const pipe = new MontoPipe();

  it('formatea CLP sin decimales', () => {
    expect(pipe.transform(1234567, 'CLP')).toContain('1.234.567');
  });

  it('formatea USD con dos decimales', () => {
    expect(pipe.transform(1234.5, 'USD')).toContain('1.234,50');
  });

  it('devuelve un guion cuando no hay valor', () => {
    expect(pipe.transform(null)).toBe('—');
    expect(pipe.transform(undefined)).toBe('—');
  });
});
