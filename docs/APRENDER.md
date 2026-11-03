# Aprender desde cero (viniendo de VB6 / VB.NET)

Esta guía no intenta enseñarte todo el stack. Intenta que puedas **leer, romper y arreglar** este proyecto, que es la forma más rápida de aprender cuando ya tienes experiencia en escritorio y SQL.

La idea central:

> Un formulario de VB con controles, eventos y un Recordset se transformó en un componente de Angular con plantilla, eventos y un servicio HTTP. La base de datos sigue siendo SQL Server.

## 1. Cómo usar esta guía

1. Levanta la base, la API y la web (ver `README.md`).
2. Abre la aplicación y recórrela.
3. Lee la tabla de equivalencias de abajo.
4. Haz los ejercicios en orden. Cada uno te pide romper algo, observar el síntoma y arreglarlo.
5. Cuando algo falle, sigue la sección "Recetas de depuración".

No empieces leyendo todos los archivos. Empieza por el flujo de una petición y ve bajando.

## 2. Equivalencias VB6/VB.NET → web

| VB6 / VB.NET | En este proyecto | Archivo de ejemplo |
| --- | --- | --- |
| `frmMonitor.frm` | Componente Angular (`.ts` + `.html` + `.css`) | `web/src/app/features/propuestas/propuestas-page.ts` |
| `TextBox`, `ComboBox`, `DataGrid` | `<input>`, `<select>`, `<table>` | `propuestas-page.html` |
| `CommandButton_Click` | `(click)="metodo()"` | Botón "Consultar" |
| `Form_Load` | `ngOnInit()` | `PropuestasPage.ngOnInit` |
| `Recordset` / `DataSet` | Interfaz TypeScript + signal | `Propuesta`, `signal<Pagina<Propuesta>>` |
| `ADODB.Connection` / `Command` | Dapper + `SqlConnection` | `DbConnectionFactory`, `PropuestasEndpoints` |
| Stored procedure | Endpoint + SQL inline | `BuscarAsync` |
| Módulo `.bas` | Servicio o utilidad | `propuesta.service.ts`, `fecha.util.ts` |
| `App.config` / `.ini` | `appsettings.json` | `api/Panel.Api/appsettings.json` |
| `MsgBox` | Toast | `NotificacionService` |
| `On Error GoTo` | `try/catch`, `ProblemDetails`, interceptor | `error.interceptor.ts` |
| `Refresh` del formulario | `signal.set(...)` y recarga | `cargar()` |
| Timer | `Observable`, `setTimeout` | `NotificacionService` |
| `Variant` / `Null` | `string \| null`, `?` | `observacion: string \| null` |
| DataSet tipado | DTO + interfaz TypeScript | `PropuestaDto`, `Propuesta` |

Diferencias importantes:

- **No hay estado compartido global como un módulo con variables.** Cada componente tiene su estado; los servicios se inyectan.
- **La UI es declarativa.** No escribes `Grid.Rows.Add`; cambias el arreglo/signal y Angular vuelve a dibujar.
- **La comunicación es asíncrona.** Una llamada HTTP no bloquea; se suscribe y reacciona cuando llega la respuesta.
- **El navegador y el servidor son procesos separados.** El "formulario" corre en el navegador; la API corre en .NET; SQL Server en otro proceso.

## 3. El viaje de una petición

Cuando presionas "Consultar":

1. `propuestas-page.ts` llama a `PropuestaService.buscar(filtros)`.
2. `HttpClient` hace `GET /api/propuestas?...` al puerto 4200.
3. El proxy de Angular (`web/proxy.conf.json`) reenvía a `http://localhost:5080`.
4. `PropuestasEndpoints.BuscarAsync` valida fechas y arma parámetros.
5. Dapper ejecuta dos consultas en un solo viaje: `COUNT(*)` y la página con `OFFSET/FETCH`.
6. SQL Server usa la vista `vwPropuestaDetalle` y el índice `IX_Propuesta_FechaEstado`.
7. La API devuelve `{ items, total, pagina, tamano, totalPaginas }`.
8. El componente guarda la respuesta en `datos` (un signal).
9. Angular re-renderiza la tabla, la paginación y los contadores.

