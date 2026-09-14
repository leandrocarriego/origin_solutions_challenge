# Skill — Planificar la implementación de una feature

Tags: [specs] [sdd] [arquitectura]

Rol dueño: **Backend-Architect** · **Frontend-Architect**. Si la feature toca las dos puntas, se
cubren ambas y se dice.

## Objetivo
Traducir una spec firmada a un plan técnico: enfoque, módulos afectados, contrato entre módulos,
datos y contratos. Es el artefacto donde viven las decisiones que `spec.md` tiene prohibido llevar.

## Cuándo usarla
- Después de `approve_spec` y antes de `tasks`.
- Cuando una feature ya firmada cambia de enfoque técnico.

## Precondiciones
- **`spec.md` está en `Estado: Aprobado`**, con quién firmó y cuándo. Si está en `Borrador`, se
  frena: planificar antes de la firma resuelve un alcance que el cliente no acordó, y el gate
  deja de serlo (Artículo V).

## Reglas (ESTRICTO)
- **No se amplía el alcance.** Si algo hace falta y no está en la spec firmada, se frena y se
  dice: se vuelve a la spec, no se agrega en el plan.
- **El Constitution Check va primero**, antes de decidir nada. Un plan que no lo pasa no avanza
  aunque sea técnicamente correcto.
- Una excepción a la constitución **la aprueba el humano, no el agente**, y queda registrada con
  qué alternativa se descartó.
- **Un ADR en `Propuesta` no se puede citar** para justificar un enfoque: todavía no lo decidió
  nadie (Artículo X). Si el plan lo necesita, se frena y se le pide al humano que decida.
- Si el plan toma una decisión que da forma al sistema entero, **no se escribe en
  `docs/DECISIONS.md`**: se plantea en la conversación y se espera. Ese archivo sólo recibe lo que
  el humano pidió explícitamente.
- Ninguna biblioteca nueva entra sin justificarse en *Alternativas descartadas*.
- **Los nombres que el plan bautiza siguen `PY-10`**: `snake_case` para funciones, métodos,
  variables y argumentos; `PascalCase` para clases; `UPPER_SNAKE_CASE` para constantes de módulo;
  guión bajo adelante (`_DEFAULT_TTL`) para lo privado del archivo. Nada de `__doble_guión_bajo`
  salvo que el plan escriba la razón. Guión bajo y `__all__` son **dos niveles de privacidad
  distintos**: el guión bajo marca lo privado del ARCHIVO, `__all__` marca lo público hacia OTROS
  MÓDULOS. Un nombre sin guión bajo que no está en `__all__` es interno del módulo: lo ven sus
  hermanos, no el resto del sistema.

## Pasos (ORDEN OBLIGATORIO)
1. Copiar `docs/specs/plan.template.md` a `docs/specs/<NNN-feature>/plan.md`.
2. Completar el **Constitution Check**, artículo por artículo.
3. Escribir el enfoque y los **módulos afectados** —`auth`, `stocks`, `favorites`, `quotes`— y qué
   pieza de cada uno se toca: `router.py`, `io.py`, `service.py`, `repository.py`, `models.py` y el
   `__init__.py` que declara el contrato (y `providers/`, infraestructura al lado de `shared/`), más
   `main.py`, `shared/` —`db.py`, `errors.py`, `security.py`— y web.
4. Definir el **contrato entre módulos**: qué suma esta feature al `__all__` del `__init__.py` de su
   módulo, y qué consume del paquete de otros (Artículo IV). **Afuera se entra por el paquete**
   —`from app.modules.stocks import get_stocks, StockInfo`—; cualquier ruta más profunda
   (`app.modules.stocks.service`) es interior ajeno y para el resto del sistema no existe. **Adentro,
   los archivos del módulo se importan entre sí por ruta completa**
   (`from app.modules.stocks.service import get_stocks`), nunca por `app.modules.stocks`: eso reentra
   al `__init__` a medio inicializar y da un ImportError confuso. Todo lo que entra a un `__all__` es
   superficie que hay que sostener: se justifica o no entra —hoy el inventario completo de lecturas
   cruzadas del backend son dos: `get_stocks` y `StockInfo`, que `favorites` consume de `stocks`, e
   `is_favorite`, que `quotes` consume de `favorites`—. Si la feature necesita el usuario
   autenticado, entra por `from app.security import
   get_current_user, CurrentUser`: es una primitiva de seguridad, no dominio de `auth`. Declarar
   también el flujo interno —`router` → `service` → `repository`— y qué excepción de dominio
   levanta el service cuando falla.
5. Datos y contratos. Toda tabla nueva necesita su migración; toda ruta declara su autorización.
6. Escribir el **Contexto de traspaso**: qué necesita saber el Developer, qué necesita saber el
   Tester, dónde tiene que mirar el Code-Reviewer.
7. Si la investigación previa o el modelo de datos son largos, sacarlos a `research.md` y
   `data-model.md` y dejar el puntero.

## Validación
- [ ] El Constitution Check está completo y toda excepción tiene su justificación.
- [ ] Cada requisito de la spec tiene un lugar en el plan.
- [ ] El plan no introduce alcance que la spec no pide.
- [ ] Cada nombre que el plan agrega a un `__all__` está justificado; lo demás queda interno.
- [ ] El **Contexto de traspaso** existe y dice algo útil, no un placeholder.

## Errores comunes (evitar)
- Empezar a planificar sobre una spec en `Borrador`.
- Saltear una capa —un router que llama a un repository— o resolver con un import entre services
  lo que le toca componer al router (`GEN-02`, `GEN-05`).
- Planear que un módulo entre a otro por adentro (`from app.modules.stocks.service import ...`) en
  vez de por su paquete —o, al revés, que un archivo se importe a un hermano vía `app.modules.stocks`
  en vez de por ruta completa.
- Poner en el `__all__` algo que usan sus hermanos y nadie más: eso es interno del módulo.
