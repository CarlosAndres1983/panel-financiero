import { Routes } from '@angular/router';
import { ShellComponent } from '@layout/shell/shell';

export const routes: Routes = [
  {
    path: '',
    component: ShellComponent,
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
      {
        path: 'dashboard',
        title: 'Dashboard · Panel Financiero',
        loadComponent: () =>
          import('@features/dashboard/dashboard-page').then((m) => m.DashboardPage),
      },
      {
        path: 'propuestas',
        title: 'Propuestas · Panel Financiero',
        loadComponent: () =>
          import('@features/propuestas/propuestas-page').then((m) => m.PropuestasPage),
      },
      {
        path: 'operaciones',
        title: 'Operaciones · Panel Financiero',
        loadComponent: () =>
          import('@features/operaciones/operaciones-page').then((m) => m.OperacionesPage),
      },
      { path: '**', redirectTo: 'dashboard' },
    ],
  },
];
