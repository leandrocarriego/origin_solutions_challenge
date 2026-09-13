# Skill — Implementar una feature desde sus tareas

Tags: [implementación] [sdd]

Rol dueño: **Developer**.

## Objetivo
Construir la feature ejecutando su `tasks.md`, cada tarea por la skill que tiene asignada.

## Cuándo usarla
- Después de que `analyze` dio **consistente** y de que el humano aprobó los tests
  (`/approve-tests`).
- Nunca antes: implementar sobre documentos inconsistentes multiplica el retrabajo, e implementar
  sobre tests sin firmar saltea un gate de la constitución.

## Precondiciones
- `analyze` dio consistente.
- **Los tests de la historia están escritos, en rojo y aprobados por el humano**, con quién y
  cuándo registrado en `tasks.md` (Artículo VI). Si falta la firma, **se frena acá** y se pide
  `/approve-tests`: no se implementa para "ir adelantando".
- Se trabaja en una rama de feature, nunca en `main` (`GIT-01` es Blocker).

## Reglas (ESTRICTO)
- **El flujo entre capas va en un solo sentido**: `router` → `service` → `repository` (Artículo IV);
  lo verifica `backend/tests/architecture/test_module_boundaries.py`.
- **No se debilita un test para pasar** (`TEST-06`). Si un test molesta, o el código está mal o el
  test está mal: las dos cosas se arreglan, ninguna se silencia.
- **No se amplía el alcance.** Si `tasks.md` es ambiguo o contradice la spec, se frena y se escala
  al `Lead`.
- **No se commitea.** Eso es del `Release-Manager`, con `ship_changes`, y después del quality gate.

## Pasos (ORDEN OBLIGATORIO)
1. Leer el **Contexto de traspaso** del plan antes de tocar nada: dice por dónde empezar, qué no
   tocar y qué decisión ya está tomada.
2. Ejecutar las tareas **en el orden de `tasks.md`**, historia por historia. Al terminar las de H1
   tiene que haber algo que funcione de punta a punta.
3. Para cada tarea, abrir su skill y seguir sus pasos **en orden**, incluida su validación.
   Saltearse una skill existente es un error.
4. **Poner en verde los tests aprobados. No escribir tests nuevos y no tocar los que hay.** Si uno
   resulta equivocado o falta un caso, se frena, se corrige con el `Tester` y **se vuelve a
   firmar** (`/approve-tests`): un test que se reescribe para que pase es exactamente lo que
   prohíbe el Artículo VI.
5. Antes de dar una tarea por terminada, correr lo que la verifica:
   ```bash
   cd backend && uv run ruff format app tests seed.py alembic && uv run ruff check app tests seed.py alembic && uv run mypy app tests seed.py alembic && uv run pytest
   cd frontend && npm run lint && npm run type-check
   ```
6. Marcar en `tasks.md` lo que va quedando hecho.

## Validación
- [ ] La suite pasa y la cobertura no bajó.
- [ ] Los tests de arquitectura siguen en verde.
- [ ] Se informó qué tareas quedaron hechas, cuáles no y por qué.
- [ ] Siguen los tests de sistema del `Tester`, después `converge` y `review_feature`.

## Errores comunes (evitar)
- Marcar una tarea como hecha sin haber corrido su validación.
- Resolver una ambigüedad de `tasks.md` decidiendo por cuenta propia.
