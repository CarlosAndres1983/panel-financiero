# Guía paso a paso: clonar, levantar y recorrer la app

Esta es la guía para **aprender la app operando tú mismo**: clonas con Fork, levantas el proyecto con tus propias manos (VS Code o Visual Studio) y recorres el flujo con breakpoints, paso por paso, como si fuera un formulario de VB.NET.

> Si solo quieres el mapa conceptual (arquitectura, capas, diagramas), ve a [`ARQUITECTURA.md`](ARQUITECTURA.md). Esta guía es la versión operativa: tecla por tecla.

---

## Parte 0 — Clonar con Fork y organizarte

**No necesitas hacer "fork" en GitHub**: el repo es tuyo. Lo que necesitas es un **clon local en otra carpeta** para practicar sin miedo.

1. Abre Fork → `File → Clone` → pega `https://github.com/CarlosAndres1983/panel-financiero.git`
2. Carpeta destino: una nueva, por ejemplo `C:\panel-financiero-aprendizaje` (así este clon es tu "mesa de práctica").
3. `Clone`. Ya tienes todo: historial, ramas, tags.

### Estrategia de ramas (NO uses GitFlow)

GitFlow sirve para equipos con releases y hotfixes. Para aprender solo, es ruido. Usa este modelo simple, que es el que usé para construir el proyecto:

| Rama | Rol | Regla |
| --- | --- | --- |
| `main` | La versión que funciona | **Siempre verde.** Si no compila, no entra. |
| `practica/<nombre>` | Donde rompes y experimentas | Una por ejercicio o experimento. |

Flujo (lo mismo por comando o por clicks en Fork):

```bash
git switch -c practica/romper-alias      # 1. crea tu rama de experimento
# ... rompes, arreglas, aprendes ...
git add -A; git commit -m "practica: alias roto"   # 2. commit chico por avance
git switch main                           # 3. vuelves a la buena
git merge practica/romper-alias           # 4. solo si el experimento vale
```

En Fork es igual: botón derecho en un commit → `New Branch Here`; arriba a la izquierda cambias de rama (checkout); `Push` sube a GitHub.

**Regla de oro:** si tu experimento rompe algo y no quieres el desorden, `git switch main` y todo vuelve a estar perfecto. Esa es la ventaja sobre "guardar copias del proyecto en carpetas".

---

## Parte 1 — Levantar el proyecto tú mismo

El orden importa: **base de datos → API → web**. Cada pieza se verifica antes de pasar a la siguiente.

### 1.0 Verificar requisitos (una vez)

```powershell
dotnet --version     # 9.x
node --version       # 20.19+, 22.12+ o 24
sqlcmd -S .\SQLEXPRESS -E -Q "SELECT @@VERSION"   # la instancia responde
```

### 1.1 Base de datos (una vez, o para reiniciar datos)

```powershell
.\scripts\crear-bd.ps1
```

Qué hace: crea `PanelFinanciero` si no existe, ejecuta `sql\001_esquema.sql` (tablas, índices, vistas) y `sql\002_datos_prueba.sql` (datos ficticios relativos a la fecha de hoy), y al final muestra un conteo de filas. Si ves `clientes=24, cuentas=40, propuestas=600, movimientos=2000`, quedó lista.

### 1.2 La API — elige tu camino

**Camino A — Visual Studio (el más parecido a lo que conoces):**

1. Doble click en **`PanelFinanciero.sln`** (raíz del repo). Se abre con el proyecto API cargado.
2. `F5`. Compila y levanta el servicio en `http://localhost:5080`.
3. Se abre el navegador en **Swagger** (`/swagger`): es tu "probador de SPs" web. Ejecuta `GET /api/health` y luego `GET /api/operaciones`.
4. Desde ahora puedes poner breakpoints con click al costado de la línea, como siempre.

**Camino B — VS Code (la carpeta raíz):**

1. `File → Open Folder` → la raíz del repo.
2. `F5` → elige la configuración **"API Panel (.NET)"** (está en `.vscode/launch.json`, ya preparada).
3. Compila (tarea `api: build` en `.vscode/tasks.json`), levanta en 5080 y abre Swagger solo.

**Camino C — Terminal pura (rápido para probar SQL):**

```powershell
cd api\Panel.Api
dotnet run --urls http://localhost:5080
```

Verificación: `http://localhost:5080/api/health` responde `{"estado":"ok",...}`.

### 1.3 La web (Angular)

```powershell
cd web
npm install        # solo la primera vez (o cuando cambie package.json)
npm start          # levanta el dev server en http://localhost:4200
```

En VS Code también puedes usar la tarea `web: start` (Terminal → Run Task). En VS Code existe además la configuración **"Web: Chrome (requiere npm start)"**: con `npm start` corriendo, `F5` sobre ella abre Chrome con la web depurable desde el propio VS Code.