Si algo no aparece, el problema está en uno de esos 9 pasos. La pestaña **Network** del navegador te dice si el problema es antes o después del paso 7.

## 4. Mapa de archivos

### Backend

| Archivo | Qué hace |
| --- | --- |
| `Program.cs` | Arranque, Swagger, CORS, health |
| `Data/DbConnectionFactory.cs` | Lee la cadena de conexión y crea `SqlConnection` |
| `Comun/Fechas.cs` | Acepta `yyyy-MM-dd` y `dd-MM-yyyy` |
| `Features/Propuestas/PropuestaDto.cs` | Contratos JSON (DTOs) |
| `Features/Propuestas/PropuestasEndpoints.cs` | Búsqueda paginada, estados y resolver |
| `Features/Dashboard/DashboardEndpoints.cs` | KPIs con `QueryMultiple` |

### Frontend

| Archivo | Qué hace |
| --- | --- |
| `core/services/propuesta.service.ts` | Llama a la API y tipa la respuesta |
| `core/http/error.interceptor.ts` | Convierte errores HTTP en mensajes |
| `core/utils/fecha.util.ts` | Fechas locales `yyyy-MM-dd` |
| `layout/shell/*` | Sidebar, contenido y toasts |
| `features/dashboard/*` | KPIs y gráficos |
| `features/propuestas/*` | Filtros, tabla, detalle y acciones |
| `shared/*` | Pipes de monto/producto y badge de estado |

### SQL

| Archivo | Qué hace |
| --- | --- |
| `001_esquema.sql` | Tablas, índices y vista |
| `002_datos_prueba.sql` | Datos deterministas |
| `003_consultas_ejemplo.sql` | Consultas de analista y ejercicios |

## 5. Dónde poner breakpoints

### API .NET

1. Abre la carpeta raíz en VS Code.
2. Instala la extensión **C# Dev Kit** (o al menos C#).
3. Abre `api/Panel.Api/Features/Propuestas/PropuestasEndpoints.cs`.
4. Pon un breakpoint en la primera línea de `BuscarAsync`.
5. Presiona F5 y elige **API Panel (.NET)**.
6. En la web, presiona "Consultar".
7. Inspecciona `fechaDesde`, `fechaHasta`, `texto`, `pagina`, `tamano`.
8. Pasa el mouse sobre `sql` y `parametros` para ver la consulta y los valores.

También puedes ejecutar la API con `dotnet run` y usar Swagger; es más rápido para probar SQL, pero no permite inspeccionar variables.

### Frontend Angular

1. Abre Chrome DevTools (F12).
2. **Network** → filtro `propuestas` → mira la URL, el status y la respuesta JSON.
3. **Console** → errores de TypeScript o del interceptor.
4. **Sources** → `webpack://` o `src/app/...` → pon breakpoint en `cargar()` o en `confirmarAccion()`.
5. También puedes escribir `debugger;` en el TypeScript y recargar.

Para ver el estado de un signal sin breakpoint, agrega temporalmente:

```ts
console.log('datos', this.datos());
console.log('filtros', this.filtros());
```

### SQL Server

- SSMS o Azure Data Studio.
- Consulta directa:

```sql
USE PanelFinanciero;
SELECT TOP (20) * FROM dbo.vwPropuestaDetalle ORDER BY fechaSolicitud DESC;
```

- Para ver qué consulta ejecuta Dapper, pon un breakpoint y copia `sql` + `parametros`, o activa logging de EF no aplica: aquí no hay EF.
- Puedes usar **SQL Server Profiler** o **Extended Events** para capturar el SQL real. En Express, Extended Events es la opción recomendada.

## 6. Ejercicios para romper y arreglar

Hazlos en una rama nueva (`git switch -c practica/...`) para no mezclar.

### Ejercicio 1: cambiar el rango de fechas por defecto

**Objetivo:** entender dónde vive el estado inicial del filtro.

