# Skill — Converger el código con lo acordado

Tags: [specs] [review] [calidad]

## Objetivo
Verificar que el código ya implementado de una feature **corresponde a lo que el cliente firmó**:
que cada requisito de `spec.md` tenga implementación real y verificable, que no exista
implementación que ningún requisito pida, y que `plan.md` y `tasks.md` sigan
describiendo el producto que efectivamente existe.

> **`review_feature` pregunta "¿está bien escrito?". `converge` pregunta "¿es lo que se acordó?"**

Son dos gates distintos y ninguno cubre al otro. Un changeset puede pasar el review con nota
perfecta y no implementar lo que la spec prometía; y puede cumplir la spec al pie de la letra
mientras rompe la frontera entre módulos. `converge` no juzga la calidad del código: no mira
tipado, ni nombres, ni cobertura. Mira **correspondencia**.

Dónde encaja respecto de las otras verificaciones:

| Momento | Skill | Compara |
|---|---|---|
| Antes de implementar | `/analyze` | documento contra documento: spec ↔ plan ↔ tasks |
| Después de implementar y testear | `converge` | **código contra lo acordado**: spec, plan, tasks, diagramas |
| Antes del merge | `review_feature` | código contra los estándares y las fronteras |

El hueco que cierra es concreto: hasta acá nadie verificaba que el código terminado hiciera lo
que el cliente firmó.

## Cuándo usarla
- Después del `Tester` y antes del `Code-Reviewer` (`AGENTS.md` → "Cadena de un feature"), sobre
  toda feature que llegó al final de `/implement`.
- Cuando la implementación se repartió entre varias sesiones o varios agentes y nadie tuvo la
  feature entera a la vista.
- Cuando se reabre una feature ya entregada para extenderla: primero se verifica que lo que hay
  todavía corresponda a su spec.
- Antes de que `/ship` mueva la spec a `docs/specs/archive/`: lo que se archiva tiene que ser
  verdad.

Cuándo **no** usarla:
- Antes de implementar: ahí va `/analyze`, que compara documentos entre sí.
- Para revisar calidad, fronteras o tipado: eso es `review_feature`.

**Rol dueño: `Lead`** — el mismo que posee `/analyze`, y por la misma razón: es el único que ve
todos los artefactos y no escribe código, así que puede juzgar correspondencia sin haber sido
parte de la implementación.

## Precondiciones
- Existen `docs/specs/<NNN-feature>/spec.md`, `plan.md` y `tasks.md`.
- `spec.md` está en estado `Aprobado` (firma del cliente registrada por `/approve-spec`).
- La implementación se declara terminada: `tasks.md` tiene tareas marcadas como completas.
- El `Tester` ya corrió y la suite pasa: `cd backend && uv run pytest`.
- El agente opera como `Lead` (`agents/roles/lead.md`).

## Reglas (ESTRICTO)
- **Se verifica contra el código, no contra los documentos.** Un requisito se marca implementado
  sólo con evidencia localizable: archivo y símbolo
  (`backend/app/modules/<modulo>/service.py::<método>`), ruta declarada en
  `backend/app/modules/<modulo>/router.py` y montada en `backend/app/main.py`, página bajo
  `frontend/src/pages/`, o test que lo ejercita. "Debería estar en el servicio" no es evidencia.
  Cada pieza de un módulo empieza como archivo y crece a carpeta del mismo nombre, así que la
  evidencia puede ser `modules/<modulo>/service.py::<método>` o
  `modules/<modulo>/services/<archivo>.py::<método>`: es el mismo lugar del mismo módulo, y
  ninguna de las dos formas es una desviación.
- **Un requisito sin implementar es un hallazgo**, no una omisión aceptable ni una tarea futura.
- **El alcance no pedido es un hallazgo de la misma gravedad.** Se detecta menos porque nada
  falla: es funcionalidad que el cliente no pidió ni firmó, y que el equipo va a mantener para
  siempre.
- **Esta skill no arregla nada.** No toca código (`backend/`, `frontend/`, `backend/tests/`) ni
  los artefactos de otros roles (`spec.md`, `plan.md`, `tasks.md`). Lo único que el
  `Lead` escribe es el informe, dentro de `docs/specs/<NNN-feature>/`; cada hallazgo se devuelve
  con su rol dueño (`agents/roles/lead.md` → "Autoridad").