Verificación: `http://localhost:4200` muestra el Dashboard con datos.

### 1.4 Detener todo

- Cada consola: `Ctrl+C`.
- O de una vez: `.\scripts\detener.ps1`.

### 1.5 Si algo falla al levantar

| Síntoma | Causa | Solución |
| --- | --- | --- |
| `Cannot open database "PanelFinanciero"` | No corriste el paso 1.1 | `.\scripts\crear-bd.ps1` |
| La web carga pero sin datos | API caída | Revisa la consola de la API; `dotnet run` otra vez |
| Puerto 5080 u 4200 ocupado | Algo lo usa | `.\scripts\detener.ps1` |
| `sqlcmd no se reconoce` | Falta el cliente | Instala "Command Line Utilities" de SQL Server |
| Cambios que no se ven | Cache | `Ctrl+F5` en el navegador; reinicia `dotnet run` si tocaste C# |

---

## Parte 2 — El mapa antes de recorrer

Una pantalla = una carpeta en `web/src/app/features/`. Un dominio de negocio = una carpeta en `api/Panel.Api/Features/`. Un conjunto de tablas = un script en `sql/`.

```text
PESTAÑA OPERACIONES
  SQL:   sql/001_esquema.sql          -> vista vwOperacionDetalle
  API:   api/.../Features/Operaciones -> OperacionesEndpoints.cs + OperacionDto.cs
  WEB:   web/.../features/operaciones -> operaciones-page.ts / .html / .css
         web/.../core/services        -> operacion.service.ts
         web/.../core/models          -> operacion.model.ts
         web/.../app.routes.ts        -> ruta /operaciones
         web/.../layout/shell         -> link del menú

PESTAÑA PROPUESTAS  (misma estructura, + resolver con transacción)
  sql:   vista vwPropuestaDetalle
  api:   Features/Propuestas (buscar, estados, resolver)
  web:   features/propuestas + propuesta.service.ts

PESTAÑA DASHBOARD (solo lectura)
  api:   Features/Dashboard  |  web: features/dashboard
```

---

## Parte 3 — Recorrido guiado: el botón "Consultar" (Operaciones)

Este es el ejercicio central. La pregunta que te haces es: *"aprieto el botón... ¿quién se entera?"*. La respuesta son **9 saltos**, y en cada uno hay un punto exacto donde pararte con un breakpoint.

Antes de empezar: levanta API y web, abre `http://localhost:4200/operaciones` y **F12** (DevTools). Vas a usar tres ventanas a la vez: el código, el navegador y la consola de la API.

### Salto 1 — El botón llama a un método
**Archivo:** `web/src/app/features/operaciones/operaciones-page.html`
En VB.NET un botón tenía `Click` → aquí cada elemento declara su evento en el HTML:
```html
<button class="btn btn-primario" (click)="aplicar()" ...>Consultar</button>
```
Ese `(click)="aplicar()"` significa: *cuando hagan click, llama a `aplicar()` del componente*. Los inputs de fecha/tipo/texto tienen `(input)="actualizar('fechaDesde', $event)"` — cada tecleo actualiza el estado del componente (un **signal**), que es tu variable privada del formulario.

### Salto 2 — `aplicar()` prepara y delega
**Archivo:** `operaciones-page.ts`
```ts
protected aplicar(): void {
  this.filtros.update((f) => ({ ...f, pagina: 1 }));  // vuelve a la página 1
  this.cargar();
}
```
📌 **Breakpoint aquí** (línea de `cargar()`). Click en Consultar → se detiene. Pasa el mouse sobre `filtros`: ahí está todo lo que el usuario escribió.

### Salto 3 — `cargar()` valida y llama al servicio
Mismo archivo, método `cargar()`:
1. Valida fechas (si están mal: `this.error.set('...')` y no consulta — es tu `If` antes del `Call`).
2. `this.cargando.set(true)` → la UI cambia (la tarjeta se pone translúcida).
3. `this.propuestaService`... no: `this.operacionService.buscar(filtros)`.
📌 Inspecciona `filtros` acá también.

### Salto 4 — El servicio arma la URL
**Archivo:** `web/src/app/core/services/operacion.service.ts`
```ts
return this.http.get<PaginaOperaciones>(`${API_URL}/operaciones`, { params });
```
Esto es tu `ADODB.Command` web: construye `GET /api/operaciones?fechaDesde=...&pagina=1&tamano=10`. El `<PaginaOperaciones>` es el **tipo de la respuesta** (tu recordset tipado). Nota que el método **devuelve** el observable en vez de ejecutar: quien se suscribe, ejecuta.

