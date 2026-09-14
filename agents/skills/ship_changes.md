# Skill — Publicar cambios (flujo de git: commit + push + PR)

Tags: [git] [release]

## Objetivo
Llevar una feature o un bugfix ya testeado y revisado desde el working tree hasta un Pull
Request contra `main`, sin romper el modelo de git del proyecto (`AGENTS.md` → "Flujo de Git").

## Cuándo usarla
- Después de que pasaron los tests y `/review-feature`, para publicar una feature o un bugfix.
- NO para definición de solución ni planificación (no producen código publicable).

## Modelo del repositorio (leer primero)
Un solo producto, un solo remoto (`origin`), un solo flujo:
- `main` es la rama **estable y desplegable**.
- El trabajo se hace en ramas de feature creadas desde `main`.
- Todo entra a `main` por Pull Request.

## Reglas (ESTRICTO)
- **Nunca commitear directo a `main`.**
- **Un commit, un propósito.** Si el changeset mezcla cosas sin relación, separarlo en varios
  commits.
- **Push y PR son hacia afuera → SIEMPRE confirmar con el usuario** antes de pushear y antes de
  abrir el PR.
- **Mensajes de commit**: estilo Conventional Commits (`feat(...)`, `fix(...)`, `chore(...)`),
  en imperativo, en **inglés**, derivados de la spec o del bug. **No agregar trailer
  `Co-Authored-By`.**
- No hacer force-push. No tocar cambios ajenos a la feature.

## Convención de ramas
- `feat/<NNN-feature>` — feature nueva (el `NNN` es el de `docs/specs/<NNN-feature>/`)
- `fix/<descripcion>` — corrección
- `chore/<descripcion>` — mantenimiento, dependencias, tooling

## Precondiciones (verificarlas antes de tocar git)

- La suite pasa: `cd backend && uv run pytest`.
- `review_feature` dio **aprobado**, y `converge` no dejó deriva mayor.
- No se está en `main` (`GIT-01` es **Blocker**). Si se está, se crea la rama antes de commitear:
  `git checkout -b feat/<NNN-feature>`.

## Pasos (ORDEN OBLIGATORIO)

### 1) Inspeccionar el working tree
- `git status --porcelain` y `git diff --stat` para listar los cambios. Si no hay nada para
  commitear → DETENERSE.
- Confirmar con el usuario que los tests y `/review-feature` ya pasaron: esta skill asume un
  estado revisado, no vuelve a revisar.

### 2) Verificar la rama
- `git rev-parse --abbrev-ref HEAD`.
- Si la rama actual es `main` → crear la rama de feature antes de commitear:
  ```bash
  git switch -c feat/<NNN-feature>
  ```
- Si el HEAD está detachado o la rama no corresponde a la feature → detenerse y preguntar.

### 3) Stagear y commitear
- Stagear sólo los archivos que pertenecen a la feature (revisar que no se cuelen archivos
  temporales, `.env`, exports de diagramas ni artefactos de build).
- Verificar que, si hubo cambios de dependencias, estén commiteados juntos `pyproject.toml` +
  `uv.lock` (backend) o `package.json` + `package-lock.json` (frontend).
- Verificar que los cambios de modelos vayan junto con su migración de Alembic.
- Completar la **columna Test** de la tabla de trazabilidad de `docs/PROJECT_BRIEF.md` para cada
  `REQ-NN` que esta feature cubre, con la ruta del test que lo verifica, y stagearla junto con la
  feature.
- Armar el mensaje Conventional a partir de la feature o del bug (el scope es el área:
  `feat(quotes): ...`).
- Commitear. **Sin trailer `Co-Authored-By`.**

```
| REQ-02 | Credenciales inválidas muestran … | pág. 2 | `tests/integration/test_auth.py::test_invalid_credentials` |
```

La columna va en el commit de la feature, y no en el del archivado, porque registra **qué test
verifica el requisito**: eso ya es verdad cuando el test corre en verde, no cuando el código sale a
producción. Si esperara al deploy, el PR se mergearía con la tabla diciendo que algo sigue pendiente
cuando ya está hecho, y el evaluador leería eso. Es lo único del brief que se actualiza acá; el
resto es el acuerdo firmado y no se toca.