1. En `propuestas-page.ts`, cambia `haceDiasISO(30)` por `haceDiasISO(7)`.
2. Guarda y observa que la bandeja muestra menos resultados.
3. En `PropuestasEndpoints.BuscarAsync`, cambia el default `hasta.AddDays(-30)` por `-7`.
4. Prueba sin fechas desde Swagger.

**Pregunta:** ¿por qué el frontend y la API tienen defaults? ¿Qué pasa si solo cambias uno?

### Ejercicio 2: romper un alias SQL

**Objetivo:** ver cómo Dapper mapea por nombre.

1. En `001_esquema.sql`, cambia `p.monto` por `p.monto AS montoX` en la vista.
2. Ejecuta `sqlcmd ... -i sql\001_esquema.sql`.
3. Recarga la bandeja: la columna Monto aparece vacía o en 0.
4. Revisa la respuesta JSON en Network: la propiedad `monto` ya no existe.
5. Arregla el alias o cambia el DTO; explica por qué falló.

### Ejercicio 3: simular un error 500

**Objetivo:** entender el interceptor y el manejo de errores.

1. En `BuscarAsync`, agrega `throw new Exception("falla de prueba");` antes de la consulta.
2. Presiona "Consultar".
3. Observa el toast, el banner y la consola de la API.
4. Revisa el JSON de error (`title`, `status`, `traceId`).
5. Quita la excepción y verifica que todo vuelve a la normalidad.

**Variante:** apaga la API y presiona "Consultar". El error debe decir que no se pudo conectar (status 0).

### Ejercicio 4: dos analistas aprueban a la vez

**Objetivo:** entender transacciones y bloqueo.

1. Abre Swagger en dos pestañas.
2. Busca una propuesta pendiente con `GET /api/propuestas?estado=PEND`.
3. En ambas pestañas prepara el mismo `POST /api/propuestas/{id}/resolver`.
4. Ejecuta una y luego la otra (o casi al mismo tiempo).
5. La segunda debe responder `409`.
6. Revisa `AuditoriaPropuesta`: debe haber **una sola** fila.

**Pregunta:** ¿qué hace `WITH (UPDLOCK, ROWLOCK)`? ¿Qué pasaría sin transacción?

### Ejercicio 5: exigir motivo al rechazar

**Objetivo:** agregar una regla de negocio de punta a punta.

1. En el modal, deshabilita "Confirmar rechazo" si el comentario está vacío.
2. En `ResolverAsync`, si `accion == "RECHAZAR"` y no hay comentario, responde `400` con un mensaje.
3. Prueba desde Swagger y desde la UI.
4. Revisa que el mensaje del `400` llegue al toast.

**Pregunta:** ¿por qué validar en el servidor si ya validaste en el navegador?

### Ejercicio 6: agregar un filtro por segmento

**Objetivo:** recorrer todas las capas.

1. La vista ya tiene `segmento`.
2. Agrega el parámetro `segmento` a `BuscarAsync`.
3. Agrega la condición `(@segmento IS NULL OR v.segmento = @segmento)`.
4. Agrega el campo en `FiltrosPropuesta` y en el HTML.
5. Prueba con `EMPRESA`, `PYME`, `PERSONA`.

**Pregunta:** ¿en qué capa es más barato filtrar? ¿Qué pasa si el filtro se hace solo en Angular?

### Ejercicio 7: medir el efecto de un índice

**Objetivo:** leer estadísticas de IO.

1. En SSMS ejecuta:

```sql
SET STATISTICS IO ON;
SELECT idPropuesta, monto
FROM dbo.Propuesta
WHERE fechaSolicitud >= DATEADD(DAY, -7, GETDATE())
  AND idEstado = 1;
SET STATISTICS IO OFF;
```

2. Revisa "logical reads".
3. Mira el índice `IX_Propuesta_FechaEstado` (incluye `idCuenta` y `monto`).
4. Prueba cambiar el orden de las columnas del filtro o quitar el índice en una copia de la base.
5. Explica por qué el índice ayuda (o no) en este caso.

### Ejercicio 8: agregar un endpoint de movimientos

**Objetivo:** crear una funcionalidad completa.

