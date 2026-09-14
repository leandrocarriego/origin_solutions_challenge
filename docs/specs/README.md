# Specs

Una carpeta por feature, numerada y correlativa: `docs/specs/<NNN-feature>/`.

## El árbol

```
docs/specs/
├── spec.template.md     ← plantilla, cara al cliente
├── plan.template.md     ← plantilla, con Constitution Check
├── tasks.template.md    ← plantilla, con cobertura de requisitos
├── 002-favorite-stocks/
├── 003-quote-chart/
└── archive/             ← las entregadas; su número no se reutiliza nunca
    ├── 000-scaffolding/  ← la fase 0, ya cerrada: sólo tasks.md (ver abajo)
    └── 001-authentication/
```

## Nombre

`NNN-<short-name>`, kebab-case, **en inglés**: es un identificador técnico y la rama lo hereda tal
cual (`feat/001-authentication`). El **contenido** de todos los artefactos va en español
(`CONSTITUTION.md`, Artículo VIII).

El número es el siguiente al mayor entre `docs/specs/` y `docs/specs/archive/`. Un número no se
reutiliza, ni siquiera si la feature se canceló.

## Los artefactos

| Archivo | Quién lo escribe | Para qué |
|---|---|---|
| `spec.md` | Solution-Designer | Qué hace la feature y para quién. **El único artefacto cara al cliente**: no lleva decisiones técnicas. |
| `plan.md` | Backend/Frontend-Architect | El enfoque técnico, con Constitution Check y **Contexto de traspaso**. |
| `tasks.md` | Backend/Frontend-Architect | El desglose, con la cobertura de cada requisito. |
| `research.md` | Architect | Sólo si la investigación previa es larga. |
| `data-model.md` | Architect | Sólo si el modelo de datos no entra cómodo en el plan. |
| `contracts/` | Architect | Los contratos de API, si hacen falta explicitados. |
| `checklists/` | Solution-Designer | Verificaciones cara al cliente. |

Los cuatro últimos son opcionales: existen cuando el `plan.md` quedaría ilegible sin ellos, no por
defecto.

## La excepción: `000-scaffolding`

La fase 0 es andamiaje, no una feature: no tiene alcance que el cliente firme, y por eso no tiene
`spec.md` ni `plan.md`. Su carpeta lleva **sólo `tasks.md`**.

Existe igual porque el Artículo VI no admite excepciones: la firma de los tests se registra en un
`tasks.md` (`agents/skills/approve_tests.md`, paso 7), y sin la carpeta la fase 0 no tendría dónde
registrarla.

Lo que en una feature aporta la spec firmada, acá lo aportan `docs/ROADMAP.md` → *Fase 0* y los
ADR **aceptados** de `docs/DECISIONS.md`. El porqué completo está en el propio archivo.

## El flujo

```
/specify  →  /clarify  →  /approve-spec  →  /plan  →  /tasks  →  /analyze  →  /implement
            (si hay preguntas)   ✍️ GATE                                   →  /converge
                                                                           →  /review-feature  🚦 GATE
                                                                           →  /ship
```

Dos reglas que no son negociables:

- **No se planifica sobre una spec en `Borrador`.** Planificar antes de la firma resuelve un
  alcance que nadie acordó, y el gate deja de serlo (Artículo V).
- **Una spec con `[NECESITA ACLARACIÓN: …]` no se firma.** Primero `/clarify`. Es preferible una
  spec con tres preguntas abiertas que una con tres invenciones que alguien firma sin notarlas.

## Trazabilidad

Cada requisito funcional de una spec (`RF-01`, `RF-02`, …) se conecta hacia arriba con un requisito
del enunciado (`REQ-01`, … en `docs/PROJECT_BRIEF.md`) y hacia abajo con al menos una tarea y un
test. `/analyze` verifica que la cadena no tenga huecos; `/converge` verifica que el código haga lo
que la cadena promete.

## Al entregar

La carpeta pasa a `archive/` y, en el **mismo commit**, se completa la columna **Test** de la tabla
de trazabilidad del brief (`ship_changes`). Si se separan, la tabla queda vieja y el evaluador lee
que algo sigue pendiente cuando ya está hecho.