### Salto 5 — La petición viaja (mírala en el navegador)
DevTools → **Network** → filtro `api` → click en la petición:
- **Headers:** la URL completa con los parámetros.
- **Response:** el JSON crudo `{ items: [...], total: 702, resumen: {...} }`.
Ese JSON **es** el DTO de C#. Míralo con este ojo: *cada propiedad del JSON debe existir en `core/models/operacion.model.ts`* — y si no existe, la columna muere ahí (error clásico de mapeo, igual que un alias mal puesto en un SELECT).

### Salto 6 — La API recibe y valida
**Archivo:** `api/Panel.Api/Features/Operaciones/OperacionesEndpoints.cs`, método `BuscarAsync`.
📌 **Breakpoint en la primera línea.** Pasa F10 y observa:
- `Fechas.TryParse` (`Comun/Fechas.cs`): acepta `yyyy-MM-dd` y `dd-MM-yyyy`; si falla → **400** con mensaje en español (pruébalo: en la URL cambia `fechaDesde` por `abc`).
- `tipoFiltro`: solo acepta `C` o `D` (o vacío). Otra validación → otro 400.
- `Math.Clamp(tamano ?? 10, 1, 100)`: límites de paginación.

### Salto 7 — El SQL sale hacia SQL Server
Un poco más abajo en el mismo método:
```csharp
using var multi = await conexion.QueryMultipleAsync(new CommandDefinition(sql, parametros, ...));
```
📌 **Breakpoint justo ahí** y pásale el mouse a `sql` y a `parametros`: ves **la consulta exacta y los valores** que irán a la base. Es tu `cmd.CommandText` de ADO.NET, a la vista.

F10 para ejecutarlo y ve a SSMS: copia el SQL, reemplaza `@desde`/`@hastaExclusivo` por valores, y ejecútalo tú. Verás las mismas filas que llegan al JSON. **Cuando esto lo hagas una vez, la base de datos deja de ser magia.**

El SQL consulta la vista `vwOperacionDetalle` (`sql/001_esquema.sql`): el join Movimiento+Cuenta+Cliente ya está hecho ahí, y `montoClp` (la conversión demo USD→CLP) se calcula en la vista, no en C#.

### Salto 8 — El mapeo por nombre (Dapper)
Todavía en `BuscarAsync`:
```csharp
var resumen = await multi.ReadSingleAsync<ResumenOperacionesDto>();
var items = (await multi.ReadAsync<OperacionDto>()).AsList();
```
Dapper llena los DTO **emparejando nombres de columna con nombres de propiedad**, sin importar mayúsculas. Cambia un alias en la vista y el JSON pierde la propiedad: es el error #1 de principiante en esta pila, y conviene provocarlo a propósito (drill 2 abajo).

### Salto 9 — La respuesta vuelve y la UI re-dibuja
1. `Results.Ok(new PaginaOperacionesDto {...})` → ASP.NET lo serializa a JSON.
2. En el navegador, el `subscribe` de `cargar()` recibe `pagina`:
```ts
next: (pagina) => { ... this.datos.set(pagina); this.cargando.set(false); }
```
3. `this.datos.set(...)` dispara el re-render: el `@if (datos(); as d)` del HTML se cumple, la `@for (o of d.items...)` dibuja una fila por movimiento, los pipes `| monto: o.moneda` y `| date: 'dd-MM-yyyy'` formatean.
4. Los KPIs son `computed(...)` sobre la misma señal: se recalculan solos.

**Ya lo recorriste completo.** Botón → método → servicio → HTTP → endpoint → SQL → vista → DTO → JSON → signal → plantilla. En VB.NET todo eso vivía en un solo proceso; aquí son tres, y ese recorrido es exactamente lo que un entrevistador llama "entender el flujo de la aplicación".

---

## Parte 3.1 — Segundo recorrido: Aprobar una propuesta (el rico)

Mismo mecanismo, pero con **transacción, bloqueo y auditoría**. Es lo que más impresiona en una entrevista.

1. **UI:** `propuestas-page.html` → fila → `(click)="seleccionar(p)"` → drawer → botón Aprobar → `abrirAccion('APROBAR')` → modal con comentario → `confirmarAccion()`.
2. **Servicio:** `PropuestaService.resolver(idPropuesta, accion, usuario, comentario)` → `POST /api/propuestas/{id}/resolver`.
3. **API:** `PropuestasEndpoints.ResolverAsync` — léelo como un guion de cine:
   - Valida acción y usuario (400 si no).
   - `conexion.BeginTransaction()` — desde aquí todo o nada.
   - `SELECT ... WITH (UPDLOCK, ROWLOCK)`: bloquea la fila de la propuesta. Si otro analista la está resolviendo, **este espera**.
   - Si el estado ya no es `PEND`/`REVI` → `Rollback` + **409** con mensaje (el conflicto).
   - `UPDATE dbo.Propuesta SET idEstado..., fechaResolucion..., usuarioResolucion...`
   - `INSERT dbo.AuditoriaPropuesta ...` — en la **misma transacción**: si este insert falla, el UPDATE también se revierte.
   - `Commit()` → JSON de vuelta.
