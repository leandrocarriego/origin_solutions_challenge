# Constitución — ORIGIN Acciones

Los principios **no negociables** del proyecto. 
Es la autoridad número uno: cuando este documento y cualquier otro se contradicen gana este.

**Versión** 1.0.0

**Ratificada** 2026-09-12

**Última reforma** 2026-09-12

---

## Artículo I — La credencial del proveedor vive sólo en el backend

Ninguna API key ni secreto va en una variable `VITE_*`, en una respuesta de la API en un log ni en un traceback. 

El frontend **no conoce el dominio del proveedor**: todo pasa por nuestra API.

**Por qué es no negociable:** una variable `VITE_*` no es configuración privada (Vite la reemplaza por su valor literal en el bundle que descarga el navegador, así que configurarla y publicarla son la misma operación).

## Artículo II — La cuota es finita, y eso es parte del diseño

Ninguna consulta llega al proveedor si el dato se puede servir de la base. 

El consumo escala con **símbolos distintos observados**, nunca con clientes conectados: diez usuarios mirando un mismo símbolo cuestan lo mismo que uno.

Y el frontend no dispara jamás una llamada al proveedor: siempre pide a nuestra API, que decide.

**Por qué es no negociable:** los números no dejan margen. El plan gratuito da 800 requests por día y un gráfico a un minuto pide 480 veces en una rueda de ocho horas. 
Y que el consumo escale con símbolos observados y no con clientes conectados es lo que lo vuelve una propiedad de la arquitectura, y no un parámetro que alguien tiene que acordarse de ajustar.

## Artículo III — Los datos de un usuario son de ese usuario

Toda lectura y toda escritura de datos del usuario filtra por el `sub` del token, y **nunca** por
un identificador que venga del path, del query string o del body.

Que el frontend "siempre mande el propio" no es un control de seguridad: el frontend es del
atacante. El repositorio recibe el id del usuario autenticado y no tiene forma de recibir otro.

**Por qué es no negociable:** es API1:2023 — Broken Object Level Authorization (BOLA, el viejo IDOR): el número uno de la OWASP API Security Top 10. La más común, la más fácil de introducir sin darse cuenta y la primera que mira cualquiera que evalúe seguridad.

## Artículo IV — Las fronteras entre módulos son reales o no existen

El backend es un **monolito modular por dominios**. 
Cada módulo es dueño de su router, sus schemas, su lógica, su acceso a datos y sus tablas.

**Un módulo nunca importa el interior de otro.**

La superficie pública de un módulo es su paquete: lo que declara `__all__` en su `__init__.py`, con tipos propios y nunca un modelo del ORM.
Todo lo demás (`service`, `repository`, `models`, `io`) es privado.

La regla tiene dos cláusulas y las dos importan. 

**Afuera** se entra por el paquete: cualquier ruta más profunda es interior ajeno y para el resto del sistema no existe. 

**Adentro** los archivos del módulo se importan entre sí por ruta completa, nunca por el paquete, porque eso reentra al `__init__` a medio inicializar. 

Y `main.py` entra por la misma puerta que todos: el composition root no es una excepción.

Python no tiene visibilidad a nivel de módulo (el guión bajo y `__all__` son convención, no
enforcement), así que la frontera la sostiene el test, no el lenguaje. El enforcement real termina siendo un test en CI.

Adentro de un módulo el flujo va en un solo sentido: `router` → `service` → `repository`. 

Un router no importa SQLAlchemy; un service no importa `fastapi` y comunica fallas con excepciones de dominio que el router traduce a HTTP.

Y cualquier proveedor externo vive detrás de una interfaz, es lo que conoce el service que lo consume, y devuelve tipos propios.

La frontera incluye lo que el test de imports no puede ver: un `relationship()` de SQLAlchemy que cruce módulos acopla sin generar un import, y por eso tampoco se permite.

Esta regla no se sostiene con disciplina ni con revisiones: está **verificada por un test que rompe el build**. 

Cualquier principio de arquitectura que dependa sólo de que alguien lo lea es una aspiración, no una regla.

Si respetar la frontera resulta incómodo, la frontera está mal trazada: se corrige la frontera, nunca la regla. Y cuando resulta imposible, casi siempre significa que los dos módulos son en realidad uno.

**Por qué es no negociable:** es lo que hace que "mantenibilidad, extensibilidad y escalabilidad" sea verificable.

Cómo se aplica la frontera está en `ARCHITECTURE.md`.

## Artículo V — Spec primero, y con firma

Ninguna feature pasa a planificación técnica sin una `spec.md` **aprobada por un humano**. 