- **La deriva mayor bloquea el gate**: la feature no pasa al `Code-Reviewer` hasta resolverse.
- **La decisión entre implementar lo que falta y renegociar la spec es del humano.** El agente
  presenta las dos opciones con su costo; no elige.

## La regla que hace útil a esta skill

**No alcanza con leer los documentos.** Que `tasks.md` diga que algo está hecho es exactamente la
afirmación que hay que auditar. Cada requisito se busca en `backend/app/` y en `frontend/src/` —con
`grep` y abriendo los archivos—, teniendo en cuenta que la documentación está en español y el
código en inglés: hay que buscar por el término traducido (`quote`, `favorite`, `symbol`,
`interval`).

## Pasos (ORDEN OBLIGATORIO)

### 1) Resolver la feature y el changeset
```bash
ls docs/specs/
ls docs/specs/<NNN-feature>/
git rev-parse --abbrev-ref HEAD          # esperado: feat/<NNN-feature>
git diff main...HEAD --name-only
```
Si la rama no sigue la convención, o el repositorio todavía no tiene historia de git, el
changeset se arma con los archivos que nombran `plan.md` y `tasks.md`, y se completa con las
búsquedas del paso 3. Una feature ya entregada vive en `docs/specs/archive/<NNN-feature>/`.

---

### 2) Extraer el inventario de lo acordado
Antes de mirar una línea de código, armar la lista de lo que se prometió:

```bash
grep -nE "(RF|CA|US)[- ]?[0-9]+" docs/specs/<NNN-feature>/spec.md
sed -n '/Contexto de traspaso/,$p' docs/specs/<NNN-feature>/plan.md
grep -nE "^\s*-\s*\[[ xX]\]" docs/specs/<NNN-feature>/tasks.md
```

- De `spec.md`: requisitos funcionales y criterios de aceptación, con su identificador.
- De `plan.md`: el enfoque técnico decidido y la sección **Contexto de traspaso** (decisiones y
  su porqué, alternativas descartadas).
- De `tasks.md`: las tareas y su estado declarado.

Si un requisito está redactado de forma que no se puede contrastar contra código (no dice qué
tiene que pasar), es un hallazgo del `Solution-Designer` — no una excusa para saltearlo.

---

### 3) Inventariar lo que el código realmente hace
```bash
ls backend/app/modules/
ls backend/app/modules/<modulo>/
grep -rn "include_router" backend/app/main.py
grep -rnE "@router\.(get|post|put|patch|delete)" backend/app/modules/*/router.py
grep -rn "def " backend/app/modules/<modulo>/service.py
grep -nE "^(def |class |__all__)" backend/app/modules/*/__init__.py
ls backend/alembic/versions/
ls frontend/src/pages frontend/src/components frontend/src/api
```
La lista de módulos, endpoints, services, repositories, símbolos que cada módulo exporta en el
`__all__` de su `__init__.py`, páginas y migraciones que existen es el otro extremo de la
comparación. Sin ella no se puede hacer el paso 5.

---

### 4) Cobertura de requisitos (spec → código)
Recorrer el inventario del paso 2 **de a un requisito**, y buscar su implementación. Como la
documentación va en español y el código en inglés, buscar por el término de dominio traducido
(`quote`, `favorite`, `symbol`, `interval`, …):

```bash
grep -rni "<termino_del_dominio>" backend/app --include="*.py"
grep -rni "<termino_del_dominio>" frontend/src --include="*.ts*"
grep -rni "<termino_del_dominio>" backend/tests
```

Volcarlo en la tabla de trazabilidad del informe, con un estado por requisito:

| Estado | Significado |
|---|---|
| Implementado | Hay código que lo cumple y evidencia que lo señala |
| Parcial | Existe el camino feliz, falta una condición, un rol o un caso de error que la spec pide |
| Ausente | No hay código que lo implemente |

`Parcial` y `Ausente` son hallazgos de tipo **Requisito sin implementar**.

---

### 5) Alcance no pedido (código → spec)
Recorrer el inventario del paso 3 en sentido inverso: por cada endpoint, página, tabla, método
de un service, nombre declarado en el `__all__` de un módulo o parámetro configurable, preguntar
**qué requisito lo pide**. Si no hay ninguno, distinguir:

- **Andamiaje técnico que `plan.md` justifica** (repositorio base, migración de soporte, el
  cliente del provider): no es hallazgo, es implementación de una decisión documentada.
- **Capacidad de negocio visible para el usuario que ningún requisito pide**: hallazgo de tipo
  **Alcance no pedido**. Es alcance que el cliente no firmó y que hay que mantener para siempre.

Lo que empieza con guión bajo (`_calcular_ttl`, `_DEFAULT_TTL`, `_Cursor`) es privado del archivo
por convención (`PY-10`): no es superficie y no entra a este inventario. Los dos niveles de
privacidad son distintos —el guión bajo esconde del archivo, el `__all__` define lo que ven los
otros módulos— y acá se recorre el segundo.

Si el andamiaje no está en el plan, es deriva del plan (paso 7), no alcance no pedido.

---

### 6) Tareas declaradas completas que no lo están
Por cada tarea marcada `[x]` en `tasks.md`, abrir el archivo que la tarea nombra y verificar que
exista lo que dice que hizo. Incluye los tests que la tarea promete:

```bash
grep -rn "<nombre_del_simbolo>" backend/app backend/tests frontend/src
```
Una tarea marcada completa cuyo código no aparece es un hallazgo de tipo **Tarea sin respaldo**,
y vuelve al `Developer`.

---

### 7) Deriva respecto del plan
Comparar las decisiones de `plan.md` (y de su "Contexto de traspaso") contra lo que el código
hizo: en qué módulo quedó cada decisión y de qué lado de la frontera, qué excepciones de dominio
(`app/errors.py`) levanta el service y cómo las traduce `main.py`, qué tablas toca —cada
tabla tiene un módulo dueño—, la estrategia de caché y TTL contra el proveedor, y los contratos
de `contracts/` contra las rutas y schemas reales.

Si la feature lee datos de otro módulo, el plan tiene que decir por qué símbolo del `__all__`
pasa y en qué forma: la grilla de "Mis Acciones" cruza `favorites` con `stocks` a través de
`from app.modules.stocks import get_stocks`, **en batch**. Un N+1 —una llamada por símbolo— o una
lectura que entra por dentro del paquete ajeno (`app.modules.stocks.service`,
`app.modules.stocks.repository`) son deriva del plan, no un detalle de implementación.

Ese cruce es uno de los **dos** que forman el inventario completo de lecturas cruzadas del
backend: `get_stocks` y `StockInfo`, que `favorites` consume de `stocks` para la grilla, e
`is_favorite`, que `quotes` consume de `favorites` para servir el gráfico sólo por las acciones de
quien pregunta. Los `__init__.py` de `auth` y `quotes` exportan sólo su `router`; el de `favorites`,
su `router` y `is_favorite`. `get_current_user` no cuenta como lectura
cruzada: es una primitiva de seguridad que vive en `app/security.py` —junto con Argon2 y
JWT— y la importan los routers de todos los módulos. Un plan que diga que la feature toma
`get_current_user` de `auth` está describiendo algo que no existe.

Una divergencia no es necesariamente un error — pero el plan tiene que reflejar la realidad o
deja de servirle al próximo que lo lea. Clasificar cada una:
- el código está bien y el plan quedó viejo → actualizar `plan.md`, vuelve al arquitecto
  (`Backend-Architect` / `Frontend-Architect`);
- el código se fue del plan sin motivo registrado → vuelve al `Developer`.

---

### 8) Las ambigüedades declaradas siguen siendo verdad
Cada entrada de `docs/PROJECT_BRIEF.md` → *Ambigüedades declaradas* dice cómo se resolvió algo que
el enunciado no definía. Verificar que el código haga **eso**, y no otra cosa que alguien decidió
después sin actualizar el documento.

Una resolución que el código contradice es un hallazgo de tipo **Ambigüedad derivada**: o se
corrige el código, o se actualiza la declaración — y esa decisión es del humano (Artículo VII).

---

### 9) Contradicción con una regla del dominio
Releer las cinco reglas inviolables de `AGENTS.md` → "Reglas del dominio (INVIOLABLES)" y la
frontera entre módulos del Artículo IV, y verificar que lo que la feature promete no obligue a
violarlas:

1. La API key vive sólo en el backend (Artículo I).
2. La cuota es finita: no se consulta al proveedor si el dato está en la base (Artículo II).
3. Toda query de datos del usuario filtra por el `sub` del token (Artículo III).
4. A un módulo se entra por su paquete —lo que declara `__all__` en su `__init__.py`—, nunca por
   una ruta más profunda; adentro, el flujo va en un solo sentido: `router` → `service` →
   `repository` (Artículo IV).
5. El enunciado se cumple literal, y lo que no define se resuelve declarándolo (Artículo VII).
6. Ningún ADR nuevo apareció en `docs/DECISIONS.md` sin que el humano lo pidiera (Artículo X).

```bash
grep -rniE "twelvedata|apikey|api_key" frontend/src
grep -rnE "^\s*(import|from)\s+(httpx|requests|aiohttp|urllib\.request)\b" backend/app | grep -v "backend/app/providers/"
grep -rni "twelvedata" backend/app --include="*.py" | grep -vE "backend/app/(providers/twelvedata\.py|settings\.py)"
grep -rnE "user_id\s*[:=].*(path|query|body)" backend/app/modules/*/router.py
grep -rnE "from app\.modules\.[a-z_]+\.(router|io|service|repository|models)" backend/app/modules
```

El último `grep` lista todos los imports por ruta profunda. Los que apuntan al **propio** módulo
son la forma correcta de importar adentro —por ruta completa, nunca por `app.modules.<modulo>`, que
reentra al `__init__` a medio inicializar—; los que cruzan a otro módulo son la violación.

El ángulo acá es distinto del de `review_feature`: no se busca la violación en el código —esa la
bloquea el reviewer— sino que **lo prometido** en `spec.md` o `plan.md` no se pueda cumplir sin
violarla. Si un requisito firmado sólo es satisfacible rompiendo una regla inviolable, el
hallazgo es de la spec y sube al humano: la regla no se negocia, el requisito sí.

---

### 10) Emitir el veredicto
Escribir el informe con el formato de abajo. Un converge sin veredicto explícito no está
completo, y el `Code-Reviewer` no puede arrancar sin él.

## Validación
- [ ] Todo requisito de `spec.md` aparece en la tabla de trazabilidad con su estado. Ninguno quedó sin fila.
- [ ] Ninguna fila dice `Implementado` sin evidencia localizable (archivo + símbolo, ruta, página o test).
- [ ] Se recorrió el sentido inverso: cada endpoint, página, tabla y método de service tiene un requisito que lo pide, o quedó reportado.
- [ ] Cada tarea marcada `[x]` en `tasks.md` se verificó contra el archivo que nombra.
- [ ] Las decisiones de `plan.md` (incluido el "Contexto de traspaso") se compararon contra el código.
- [ ] Las cinco reglas del dominio y la frontera entre módulos se contrastaron contra lo que la feature promete.
- [ ] Las ambigüedades declaradas en `docs/PROJECT_BRIEF.md` siguen describiendo lo que el código hace.
- [ ] Hay un veredicto escrito, y cada hallazgo tiene tipo, rol dueño y acción concreta.
- [ ] No se modificó código ni artefactos de otros roles durante la corrida: lo único escrito es el informe.

## Formato de salida (informe de convergencia)

Un veredicto, uno solo, y explícito:

- **Converge** — todo requisito tiene implementación con evidencia, no hay alcance sin
  requisito, las tareas completas están respaldadas, y plan y diagramas describen lo que el
  código hace. Pasa al `Code-Reviewer`.
- **Deriva menor** — el código y la spec describen el mismo producto, pero algún artefacto
  quedó desactualizado (el plan documenta un enfoque que el código cambió con motivo, un
  diagrama muestra un paso que se movió, una tarea quedó sin marcar). **No bloquea el gate**: se
  actualiza el artefacto desactualizado, con su rol dueño, y la feature sigue.
- **Deriva mayor** — el código y la spec **no describen el mismo producto**: hay requisitos
  firmados sin implementar, o capacidades implementadas que nadie pidió. **Bloquea el gate**: la
  feature no pasa al `Code-Reviewer`.

Ante una **deriva mayor** hay dos salidas, y la salida por defecto **no** es "arreglar el código":

1. **Implementar lo que falta** (o quitar lo que sobra) → vuelve al `Developer`, y después otra
   vez al `Tester`.
