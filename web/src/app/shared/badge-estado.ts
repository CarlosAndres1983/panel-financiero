import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

const CLASE: Record<string, string> = {
  PEND: 'pendiente',
  APRO: 'aprobado',
  RECH: 'rechazado',
  ANUL: 'anulado',
  REVI: 'revision',
};

@Component({
  selector: 'app-badge-estado',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<span [class]="'badge badge-' + clase()">{{ nombre() }}</span>`,
})
export class BadgeEstadoComponent {
  readonly codigo = input.required<string>();
  readonly nombre = input.required<string>();

  protected readonly clase = computed(() => CLASE[this.codigo()] ?? 'otro');
}
