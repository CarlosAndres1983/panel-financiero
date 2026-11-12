import { DatePipe } from '@angular/common';
import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  OnInit,
  signal,
} from '@angular/core';
import { PaginaOperaciones } from '@core/models/operacion.model';
import { FiltrosOperacion, OperacionService } from '@core/services/operacion.service';
import { mensajeError } from '@core/utils/error.util';
import { haceDiasISO, hoyISO } from '@core/utils/fecha.util';
import { MontoPipe } from '@shared/monto.pipe';

function filtrosIniciales(): FiltrosOperacion {
  return {
    fechaDesde: haceDiasISO(30),
    fechaHasta: hoyISO(),
    tipo: '',
    texto: '',
    pagina: 1,
    tamano: 10,
  };
}

@Component({
  selector: 'app-operaciones-page',
  imports: [DatePipe, MontoPipe],
  templateUrl: './operaciones-page.html',
  styleUrl: './operaciones-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OperacionesPage implements OnInit {
  private readonly operacionService = inject(OperacionService);

  protected readonly filtros = signal<FiltrosOperacion>(filtrosIniciales());
  protected readonly datos = signal<PaginaOperaciones | null>(null);
  protected readonly cargando = signal(false);
  protected readonly error = signal<string | null>(null);

  protected readonly rango = computed(() => {
    const d = this.datos();
    if (!d || d.total === 0) {
      return 'Sin resultados';
    }

    const inicio = (d.pagina - 1) * d.tamano + 1;
    const fin = Math.min(d.pagina * d.tamano, d.total);
    return `${inicio}–${fin} de ${d.total}`;
  });

  protected readonly netoNegativo = computed(() => (this.datos()?.resumen.netoClp ?? 0) < 0);

  ngOnInit(): void {
    this.cargar();
  }

  protected cargar(): void {
    if (this.cargando()) {
      return;
    }

    const filtros = this.filtros();
    if (!filtros.fechaDesde || !filtros.fechaHasta) {
      this.error.set('Debes indicar la fecha desde y la fecha hasta.');
      return;
    }

    if (filtros.fechaDesde > filtros.fechaHasta) {
      this.error.set('La fecha desde no puede ser mayor que la fecha hasta.');
      return;
    }

    this.cargando.set(true);
    this.error.set(null);

    this.operacionService.buscar(filtros).subscribe({
      next: (pagina) => {
        // Si el filtro arrojo menos filas que antes y quedamos en una pagina
        // que ya no existe, retrocede una pagina y vuelve a consultar.
        if (pagina.items.length === 0 && pagina.total > 0 && pagina.pagina > 1) {
          this.filtros.update((f) => ({ ...f, pagina: pagina.pagina - 1 }));
          this.cargando.set(false);
          this.cargar();
          return;
        }

        this.datos.set(pagina);
        this.cargando.set(false);
      },
      error: (err: unknown) => {
        this.error.set(mensajeError(err));
        this.cargando.set(false);
      },
    });
  }

  protected aplicar(): void {
    this.filtros.update((f) => ({ ...f, pagina: 1 }));
    this.cargar();
  }

  protected limpiar(): void {
    this.filtros.set(filtrosIniciales());
    this.cargar();
  }

  protected actualizar(
    campo: 'fechaDesde' | 'fechaHasta' | 'tipo' | 'texto',
    event: Event,
  ): void {
    const valor = (event.target as HTMLInputElement | HTMLSelectElement).value;
    this.filtros.update((f) => ({ ...f, [campo]: valor }));
  }

  protected cambiarPagina(pagina: number): void {
    const d = this.datos();
    if (!d || pagina < 1 || pagina > d.totalPaginas || pagina === d.pagina) {
      return;
    }

    this.filtros.update((f) => ({ ...f, pagina }));
    this.cargar();
  }

  protected cambiarTamano(event: Event): void {
    const tamano = Number((event.target as HTMLSelectElement).value);
    this.filtros.update((f) => ({ ...f, tamano, pagina: 1 }));
    this.cargar();
  }

  protected etiquetaTipo(tipo: string): string {
    return tipo === 'C' ? 'Crédito' : 'Débito';
  }

  protected claseTipo(tipo: string): string {
    return tipo === 'C' ? 'badge-credito' : 'badge-debito';
  }
}