La spec es funcional: no lleva decisiones técnicas.

Acá el cliente es el enunciado, y quien firma en su nombre es el humano del proyecto.

Al terminar, el código se verifica contra lo que se firmó (`/converge`), no sólo contra su propia calidad. 

Si el código y la spec no describen el mismo producto, la decisión de qué corregir (el
código o la spec) **es del humano, no del agente**.

**Por qué es no negociable:** es el único mecanismo que impide que el resultado del desarrollo sea diferente de lo que se pidió.

## Artículo VI — Lo que no está tipado y testeado no está terminado

Todo el código lleva tipos completos y pasa sus chequeos. 

La lógica de negocio tiene tests unitarios; los endpoints y la base, tests de integración; el proveedor se testea contra **JSON fijado**, nunca contra la API del proveedor en vivo.

Un test **nunca** se debilita para pasar un gate. 

Si un test molesta, o el código está mal o el test está mal: las dos cosas se arreglan, ninguna se silencia.

Cada test desarrollado por el agente debe ser aprovado por el humano **sin excepcion** antes de pasar al desarrollo de la implementacion.

**Por qué es no negociable:** además de lo obvio, una suite que sale a la red consume la cuota del
Artículo II. La suite completa corre sin red y sin API key, o no es una suite.

## Artículo VII — El enunciado es el contrato, y sus ambigüedades se declaran

Lo que el enunciado pide se entrega tal como lo pide, textos literales incluidos. 

Lo que el enunciado **no** define se resuelve, pero la decisión se escribe donde se pueda leer (`docs/PROJECT_BRIEF.md` → *Ambigüedades*), con su alternativa descartada.

Lo que el enunciado no pide no se construye.

**Por qué es no negociable:** se debe evalúar la **atención a los requerimientos**.

## Artículo VIII — Un idioma para cada audiencia

La documentación va en **español**, porque se lee y se discute con el evaluador. 

El código va en **inglés**. 

Los strings que ve el usuario, en **español**.

**Por qué es no negociable:** la spec es un documento contractual. Un documento que el cliente no
puede leer no puede ser firmado por el cliente.

## Artículo IX — Las dependencias entran por la puerta

Backend con `uv`, frontend con `npm`, y siempre con su lockfile actualizado en el mismo commit.

Se prohibe `pip install`, `requirements.txt` y edición a mano de versiones.

**Por qué es no negociable:** un build que no es reproducible no es verificable, y todo lo demás que
dice esta constitución depende de poder verificar.

## Artículo X — Las decisiones de arquitectura las toma un humano

`docs/DECISIONS.md` registra decisiones, y una decisión la toma una persona. 
Todo lo que entra a ese archivo requiere un acto explícito de un humano: o pidió ese ADR específicamente, o confirmó una propuesta que el agente le planteó en la conversación.

Un agente **nunca agrega un ADR por iniciativa propia**, ni siquiera marcado como `Propuesta`. 
Y **nunca** escribe `Aceptada` ni completa *Decidida por*.

Un ADR en `Propuesta` no es autoridad: ningún `plan.md` lo puede citar para justificar un enfoque.

**Por qué es no negociable:** es un proceso donde la mayor parte del trabajo la hacen agentes. 
Un ADR es el registro de un juicio con consecuencias, y el humano a cargo debe **defender
cada decisión de arquitectura que tomo**, y una decisión que no tomó no la puede defender.

---

## Constitution Check

Todo `plan.md` se valida contra esta constitución antes de pasar a `/tasks`. 

El plan declara explícitamente:

- Que ningún artículo resulta violado por el enfoque elegido.

- Si algún artículo **parece** exigir una excepción: cuál, por qué, y qué alternativa se descartó. 

Una excepción a esta constitución no la aprueba un agente: la aprueba el humano, y queda registrada en el plan.

Un plan que no pasa el Constitution Check no avanza, aunque sea técnicamente correcto.

## Reforma

Esta constitución se modifica sólo con decisión humana explícita, y el cambio incluye:

1. Actualizar la versión y la fecha de este documento.
2. Revisar `ARCHITECTURE.md`, `AGENTS.md` y `CONVENTIONS.md` para que no la contradigan.
3. Cuando el artículo sea verificable por una prueba automática, actualizar o crear el test que lo verifica.

## Versionado

`MAJOR`: se elimina o se redefine un artículo.

`MINOR`: se agrega un artículo o una obligación material.

`PATCH`: redacción, ejemplos, aclaraciones que no cambian el alcance.

## Dónde vive este documento

En la raíz, junto al resto de la gobernanza, y lo carga `AGENTS.md` con un import para que esté siempre en contexto. 