### 4) Pushear (confirmar antes)
- Mostrarle al usuario la rama destino y el commit. **Pedir confirmación.**
- Con la confirmación:
  ```bash
  git push -u origin <rama>
  ```

### 5) Abrir el Pull Request (confirmar antes)
- Base `main`, head la rama de feature:
  ```bash
  gh pr create --base main --head <rama>
  ```
- Generar un título y un cuerpo claros: resumen, qué cambió, estado de tests y review, y el
  link a `docs/specs/<NNN-feature>/spec.md` si existe.
- **Pedir confirmación antes de crear el PR.**
- Reportar la URL del PR.

### 6) Archivar la spec (después del deploy)

**Decisión humana (2026-09-13): la spec se archiva después del deploy, no después del merge.**
`docs/specs/archive/` significa *"está en producción"*, y mover la carpeta apenas se mergea el PR
convierte esa lectura en una promesa: quien abre `docs/specs/` deja de poder leer la lista como
"esto es lo que todavía no está desplegado".

Una vez que el PR está mergeado a `main` **y el cambio salió a producción**, mover la carpeta de la
feature a `docs/specs/archive/`:

```bash
git mv docs/specs/<NNN-feature> docs/specs/archive/<NNN-feature>
```

Es un changeset propio y posterior al PR de la feature, así que entra por donde entra todo: rama
desde `main` (`chore/archive-<NNN-feature>`), commit `docs(specs): ...` y PR. Nunca directo a
`main` (`GIT-01`).

Sin este paso el árbol de specs crece sin límite y deja de distinguir lo que está por
construirse de lo que ya está en producción. El número **no se reutiliza**: la próxima feature
toma el siguiente al mayor entre las activas y las archivadas. Convención completa en
`docs/specs/archive/README.md`.

La columna **Test** del brief **no viaja acá**: ya se completó en el commit de la feature (paso 3).
Lo que garantiza que la tabla no quede vieja deja de ser el "mismo commit" y pasa a ser la
*Definition of Done* de `AGENTS.md`, que la exige completa y frena el merge — un gate, y no una
convención sobre dónde cae el diff.

## Validación
- El commit quedó en una rama de feature, nunca directo en `main`.
- El commit incluye migraciones y lockfiles cuando corresponde.
- El push y el PR ocurrieron sólo después de la confirmación explícita del usuario.
- El mensaje de commit es Conventional, en inglés, y no tiene trailer `Co-Authored-By`.
- El PR está abierto contra `main` y tiene una descripción útil.
- La columna **Test** del brief quedó completa —en el commit de la feature, antes del merge— para
  los requisitos que esta feature cubre.
- Después del **deploy**, y no del merge, la spec de la feature quedó movida a
  `docs/specs/archive/` en su propio changeset.
- El *Estado de los doce problemas* del brief refleja lo que esta feature resolvió.

## Errores comunes (evitar)
- Commitear directo a `main`.
- Mezclar en un commit cambios sin relación entre sí.
- Pushear o abrir el PR sin confirmación.
- Commitear el modelo sin su migración, o la dependencia sin el lockfile.
- Commitear `.env`, fixtures pesadas innecesarias o exports de diagramas (van gitignorados).
- Agregar el trailer `Co-Authored-By`.
- Archivar la spec apenas se mergea el PR, sin esperar al deploy.
- Dejar la columna **Test** del brief para el commit del archivado: el PR de la feature se
  mergearía con la tabla incompleta.
- Hacer force-push para "acomodar" la rama.

## Troubleshooting
- La rama no tiene upstream → `git push -u origin <rama>`.
- `gh` no está autenticado → reportarlo y detenerse en el paso de push (el commit y el push
  siguen siendo válidos).
- HEAD detachado o rama equivocada → detenerse y preguntar antes de hacer nada.
- Hay conflictos con `main` → rebasear la rama de feature sobre `main` actualizado y volver a
  correr los tests antes de pushear.
