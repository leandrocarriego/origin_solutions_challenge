# Skills — Convención e índice

Las skills son **procedimientos operativos y repetibles** que siguen tanto las personas como
los agentes al trabajar sobre ORIGIN Acciones. Cuando una skill aplica, sus pasos se
siguen en orden y su sección de **Validación** se completa antes de declarar el trabajo hecho
(`AGENTS.md` → *Skills*).

Viven acá, **fuera de `.claude/`**, a propósito: un procedimiento del proyecto no le pertenece a
la herramienta con la que se ejecuta. Los archivos de `.claude/commands/` son punteros de una
línea a estas skills, así que integrar otro proveedor de IA es escribir once punteros en su
formato — no reescribir once procedimientos. Es la misma razón por la que `AGENTS.md` está en la
raíz y `.claude/CLAUDE.md` sólo lo importa.

**Ninguna skill menciona una herramienta ni una variable suya.** Si una skill dice `$ARGUMENTS`,
está acoplada y hay que corregirla.

## Índice de skills

### La cadena de una feature (SDD)

| Skill | Comando | Rol dueño | Para qué |
|---|---|---|---|
| `specify.md` | `/specify` | Solution-Designer | Escribir la spec funcional de una feature nueva |
| `clarify.md` | `/clarify` | Solution-Designer | Resolver las ambigüedades antes de la firma |
| `approve_spec.md` | `/approve-spec` | Solution-Designer | Registrar la firma del cliente (**gate**) |
| `approve_tests.md` | `/approve-tests` | Tester | Registrar la aprobación humana de los tests, antes de implementar (**gate**) |
| `plan.md` | `/plan` | Backend-Arch · Frontend-Arch | Traducir la spec firmada a un plan técnico, con Constitution Check |
| `tasks.md` | `/tasks` | Backend-Arch · Frontend-Arch | Desglosar el plan en tareas, cada una mapeada a una skill |
| `analyze.md` | `/analyze` | Lead | Verificar la consistencia spec ↔ plan ↔ tasks |
| `implement.md` | `/implement` | Developer | Ejecutar las tareas, cada una por su skill |
| `converge.md` | `/converge` | Lead | ¿El código es lo que el cliente firmó? |
| `review_feature.md` | `/review-feature` | Code-Reviewer | Quality gate: ¿está bien escrito? (**gate**) |
| `ship_changes.md` | `/ship` | Release-Manager | Commit + push + PR contra `main`, y archivar la spec |

### Construir

| Skill | Rol dueño | Para qué |
|---|---|---|
| `add_backend_feature.md` | Developer | Agregar una capacidad a un módulo del backend: su router, su service y su repository en `backend/app/modules/<modulo>/` |
| `add_frontend_feature.md` | Developer | Agregar una página o un componente de UI en `frontend/src/` |
| `add_feature.md` | Developer | Feature full-stack: backend + frontend conectados por los tipos de OpenAPI |
| `add_integration.md` | Developer | Tocar la integración con TwelveData: el provider en `app/providers/`, la caché y la cuota |
| `add_database_migration.md` | Developer | Crear y aplicar migraciones de Alembic cuando cambian los modelos de un módulo |
| `add_tests.md` | Tester | Escribir los tests **antes** de la implementación: unitarios, de integración y del provider contra JSON fijado |

### Operar y mantener

| Skill | Comando | Rol dueño | Para qué |
|---|---|---|---|
| `deploy.md` | — | Release-Manager | Desplegar a producción lo que ya está en `main`, verificarlo contra el dominio real y habilitar el archivado de la spec |
| `debug.md` | — | el rol del área afectada | Encontrar la causa raíz de un fallo y corregirla (transversal, cualquier paso) |
| `project_status.md` | `/status` | Lead | Radiografía del estado real del proyecto |

**Toda skill tiene un rol dueño.** Una skill sin dueño está incompleta y no se puede disparar: el
rol es quien responde por su resultado, y está declarado también en la cabecera de cada archivo.

El protocolo de cuándo se dispara una skill y cómo se sigue está en `AGENTS.md` → *Skills*. Este
índice es la fuente de qué skills existen; ese documento, la de cómo se usan.

## Nombres
- Formato: `<verbo>_<objeto>.md`
- `snake_case`, sin prefijos numéricos.
- Ejemplo: `add_backend_feature.md`

## Secciones requeridas (en este orden)
1. Título: `# Skill — <Nombre>`
2. `Tags: [...]` (recomendado)
3. `## Objetivo`
4. `## Cuándo usarla`
5. `## Precondiciones`
6. `## Reglas (ESTRICTO)` *(opcional, si hay restricciones duras)*
7. `## Pasos (ORDEN OBLIGATORIO)`
8. `## Validación`
9. `## Errores comunes (evitar)`
10. `## Troubleshooting`

## Tags sugeridos
`[backend]` `[frontend]` `[feature]` `[database]` `[integracion]` `[proveedor]` `[cuota]`
`[testing]` `[review]` `[release]` `[deploy]` `[specs]` `[debug]`

## Reglas de estilo
- Las skills se escriben en **español**; el código de los ejemplos, en inglés y con la convención
  de nombres del proyecto (`PY-10`): `snake_case` para funciones, variables y argumentos,
  `PascalCase` para clases, `UPPER_SNAKE_CASE` para constantes, y `_` adelante para lo privado del
  archivo (`_DEFAULT_TTL`). Son dos niveles distintos: el guión bajo marca lo privado del archivo;
  `__all__`, lo público hacia otros módulos.
- Los pasos son deterministas y verificables: comandos y rutas explícitas.
- La sección de Validación se escribe con comandos o chequeos concretos, no con adjetivos.
- Evitar lenguaje vago ("debería", "quizás") salvo que no haya alternativa.
- Las rutas y estructuras citadas tienen que existir: monolito modular en `backend/app/modules/`
  (`auth/`, `stocks/`, `favorites/`, `quotes/`), con `shared/` (`db.py`, `errors.py`,
  `security.py`), `providers/`, `settings.py` y `main.py` al lado, y `frontend/src/` (`pages/`,
  `components/`, `backend/`, `auth/`). No se inventan carpetas ni fronteras nuevas: cada pieza de un
  módulo empieza como archivo (`router.py`, `io.py`, `service.py`, `repository.py`, `models.py`) y
  crece a carpeta del mismo nombre cuando hace falta. Hay dos fronteras y las verifica
  `backend/tests/architecture/`: entre módulos, se entra por el paquete del otro y sólo a lo que
  declara su `__all__` (`from app.modules.stocks import get_stocks`) — cualquier ruta más honda es
  interior ajeno; adentro de un módulo, los archivos se importan entre sí por ruta completa
  (`from app.modules.stocks.service import get_stocks`, nunca por `app.modules.stocks`) y el flujo
  va en un solo sentido `router → service → repository`. `get_current_user` no es dominio de
  `auth`: es una primitiva de seguridad y sale de `app.security`, igual que `CurrentUser`.

Para agregar o modificar una skill, seguir la convención de arriba y **darla de alta en el índice
de este archivo**, con su comando si lo tiene y su rol dueño. Una skill que no está en este índice
no se dispara nunca.