4. **UI:** toast `Propuesta #X quedó aprobada.` y `this.cargar()` refresca la bandeja.

📌 **Breakpoints:** en la línea del `SELECT ... UPDLOCK`, en el `Commit`, y en el `return Results.Conflict`.

**Drill estrella:** abre Swagger en dos pestañas, prepara el mismo `POST .../resolver` y ejecuta dos veces. La segunda responde **409**. Luego en SSMS:
```sql
SELECT TOP (5) * FROM dbo.AuditoriaPropuesta ORDER BY idAuditoria DESC;
```
Debes ver **una sola** fila por propuesta, no dos.

---

## Parte 3.2 — Tercer recorrido: Dashboard (solo lectura)

1. Al abrir `/dashboard`, `ngOnInit()` (tu `Form_Load`) llama `DashboardService.obtener()` → `GET /api/dashboard`.
2. `DashboardEndpoints.cs` ejecuta **varias consultas en un viaje** (`QueryMultiple`): saldos, pendientes, serie de 7 días, distribución por estado, últimas propuestas.
3. El componente guarda todo en signals; el gráfico de barras es HTML/CSS puro: la altura de cada barra sale de un `computed` que convierte la cantidad en porcentaje.

Entra con breakpoint en `ngOnInit` del dashboard y observa que la petición **sale antes de que la pantalla termine de dibujar** — la asincronía en acción.

---

## Parte 4 — Drills: romper, observar el síntoma, arreglar

Hazlos en rama `practica/*`. Cada uno enseña una capa.

### Drill 1 — Apagar la API (capa: red)
1. `Ctrl+C` en la API (déjala caída) → en la web, Consultar.
2. **Síntoma:** toast de error; Network muestra el request en rojo.
3. Levántala y reintenta. Aprendiste: el interceptor (`core/http/error.interceptor.ts`) convierte el fallo en mensaje legible; la UI nunca toca el error crudo.

### Drill 2 — Romper un alias SQL (capa: mapeo)
1. En `001_esquema.sql`, vista `vwOperacionDetalle`, cambia `m.monto` por `m.monto AS montoX`. Ejecuta: `sqlcmd -S .\SQLEXPRESS -E -b -f 65001 -i sql\001_esquema.sql`
2. Recarga Operaciones: la columna Monto aparece en `$0` o `—`.
3. **Síntoma en Network:** el JSON ya no trae `monto`.
4. Arregla el alias (o cambia el DTO). Aprendiste: **Dapper mapea por nombre**.

### Drill 3 — Fechas al revés (capa: validación)
1. En la UI: fecha desde mayor que hasta → Consultar.
2. Banner: "La fecha desde no puede ser mayor que la fecha hasta."
3. Encuentra la validación dos veces: en `cargar()` (front) y en `BuscarAsync` (back). **Pregunta para ti:** ¿por qué se valida en ambos lados? (Respuesta: la API no puede confiar en quién la llama — Swagger, otro front, Postman.)

### Drill 4 — Cambiar el rango por defecto (capa: estado)
1. En `operaciones-page.ts`, función `filtrosIniciales()`: cambia `haceDiasISO(30)` por `haceDiasISO(7)`.
2. Recarga: menos movimientos. En `OperacionesEndpoints.BuscarAsync` hay otro `-30` para el caso "sin fechas" (Swagger). Dos defaults, dos capas.

### Drill 5 — El 409 (capa: transacción)
Ya descrito en 3.1. Es el mejor drill del proyecto.

---

## Parte 5 — Checklist del día 1

- [ ] Cloné con Fork a `panel-financiero-aprendizaje` y creé mi primera rama `practica/`
- [ ] `crear-bd.ps1` corrido por mí (veo el conteo de filas)
- [ ] API levantada con F5 y Swagger abierto
- [ ] Web levantada con `npm start` y datos visibles
- [ ] Recorrí los 9 saltos de "Consultar" con breakpoints
- [ ] Vi el JSON en Network y lo comparé con el DTO
- [ ] Ejecuté en SSMS el SQL que vi en el breakpoint
- [ ] Drill 1 (API caída) hecho
- [ ] Drill 2 (alias roto) hecho y arreglado
- [ ] El 409 visto dos veces (con auditoría en SSMS)

Cuando los 10 estén listos, ya no eres alguien que "usó la app": eres alguien que sabe dónde vive cada cosa y por qué. Ese es el punto de partida para las pestañas nuevas, JWT y todo lo que venga.

---

*Guía complementaria a [`ARQUITECTURA.md`](ARQUITECTURA.md) (mapa conceptual) y [`APRENDER.md`](APRENDER.md) (ejercicios avanzados y equivalencias VB.NET).*