2. **Corregir la spec** para que refleje lo que de verdad se acordó → vuelve al
   `Solution-Designer`, y **el cliente la vuelve a firmar** con `/approve-spec`: el gate de la
   firma se reabre.

A veces la spec estaba mal y lo correcto es renegociarla. **Esa decisión es del humano, no del
agente**: el agente presenta las dos opciones con lo que cuesta cada una y espera. Elegir por el
cliente es exactamente lo que el gate de firma existe para impedir.

### Tabla de trazabilidad
| Requisito | Qué promete la spec | Dónde está implementado | Evidencia | Estado |
|---|---|---|---|---|

### Hallazgos
| # | Tipo | Qué dice el artefacto | Qué hace el código | Rol dueño | Acción |
|---|---|---|---|---|---|

Tipos de hallazgo: **Requisito sin implementar** · **Alcance no pedido** · **Tarea sin respaldo**
· **Deriva del plan** · **Diagrama desactualizado** · **Contradicción con una regla del dominio**.

## Errores comunes (evitar)

### 1) Leer documentos en lugar de verificar código
Confirmar que `tasks.md` dice que la tarea está hecha no es verificar nada: es repetir la
afirmación que hay que auditar. Toda fila `Implementado` sale de un `grep` o de abrir el archivo.

### 2) Aceptar el nombre como evidencia
Que exista `app/modules/quotes/service.py::get_series` no prueba que sirva TSLA de la base cuando el
dato todavía está fresco. Si el requisito define un comportamiento, la evidencia es el cuerpo del
método o el test que lo ejercita.

### 3) Tratar el alcance no pedido como un extra
"Ya que estábamos, agregamos el filtro por fecha" es alcance que el cliente no pidió, no firmó y
va a mantener para siempre. Se reporta igual que un requisito faltante.

### 4) Hacer el trabajo del `review_feature`
Tipado, fronteras, nombres (`PY-10`: `snake_case`, `PascalCase`, `UPPER_SNAKE_CASE`, guión bajo
para lo privado del archivo), cobertura y formato no son de esta skill. Si aparece un import que
entra al interior de otro módulo, se anota en una línea y se escala al `Code-Reviewer` —lo bloquea
`backend/tests/architecture/test_module_boundaries.py`, que lee los imports con `ast` y falla
nombrando archivo y línea—; no se convierte el converge en un review.

### 5) Arreglar durante el converge
El `Lead` no edita código ni los artefactos de otros roles. Arreglar sobre la marcha destruye el
hallazgo: nadie vuelve a saber que la spec y el código se habían separado.

### 6) Degradar una deriva mayor para no bloquear
Un requisito firmado sin implementar es deriva mayor aunque sea chico y aunque la fecha apriete.
El estado del gate no se negocia contra el calendario.

### 7) Decidir por el cliente
Concluir "la spec pedía de más, la sacamos" es reescribir el alcance firmado sin el cliente. Se
presentan las dos opciones y decide el humano.

## Troubleshooting

### `spec.md` no tiene requisitos identificables
Sin inventario no hay converge. No inventar los requisitos faltantes: se reporta como hallazgo
del `Solution-Designer` y se frena (`AGENTS.md` → "Enforcement").

### No existe `plan.md` o `tasks.md`
La cadena se salteó un paso. Se detiene el converge y se escala al humano: no se puede verificar
correspondencia contra artefactos que no se escribieron.

### No se encuentra la implementación de un requisito
Antes de declararlo `Ausente`, buscar por el término de dominio **en inglés** (`quote`,
`favorite`, `symbol`, `interval`) en `backend/app/`, `frontend/src/` y `backend/tests/`.
La documentación está en español y el código no.

### La rama no dice cuál es la feature
Si `git rev-parse --abbrev-ref HEAD` no devuelve `feat/<NNN-feature>` —o no hay repositorio git—,
pedir la feature como argumento y listar `docs/specs/`. No adivinar.

### Un requisito del enunciado no aparece en ninguna spec
Es alcance firmado por el cliente que nadie se comprometió a construir. Se reporta contra
`docs/PROJECT_BRIEF.md` —la tabla de trazabilidad tiene la fila y no tiene test— y vuelve al
`Solution-Designer`, no al Developer.