1. Crea `Features/Movimientos/MovimientosEndpoints.cs`.
2. Implementa `GET /api/cuentas/{id}/movimientos?desde=...&hasta=...`.
3. Devuelve `idMovimiento`, `fecha`, `tipo`, `concepto`, `monto`, `referencia`.
4. Agrega un método en un servicio Angular.
5. Muestra los movimientos en el drawer de detalle de la propuesta.
6. Agrega un estado de carga y un mensaje de "sin movimientos".

**Pregunta:** ¿cómo evitar consultar movimientos si el usuario nunca abre el detalle?

### Ejercicio 9: reemplazar el tipo de cambio fijo

**Objetivo:** modelar datos que cambian en el tiempo.

1. Crea `TipoCambio(fecha, monedaOrigen, monedaDestino, valor)`.
2. Carga algunos valores para USD → CLP.
3. Cambia `montoClp` de la vista por una función o join que use el tipo de cambio del día de la propuesta.
4. Prueba con datos USD y CLP.

**Pregunta:** ¿qué pasa si no hay tipo de cambio para un día? ¿Qué debería hacer el sistema?

### Ejercicio 10: prueba unitaria de una regla

**Objetivo:** escribir una prueba que no dependa del navegador.

1. Crea una función `puedeResolver(codigoEstado: string): boolean`.
2. Úsala en el componente y en un pipe/servicio.
3. Escribe una prueba en Vitest: pendiente y en revisión → true; aprobada → false.
4. Ejecuta `npm test -- --watch=false`.

## 7. Recetas de depuración

### "La tabla está vacía pero la API responde 200"

Revisa en Network el JSON:

- ¿`items` viene vacío? Entonces el filtro SQL no encontró filas. Prueba la misma consulta en SSMS.
- ¿`items` tiene datos pero la tabla no los muestra? Revisa los nombres de propiedades (`nombreCliente`, `monto`, etc.) y los `@for`.
- ¿La fecha está en otro formato? La API espera `yyyy-MM-dd`; el input date entrega ese formato.

### "Error 400 al consultar"

- `La fecha desde no es valida`: formato incorrecto.
- `La fecha desde no puede ser mayor`: invierte el rango.
- `tamano` fuera de rango: la API lo limita entre 1 y 100.

### "Error 409 al aprobar"

La propuesta ya no está pendiente. Recarga la bandeja y revisa `AuditoriaPropuesta`. Es el comportamiento correcto.

### "Error 500"

1. Mira la ventana de la API: allí está el stack trace.
2. Si es SQL, revisa el nombre de la columna/tabla y los parámetros.
3. Si es JSON, revisa el DTO y el alias.
4. Si el error es de conexión, revisa la cadena en `appsettings.json`.

### "El cambio en TypeScript no se refleja"

- ¿Guardaste el archivo? `ng serve` recompila al guardar.
- ¿El componente usa `OnPush`? Cambia el estado con `signal.set/update`, no mutando el arreglo.
- ¿El valor está fuera del signal? Angular no detecta cambios en variables normales si el componente es `OnPush` y el evento no ocurrió dentro del componente.

### "No puedo llamar a la API desde el navegador"

- Usa `http://localhost:4200`, no `127.0.0.1`, para que el proxy y CORS coincidan.
- Si llamas directo a `:5080`, CORS solo permite `http://localhost:4200`.
- En producción, sirve la web y la API bajo el mismo dominio o configura CORS explícitamente.

## 8. Conceptos de Angular usados (versión corta)

- **Componente:** clase + plantilla + estilos. `standalone` significa que declara sus imports sin `NgModule`.
- **Signal:** caja reactiva (`signal(0)`), se lee con `()` y se cambia con `.set()` o `.update()`.
- **Computed:** valor derivado que se recalcula cuando cambian sus signals.
- **Input:** parámetro de un componente hijo (`input.required<string>()`).
- **Servicio:** clase con lógica compartida, se inyecta con `inject()`.
- **Observable:** flujo asíncrono de RxJS; `HttpClient` devuelve uno y se consume con `.subscribe()`.
- **Pipe:** transformación de presentación (`monto`, `producto`, `date`).
- **Router:** carga componentes por URL; aquí usa `loadComponent` (lazy loading).
- **Interceptor:** función que ve todas las peticiones/respuestas HTTP.
- **Zoneless / OnPush:** Angular no revisa todo el árbol; los signals avisan cuándo cambió algo.

