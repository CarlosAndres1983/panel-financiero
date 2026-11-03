import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  OnInit,
  signal,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { Dashboard } from '@core/models/dashboard.model';
import { DashboardService } from '@core/services/dashboard.service';
import { NotificacionService } from '@core/services/notificacion.service';
import { mensajeError } from '@core/utils/error.util';
import { BadgeEstadoComponent } from '@shared/badge-estado';
import { MontoPipe } from '@shared/monto.pipe';
import { ProductoPipe } from '@shared/producto.pipe';
import { DatePipe } from '@angular/common';

const COLOR_ESTADO: Record<string, string> = {
  PEND: '#f59e0b',
  APRO: '#059669',
  RECH: '#dc2626',
  ANUL: '#64748b',
  REVI: '#7c3aed',
};

@Component({
  selector: 'app-dashboard-page',
  imports: [RouterLink, BadgeEstadoComponent, MontoPipe, ProductoPipe, DatePipe],
  templateUrl: './dashboard-page.html',
  styleUrl: './dashboard-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DashboardPage implements OnInit {
  private readonly dashboardService = inject(DashboardService);
  private readonly notificaciones = inject(NotificacionService);

  protected readonly datos = signal<Dashboard | null>(null);
  protected readonly cargando = signal(true);
  protected readonly error = signal<string | null>(null);

  protected readonly hoy = new Date().toLocaleDateString('es-CL', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });

  protected readonly barras = computed(() => {
    const serie = this.datos()?.serie ?? [];
    const maximo = Math.max(1, ...serie.map((d) => d.monto));
    const compacto = new Intl.NumberFormat('es-CL', {
      notation: 'compact',
      maximumFractionDigits: 1,
    });

    return serie.map((d) => ({
      ...d,
      altura: Math.max(5, Math.round((d.monto / maximo) * 100)),
      dia: new Date(d.fecha).toLocaleDateString('es-CL', { weekday: 'short' }),
      montoCorto: compacto.format(d.monto),
    }));
  });

  protected readonly estados = computed(() => {
    const estados = this.datos()?.porEstado ?? [];
    const total = Math.max(
      1,
      estados.reduce((suma, e) => suma + e.cantidad, 0),
    );

    return estados.map((e) => ({
      ...e,
      porcentaje: Math.round((e.cantidad / total) * 100),
      color: COLOR_ESTADO[e.codigo] ?? '#64748b',
    }));
  });

  ngOnInit(): void {
    this.cargar();
  }

  protected cargar(): void {
    this.cargando.set(true);
    this.error.set(null);

    this.dashboardService.obtener().subscribe({
      next: (datos) => {
        this.datos.set(datos);
        this.cargando.set(false);
      },
      error: (err: unknown) => {
        this.error.set(mensajeError(err));
        this.cargando.set(false);
        this.notificaciones.error('No se pudo cargar el dashboard.');
      },
    });
  }
}
