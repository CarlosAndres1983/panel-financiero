import { DatePipe, DecimalPipe } from '@angular/common';
import {
  ChangeDetectionStrategy,
  Component,
  computed,
  HostListener,
  inject,
  OnInit,
  signal,
} from '@angular/core';
import { EstadoPropuesta, Pagina, Propuesta } from '@core/models/propuesta.model';
import { NotificacionService } from '@core/services/notificacion.service';
import {
  AccionPropuesta,
  FiltrosPropuesta,
  PropuestaService,
} from '@core/services/propuesta.service';
import { mensajeError } from '@core/utils/error.util';
import { haceDiasISO, hoyISO } from '@core/utils/fecha.util';
import { BadgeEstadoComponent } from '@shared/badge-estado';
import { MontoPipe } from '@shared/monto.pipe';
import { ProductoPipe } from '@shared/producto.pipe';

function filtrosIniciales(): FiltrosPropuesta {
  return {
    fechaDesde: haceDiasISO(30),
    fechaHasta: hoyISO(),
    estado: '',
    texto: '',
    pagina: 1,
    tamano: 10,
  };
}

@Component({
  selector: 'app-propuestas-page',
  imports: [BadgeEstadoComponent, MontoPipe, ProductoPipe, DatePipe, DecimalPipe],
  templateUrl: './propuestas-page.html',
  styleUrl: './propuestas-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PropuestasPage implements OnInit {
  private readonly propuestaService = inject(PropuestaService);
  private readonly notificaciones = inject(NotificacionService);

  protected readonly usuario = 'analista.demo';

  protected readonly filtros = signal<FiltrosPropuesta>(filtrosIniciales());
  protected readonly datos = signal<Pagina<Propuesta> | null>(null);
  protected readonly estados = signal<EstadoPropuesta[]>([]);
  protected readonly cargando = signal(false);
  protected readonly error = signal<string | null>(null);

  protected readonly seleccionada = signal<Propuesta | null>(null);
  protected readonly accion = signal<AccionPropuesta | null>(null);
  protected readonly comentario = signal('');
  protected readonly enviando = signal(false);

  protected readonly rango = computed(() => {
    const d = this.datos();
    if (!d || d.total === 0) {
      return 'Sin resultados';
    }

    const inicio = (d.pagina - 1) * d.tamano + 1;
    const fin = Math.min(d.pagina * d.tamano, d.total);
    return `${inicio}–${fin} de ${d.total}`;
  });

  ngOnInit(): void {
    this.cargarEstados();
    this.cargar();
  }

  @HostListener('document:keydown.escape')
  protected cerrarConEscape(): void {
    if (this.accion()) {
      this.cerrarAccion();
      return;
    }

    this.cerrarDetalle();
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

    this.propuestaService.buscar(filtros).subscribe({
      next: (pagina) => {
        // Si se resolvio la ultima propuesta de la ultima pagina, retrocede una.
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
    this.seleccionada.set(null);
    this.cargar();
  }

  protected limpiar(): void {
    this.filtros.set(filtrosIniciales());
    this.seleccionada.set(null);
    this.cargar();
  }

  protected actualizar(
    campo: 'fechaDesde' | 'fechaHasta' | 'estado' | 'texto',
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
    this.seleccionada.set(null);
    this.cargar();
  }

  protected cambiarTamano(event: Event): void {
    const tamano = Number((event.target as HTMLSelectElement).value);
    this.filtros.update((f) => ({ ...f, tamano, pagina: 1 }));
    this.cargar();
  }

  protected seleccionar(propuesta: Propuesta): void {
    this.seleccionada.set(propuesta);
  }

  protected cerrarDetalle(): void {
    this.seleccionada.set(null);
  }

  protected puedeResolver(propuesta: Propuesta): boolean {
    return propuesta.codigoEstado === 'PEND' || propuesta.codigoEstado === 'REVI';
  }

  protected abrirAccion(accion: AccionPropuesta): void {
    this.comentario.set('');
    this.accion.set(accion);
  }

  protected cerrarAccion(): void {
    this.accion.set(null);
    this.comentario.set('');
  }

  protected onComentario(event: Event): void {
    this.comentario.set((event.target as HTMLTextAreaElement).value);
  }

  protected confirmarAccion(): void {
    const accion = this.accion();
    const propuesta = this.seleccionada();

    if (!accion || !propuesta || this.enviando()) {
      return;
    }

    this.enviando.set(true);

    this.propuestaService
      .resolver(propuesta.idPropuesta, accion, this.usuario, this.comentario())
      .subscribe({
        next: (respuesta) => {
          this.enviando.set(false);
          this.cerrarAccion();
          this.seleccionada.set(null);
          this.notificaciones.exito(
            `Propuesta #${respuesta.idPropuesta} quedó ${respuesta.estado.toLowerCase()}.`,
          );
          this.cargar();
        },
        error: (err: unknown) => {
          this.enviando.set(false);
          this.cerrarAccion();
          this.notificaciones.error(mensajeError(err));
          this.cargar();
        },
      });
  }

  private cargarEstados(): void {
    this.propuestaService.estados().subscribe({
      next: (estados) => this.estados.set(estados),
      error: (err: unknown) => this.notificaciones.error(mensajeError(err)),
    });
  }
}