## 9. Conceptos de C# usados

- **Minimal API:** `app.MapGet(...)` registra un endpoint sin controladores.
- **DI:** `builder.Services.AddSingleton<IDbConnectionFactory, SqlConnectionFactory>()`; el endpoint lo recibe por parámetro.
- **async/await:** no bloquea el hilo mientras SQL responde.
- **DTO:** clase plana que define el JSON de salida/entrada.
- **Dapper:** ejecuta SQL y mapea filas a objetos por nombre de columna.
- **`QueryMultiple`:** varias consultas en un viaje; se leen con `ReadSingleAsync`/`ReadAsync`.
- **Transacción:** `BeginTransaction`, `Commit`, `Rollback`.
- **`using`:** libera conexiones/transacciones al salir del bloque.
- **Nullable reference types:** `string?` indica que puede ser null; el compilador obliga a considerarlo.

## 10. Conceptos SQL que ya conoces (y cómo se usan aquí)

- **Vista:** `vwPropuestaDetalle`, para no repetir joins.
- **CTE:** `WITH dias AS (...)`, `WITH ranking AS (...)`.
- **Funciones de ventana:** `ROW_NUMBER`, `LAG`, `SUM() OVER`, `PERCENTILE_CONT`.
- **Paginación:** `ORDER BY ... OFFSET @offset ROWS FETCH NEXT @tamano ROWS ONLY`.
- **Bloqueo:** `WITH (UPDLOCK, ROWLOCK)` para que dos sesiones no resuelvan la misma propuesta.
- **Índice con columnas incluidas:** `IX_Propuesta_FechaEstado`.
- **Parámetros:** nunca concatenar texto del usuario en el SQL.
- **Identidad:** los seeds usan IDs explícitos para ser reproducibles.

## 11. Plan sugerido de 10 días

| Día | Objetivo |
| --- | --- |
| 1 | Levantar todo, recorrer la app, leer README y este documento |
| 2 | Leer el flujo de una petición y poner breakpoints en API y Angular |
| 3 | Ejercicios 1, 2 y 3 (filtros, alias, errores) |
| 4 | Ejercicio 4 (transacción y concurrencia) + revisar auditoría |
| 5 | Ejercicio 5 (regla de negocio rechazo) y ejercicio 6 (filtro segmento) |
| 6 | SQL: ejecutar `003`, ejercicio 7 (índices) |
| 7 | Ejercicio 8 (endpoint de movimientos) |
| 8 | Ejercicio 9 (tipo de cambio) |
| 9 | Ejercicio 10 (pruebas) + ordenar el código |
| 10 | README final, capturas, deploy local y repaso para entrevista |

## 12. Glosario mínimo

- **API:** programa que recibe HTTP y responde JSON.
- **Endpoint:** una ruta + método (`GET /api/propuestas`).
- **DTO:** objeto de transferencia de datos.
- **JSON:** formato de texto para intercambiar datos.
- **Proxy:** servidor que reenvía pedidos; aquí evita CORS en desarrollo.
- **CORS:** política del navegador para permitir llamadas entre dominios.
- **Signal:** estado reactivo de Angular.
- **Observable:** flujo de eventos/valores asíncronos.
- **Transacción:** unidad atómica de trabajo en SQL.
- **UPDLOCK:** bloqueo de actualización que impide que otra sesión modifique la fila mientras la lees.
- **Snapshot:** valor guardado en un momento, no recalculado en cada lectura.

## 13. Siguiente nivel

Cuando termines los ejercicios, el siguiente salto natural es:

1. **Autenticación real** con JWT y roles.
2. **Pruebas de integración** de la API con una base de datos de prueba.
3. **Docker Compose** para levantar todo con un comando.
4. **CI** en GitHub Actions.
5. **Observabilidad**: logs con correlation id y métricas.

Con eso el proyecto deja de ser un demo y se parece a un sistema que se puede operar.
