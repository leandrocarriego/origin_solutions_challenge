# Skill — Registrar la aprobación humana de los tests de una feature

Tags: [tests] [sdd] [gate]

Rol dueño: **Tester**.

## Objetivo
Registrar la aprobación del humano sobre los tests de una feature y habilitar la implementación.

## Cuándo usarla
- Cuando los tests de la feature están escritos y **todavía no existe el código que los hace
  pasar**. **Es un gate**: sin esto no arranca `implement` (`CONSTITUTION.md`, Artículo VI).

## Precondiciones
- Existe `tasks.md` con la tarea de tests cerrada y las de implementación abiertas.
- El `plan.md` fija la interfaz que los tests ejercitan —módulos, services, firmas y endpoints—.
  Sin eso el test no se puede escribir contra nada: se vuelve a `plan`, no se inventa la firma.
- Los tests corren y **fallan** por la razón correcta: falta la implementación, no un import roto
  ni un fixture mal armado. Un test que falla por error de sintaxis no describe ningún
  comportamiento.
- La suite corre sin red y sin API key (`TEST-03`).

## Reglas (ESTRICTO)
- **No se aprueba en nombre del humano.** La aprobación es de una persona; esta skill sólo la
  registra. Es el mismo principio del Artículo X para los ADR.
- **No se aprueban tests contra código que ya existe.** Si la implementación está escrita, el gate
  ya se salteó: se informa y se decide qué hacer, no se firma para regularizar.
- **Un test aprobado no se reescribe después para que pase** (Artículo VI). Si durante
  `implement` un test resulta equivocado, se vuelve acá con el cambio y se firma de nuevo.
- La fecha se pide, no se inventa.

## Pasos (ORDEN OBLIGATORIO)
1. Correr la suite y verificar que los tests nuevos **fallan porque falta la implementación**.
   Adjuntar la salida: es la evidencia de que describen algo que todavía no existe.
2. Revisar que cada test nombre un comportamiento del `spec.md` firmado y no un detalle interno:
   un test que sólo puede escribirse mirando la implementación no es un contrato, es un espejo.
3. Verificar la cobertura de la historia contra `tasks.md`: cada criterio de aceptación tiene su
   test, y cada test se puede rastrear a un criterio.
4. Si algo de lo anterior falla, **no registrar la aprobación**: informar qué falta.
5. Presentar los tests **uno por uno**, en orden, y **con el código de cada uno a la vista**. No
   una tabla resumen, no una lista de títulos: el código, porque el contrato es el código y lo que
   se firma es eso. Por cada test:
   - el código completo, tal como está escrito;
   - qué comportamiento fija, en una frase;
   - **contra qué criterio de aceptación del `spec.md` responde**;
   - si hoy pasa en verde sin implementación —porque asserta algo que un 404 ya cumple—, decirlo:
     es un test que todavía no prueba nada y el humano tiene que saberlo antes de firmar.

   Nada de resumir para ahorrar espacio. Un humano no puede aprobar lo que no leyó, y un test
   aprobado sin leer es exactamente el escenario que el Artículo VI existe para evitar.
6. **Esperar la respuesta.** No continuar mientras no haya una respuesta explícita, y no
   interpretar el silencio ni un "dale" genérico como aprobación de los tests que no se miraron.
7. Registrar en el encabezado de `tasks.md`: `Tests aprobados por: <quien aprueba>` y
   `Fecha de aprobación: <YYYY-MM-DD>`.

## Validación
- [ ] La suite corrió y los tests nuevos fallan por ausencia de implementación.
- [ ] **Se mostró el código de cada test, uno por uno**, y se señalaron los que hoy pasan vacuamente.
- [ ] Cada criterio de aceptación de la historia tiene su test.
- [ ] `tasks.md` tiene quién aprobó y cuándo.
- [ ] Se confirmó cuál es el paso siguiente (`implement`).

## Errores comunes (evitar)
- Registrar la aprobación para "destrabar" al Developer cuando el humano todavía no los vio.
- Aprobar tests que pasan en verde: si pasan sin implementación, no están probando nada.
- Escribir los tests mirando una implementación que ya existe y firmarlos como si fueran previos.
