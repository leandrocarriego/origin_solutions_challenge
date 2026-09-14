# Autenticación y sesión — Especificación

<!--
  ESTE ES EL ÚNICO ARTEFACTO CARA AL CLIENTE. Se lee, se discute y se firma con él.
  NO lleva decisiones técnicas: nada de stack, endpoints, schemas, tablas ni rutas
  de archivo. Todo eso va en plan.md.
  Las notas como esta no salen en el PDF: el exportador las descarta.
-->

**Estado:** Aprobado · **Feature:** `001-authentication` · **Fecha:** 2026-09-13

**Aprobada por:** Leandro Carriego · **Fecha de aprobación:** 2026-09-13

> **Enmienda del 2026-09-13 — firmada.** Después de la primera aprobación de ese mismo día, el
> cliente pidió incorporar al alcance el **límite de intentos de ingreso**: se agregaron `RF-21` a
> `RF-26` con sus criterios de aceptación, la regla de negocio que explica por qué es una espera y
> no un bloqueo de cuenta, y el aviso `Demasiados intentos. Probá de nuevo en unos minutos.`
>
> La enmienda fue **firmada por Leandro Carriego el 2026-09-13**, y la aprobación de arriba cubre
> ahora `RF-01` a `RF-26`. Queda registrada acá en vez de reemplazar la línea de aprobación porque
> el alcance cambió después de una firma, y eso es exactamente lo que conviene poder leer después.

> **Segunda enmienda del 2026-09-13 — firmada.** Al construir H1 apareció un caso que
> esta spec no cubría: cuando el sistema no logra comunicarse para validar las credenciales, la
> pantalla de ingreso mostraba `usuario o clave invalida`, porque era el único aviso de falla que
> existía. Es un mensaje que le echa la culpa a la credencial de la persona cuando la falla no es
> suya. **El cliente pidió incorporarlo al alcance** y construirlo dentro de **H2**, que es la
> historia donde se resuelve el manejo de la sesión y sus avisos.
>
> Se agregó `RF-27` con su criterio de aceptación, el aviso `No pudimos conectarnos con el servidor.
> Intentá de nuevo en unos minutos.`, su fila en *Lo que se aparta de los wireframes* y la regla de
> negocio que fija el orden de los cuatro avisos del ingreso.
>
> Fue **firmada por Leandro Carriego el 2026-09-13**, y la aprobación de arriba cubre ahora
> `RF-01` a `RF-27`. Con eso la spec vuelve a `Aprobado` y queda habilitado el ciclo de H2.

## Problema

La aplicación guarda las acciones favoritas **de cada usuario**: la lista de Juan no es la de
Ana. Sin una forma de saber quién está del otro lado, no hay a quién atribuirle una favorita, y
cualquiera que abra la dirección de la aplicación vería —y borraría— las acciones de otro.

Hoy no existe ninguna de las dos cosas: ni la pantalla donde una persona se identifica, ni la
noción de que hay alguien identificado mientras usa la aplicación.

## Objetivo

Que una persona pueda identificarse con su usuario y su clave, entrar a la aplicación, y que
desde ese momento todo lo que ve y hace quede asociado a ella y sólo a ella.

Es la puerta de entrada: las otras dos pantallas del producto (Mis Acciones y el Detalle de
Acción) no tienen sentido sin esto resuelto.

## Actores

| Actor | Qué hace con esta feature |
|---|---|
| **Visitante** | Una persona que todavía no se identificó. Lo único que puede hacer es intentar ingresar. |
| **Usuario** | Una persona ya identificada. Es dueña de sus favoritas, ve su nombre en la cabecera y puede cerrar su sesión. No hay más de un tipo: no existen roles ni permisos diferenciados. |
| **El sistema** | Valida las credenciales, sostiene la sesión mientras dura, avisa cuando se termina y responde siempre lo mismo cuando las credenciales no sirven. |

## Historias de usuario

<!--
  Priorizadas y ENTREGABLES DE FORMA INDEPENDIENTE: si sólo se construye H1, el
  cliente ya tiene algo que usar. Ese corte es lo que permite entregar por partes
  y es la razón de que estén numeradas por prioridad, no por orden narrativo.
-->

### H1 — Entrar a la aplicación *(prioridad más alta)*
Como **visitante**, quiero **identificarme con mi usuario y mi clave**, para **acceder a mis
acciones favoritas**.

**Cómo se prueba que anda:** se abre la aplicación, se cargan el usuario y la clave de uno de los
usuarios de prueba, se aprieta `Ingresar` y aparece la pantalla `Mis Acciones`. Con una clave
equivocada, en cambio, aparece el mensaje `usuario o clave invalida` y la pantalla no cambia.

*Entregable por sí sola:* con sólo H1 el cliente ya puede verificar que las credenciales se
validan y que la aplicación distingue un intento bueno de uno malo.

### H2 — Seguir adentro y saber quién soy
Como **usuario**, quiero **que la aplicación me reconozca mientras la uso y me muestre mi
nombre**, para **saber con qué cuenta estoy trabajando y no tener que identificarme a cada paso**.

**Cómo se prueba que anda:** después de ingresar como Juan, la cabecera dice `Usuario: Juan
Perez`; se recarga la pantalla y se sigue adentro, sin volver a pedir la clave. Pasada una hora
sin identificarse de nuevo, la aplicación vuelve a la pantalla de ingreso y explica por qué.

*Entregable por sí sola:* H2 agrega el reconocimiento sostenido sobre una entrada que H1 ya
resolvió; se puede construir y mostrar después, sin rehacer H1.

### H3 — Cerrar mi sesión
Como **usuario**, quiero **poder terminar mi sesión cuando quiera**, para **que quien use la
misma computadora después de mí no entre a mis acciones**.

**Cómo se prueba que anda:** con la sesión abierta, la cabecera muestra `Cerrar sesión`; al
activarlo aparece la pantalla de ingreso, y volver a la dirección de `Mis Acciones` ya no muestra
la grilla.

*Entregable por sí sola:* H3 no cambia nada de H1 ni de H2; agrega una salida a una sesión que
ya funciona.

## Requisitos funcionales

<!--
  En formato EARS: cada requisito es atómico, sin ambigüedad, y se puede verificar.
  De acá salen los tests, uno a uno. Los cinco patrones:

    Siempre        El sistema debe <respuesta>.
    Ante un evento Cuando <disparador>, el sistema debe <respuesta>.
    Durante un estado  Mientras <estado>, el sistema debe <respuesta>.
    Ante un problema   Si <condición>, entonces el sistema debe <respuesta>.
    Condicional    Donde <la opción esté activada>, el sistema debe <respuesta>.

  Reglas: un requisito por línea, un solo "debe", sin "y/o", sin adjetivos sin
  medida ("rápido", "amigable"). Si no se puede escribir así, todavía no está claro.
  Numerarlos RF-01, RF-02… y no reutilizar números dentro de la feature.
-->

<!--
  La columna Enunciado conecta cada requisito con `docs/PROJECT_BRIEF.md`. Es lo que /analyze
  recorre para verificar que la cadena no tenga huecos. Los que dicen `/clarify` no vienen del
  enunciado: los decidió el cliente el 2026-09-13, y por eso están acá y no en el brief.
-->

| ID | Requisito | Historia | Enunciado |
|----|-----------|----------|-----------|
| RF-01 | El sistema debe presentar una pantalla de ingreso con un campo `Usuario`, un campo `Clave` y un botón `Ingresar`. | H1 | REQ-01 |
| RF-02 | Mientras se escribe en el campo `Clave`, el sistema debe ocultar los caracteres ingresados. | H1 | REQ-01 |
| RF-03 | Cuando el visitante confirma el ingreso con credenciales válidas, el sistema debe llevarlo a la pantalla `Mis Acciones`. | H1 | REQ-03 |
| RF-04 | Si las credenciales no son válidas, entonces el sistema debe mostrar el mensaje `usuario o clave invalida`. | H1 | REQ-02 |
| RF-05 | Si las credenciales no son válidas, entonces el sistema debe dejar al visitante en la pantalla de ingreso. | H1 | REQ-02 |
| RF-06 | Si el usuario ingresado no existe, entonces el sistema debe mostrar el mismo mensaje que cuando la clave es incorrecta. | H1 | REQ-02 |
| RF-07 | El sistema debe reconocer al usuario identificado en cada pantalla que este abra, sin volver a pedirle sus credenciales. | H2 | REQ-03 |
| RF-08 | Mientras haya un usuario identificado, el sistema debe mostrar `Usuario: {nombre completo}` en la cabecera de las pantallas internas. | H2 | REQ-04 |
| RF-09 | Si alguien abre una pantalla interna sin estar identificado, entonces el sistema debe llevarlo a la pantalla de ingreso. | H2 | REQ-03 |
| RF-10 | El sistema debe conservar las claves de manera que no puedan leerse ni recuperarse en texto legible, tampoco por quien acceda a la base de datos. | H1 | NFR-01 |
| RF-11 | El sistema nunca debe devolver la clave de un usuario, ni mostrarla en pantalla fuera del campo donde se la escribe. | H1 | NFR-01 |
| RF-12 | Si el visitante confirma el ingreso con algún campo vacío, entonces el sistema debe mostrar `Completá este campo.` debajo de cada campo que haya quedado vacío. | H1 | `/clarify` |
| RF-13 | Si el visitante confirma el ingreso con algún campo vacío, entonces el sistema debe omitir la validación de las credenciales. | H1 | `/clarify` |
| RF-14 | Cuando el visitante escribe su nombre de usuario, el sistema debe reconocerlo sin distinguir mayúsculas de minúsculas. | H1 | `/clarify` |
| RF-15 | Cuando el visitante escribe su clave, el sistema debe distinguir mayúsculas de minúsculas. | H1 | `/clarify` |
| RF-16 | Mientras no pasen 60 minutos desde que se identificó, el sistema debe mantener al usuario dentro de la aplicación. | H2 | `/clarify` |
| RF-17 | Si la sesión del usuario venció, entonces el sistema debe llevarlo a la pantalla de ingreso mostrando `Tu sesión expiró. Volvé a ingresar.` | H2 | `/clarify` |
| RF-18 | Mientras haya un usuario identificado, el sistema debe mostrar `Cerrar sesión` en la cabecera de las pantallas internas. | H3 | `/clarify` |
| RF-19 | Cuando el usuario activa `Cerrar sesión`, el sistema debe terminar su sesión. | H3 | `/clarify` |
| RF-20 | Cuando el usuario activa `Cerrar sesión`, el sistema debe llevarlo a la pantalla de ingreso. | H3 | `/clarify` |
| RF-21 | Si desde una misma dirección de red se acumulan 10 intentos de ingreso fallidos en 5 minutos, entonces el sistema debe rechazar los intentos siguientes que lleguen desde esa dirección de red hasta que la espera se cumpla. | H1 | `/clarify` |
| RF-22 | Si un mismo nombre de usuario acumula 10 intentos de ingreso fallidos en 5 minutos, entonces el sistema debe rechazar los intentos siguientes que se hagan con ese nombre de usuario hasta que la espera se cumpla. | H1 | `/clarify` |
| RF-23 | Mientras el límite de intentos esté activo, el sistema debe mostrar `Demasiados intentos. Probá de nuevo en unos minutos.` | H1 | `/clarify` |
| RF-24 | Mientras el límite de intentos esté activo, el sistema debe omitir la validación de las credenciales recibidas. | H1 | `/clarify` |
| RF-25 | Cuando un visitante ingresa con credenciales válidas, el sistema debe reiniciar el conteo de intentos fallidos de ese nombre de usuario. | H1 | `/clarify` |
| RF-26 | Cuando un visitante ingresa con credenciales válidas, el sistema debe reiniciar el conteo de intentos fallidos de la dirección de red desde la que ingresó. | H1 | `/clarify` |
| RF-27 | Si al confirmar el ingreso el sistema no logra comunicarse para validar las credenciales, entonces el sistema debe mostrar `No pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.` en lugar de `usuario o clave invalida`. | H2 | `/clarify` |

## Reglas de negocio

<!-- Lo que siempre vale, independientemente del flujo. Si una regla viene de la constitución (la cuota es finita, los datos de un usuario son de ese usuario), nombrala en términos del negocio, no del artículo. -->

- **Hay un solo tipo de usuario.** Ninguna persona tiene más permisos que otra: no hay
  administrador, no hay roles.
- **Los usuarios se cargan con los datos de prueba del proyecto.** La aplicación no ofrece
  registro, ni alta, ni recuperación de clave: el enunciado pide login y nunca alta
  (`docs/PROJECT_BRIEF.md` → A1).
- **Una clave nunca se guarda tal cual se escribió.** Ni en la base, ni en un archivo, ni en un
  registro de actividad.
- **El mensaje de credenciales inválidas es siempre el mismo**, exista o no el usuario: decir
  "ese usuario no existe" le confirmaría a un tercero qué nombres de usuario son reales.
- **El texto del mensaje es literal del enunciado —`usuario o clave invalida`—**, sin la tilde
  que le falta. Se copia tal cual, porque es un texto que el cliente especificó.
- **El nombre de usuario no distingue mayúsculas; la clave sí.** Quien tipea `Juan` entra igual
  que quien tipea `juan`, porque el teclado de un celular pone la primera en mayúscula solo.
  Aflojar lo mismo en la clave le sacaría fuerza.
- **Lo que un usuario ve es lo suyo.** La aplicación toma la identidad de quien ya se identificó,
  nunca de un dato que venga escrito en la pantalla o en la dirección.
- **La cabecera muestra el nombre completo de la persona**, no el usuario con el que ingresa:
  `Usuario: Juan Perez`, no `Usuario: juan`.
- **El límite de intentos es una espera, no una cuenta bloqueada.** La aplicación no ofrece alta ni
  recuperación de clave: una cuenta bloqueada para siempre deja a la persona afuera sin ninguna
  salida, y además le daría a cualquiera la forma de dejar afuera a otro tipeando mal su clave a
  propósito. Por eso el límite se cuenta por tiempo y se levanta solo: pasados unos minutos sin
  intentar, la misma persona vuelve a poder ingresar con su clave correcta, sin que nadie tenga que
  desbloquearla.
- **Los avisos de la pantalla de ingreso son excluyentes, y hay un orden.** Nunca se muestran dos a
  la vez: primero el de campo vacío, que ni siquiera llega a validarse; después el de demasiados
  intentos, que se responde sin mirar la credencial; después el de no haber podido conectarse,
  porque tampoco llegó a validarse nada; y sólo si ninguno de los tres aplica, `usuario o clave
  invalida`, que es el único que afirma algo sobre la credencial de la persona. Un aviso que culpa a
  la credencial cuando la falla es del sistema manda a revisar una clave que estaba bien.

### Lo que se aparta de los wireframes

Son cinco cosas que el enunciado no dibuja ni nombra, y las cinco están aprobadas: el cliente firmó
cuatro el 2026-09-13, con la aprobación original, y ese mismo día pidió la quinta —el aviso de que no
se pudo conectar—, que quedó firmada en la segunda enmienda. Quedan acá para que no se lean como un
descuido cuando alguien compare la pantalla contra el wireframe:

| Qué | Dónde | Por qué |
|---|---|---|
| El enlace `Cerrar sesión` | Cabecera de `Mis Acciones` y del Detalle de Acción, junto a `Usuario: {nombre completo}` | Sin él, una persona no tiene forma de salir en una computadora compartida. |
| `Tu sesión expiró. Volvé a ingresar.` | Pantalla de ingreso, cuando se llega ahí por vencimiento | Volver al login de golpe, sin explicación, se lee como que la aplicación se rompió. |
| `Completá este campo.` | Debajo de cada campo vacío de la pantalla de ingreso | Un campo en blanco es un olvido, no una credencial equivocada, y merece decirlo. |
| `Demasiados intentos. Probá de nuevo en unos minutos.` | Pantalla de ingreso, mientras el límite de intentos está activo | Sin ese aviso, alguien con la clave correcta la tipea bien y no entra, sin explicación. |
| `No pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.` | Pantalla de ingreso, cuando el ingreso no se puede validar porque el sistema no logra comunicarse | Es el único aviso que dice que la falla no es de la persona: sin él, quien tiene la clave bien la ve rechazada y la cambia por nada. |

Los cinco textos son nuevos: no salen del enunciado ni de sus wireframes, y por eso se deciden acá.

## Criterios de aceptación

<!-- Uno por requisito funcional, redactado como algo observable. Es lo que el cliente marca cuando lo ve andando, y lo que /converge contrasta contra el código. -->

- [ ] **RF-01** — Al abrir la aplicación sin haber ingresado, se ve la pantalla con las etiquetas
      `Usuario` y `Clave`, el texto de ayuda `Ingresar nombre de usuario` en el primer campo, y el
      botón `Ingresar`, tal como el wireframe del enunciado.
- [ ] **RF-02** — Al escribir la clave, en pantalla aparecen caracteres enmascarados en lugar de
      las letras tipeadas.
- [ ] **RF-03** — Con el usuario y la clave de un usuario de prueba, apretar `Ingresar` deja a la
      vista la pantalla `Mis Acciones`.
- [ ] **RF-04** — Con una clave equivocada, en la pantalla aparece el texto `usuario o clave
      invalida`, escrito exactamente así.
- [ ] **RF-05** — Después de ese intento fallido se sigue viendo la pantalla de ingreso, con sus
      dos campos y su botón.
- [ ] **RF-06** — Probar con un usuario inventado y probar con un usuario real y clave equivocada
      producen en pantalla el mismo mensaje, palabra por palabra.
- [ ] **RF-07** — Después de ingresar, navegar entre pantallas de la aplicación no vuelve a pedir
      usuario ni clave.
- [ ] **RF-08** — Habiendo ingresado con el usuario de prueba `juan`, arriba a la derecha se lee
      `Usuario: Juan Perez`; con el otro usuario de prueba se lee `Usuario: Ana Gomez`.
- [ ] **RF-09** — Pegar en el navegador la dirección de `Mis Acciones` en una ventana donde nunca
      se ingresó deja a la vista la pantalla de ingreso, no la grilla.
- [ ] **RF-10** — Abriendo directamente la base de datos, la columna donde vive la clave no
      contiene la clave que el usuario escribe al ingresar.
- [ ] **RF-11** — Revisando lo que la aplicación responde al ingresar, no aparece la clave por
      ningún lado.
- [ ] **RF-12** — Apretar `Ingresar` con los dos campos vacíos muestra `Completá este campo.`
      debajo de los dos; con sólo la clave vacía, el aviso aparece únicamente debajo de `Clave`.
- [ ] **RF-13** — En ese intento no aparece `usuario o clave invalida` por ningún lado.
- [ ] **RF-14** — Ingresar escribiendo `JUAN`, `Juan` o `juan` con la clave correcta lleva a
      `Mis Acciones` en los tres casos.
- [ ] **RF-15** — Ingresar con el usuario correcto y la clave escrita en mayúsculas muestra
      `usuario o clave invalida`.
- [ ] **RF-16** — Con la sesión recién abierta, seguir usando la aplicación durante un rato no
      obliga a volver a identificarse.
- [ ] **RF-17** — Una sesión ya vencida deja a la vista la pantalla de ingreso con el texto
      `Tu sesión expiró. Volvé a ingresar.`
- [ ] **RF-18** — Estando adentro, arriba a la derecha se lee `Cerrar sesión`, tanto en
      `Mis Acciones` como en el Detalle de Acción.
- [ ] **RF-19** — Después de activarlo, volver a la dirección de `Mis Acciones` deja a la vista la
      pantalla de ingreso y no la grilla.
- [ ] **RF-20** — Al activarlo, la pantalla que aparece es la de ingreso.
- [ ] **RF-21** — Después de diez intentos fallidos hechos desde la misma computadora en menos de
      cinco minutos, el siguiente intento no entra a la aplicación, ni siquiera probando con otro
      nombre de usuario; pasados cinco minutos sin intentar, la clave correcta vuelve a entrar.
- [ ] **RF-22** — Después de diez intentos fallidos con el usuario de prueba `juan` en menos de
      cinco minutos, el siguiente intento con ese usuario no entra a la aplicación, aunque se haga
      desde otra computadora; pasados cinco minutos sin intentar, vuelve a entrar.
- [ ] **RF-23** — En ese intento, en la pantalla de ingreso aparece el texto `Demasiados intentos.
      Probá de nuevo en unos minutos.`, escrito exactamente así.
- [ ] **RF-24** — En ese intento se ve el mismo aviso se escriba la clave correcta o una
      equivocada, y `usuario o clave invalida` no aparece por ningún lado.
- [ ] **RF-25** — Nueve intentos fallidos con el usuario de prueba `juan`, un ingreso exitoso con
      ese usuario, y nueve intentos fallidos más: el siguiente intento sigue mostrando `usuario o
      clave invalida` y no el aviso de demasiados intentos.
- [ ] **RF-26** — La misma secuencia hecha toda desde la misma computadora, alternando nombres de
      usuario, tampoco llega al límite después del ingreso exitoso.
- [ ] **RF-27** — Con la aplicación sin poder comunicarse —por ejemplo, con la conexión de la
      computadora interrumpida—, apretar `Ingresar` con los dos campos completos muestra `No pudimos
      conectarnos con el servidor. Intentá de nuevo en unos minutos.`, escrito exactamente así, y
      `usuario o clave invalida` no aparece por ningún lado.

## Fuera de alcance

<!-- Lo que alguien podría suponer incluido y no lo está. Esta sección evita discusiones en la entrega. -->

- **Registro de usuarios**, alta desde la aplicación y recuperación o cambio de clave. El
  enunciado describe login y nunca alta (A1).
- **Roles, permisos y administración de usuarios.**
- **Recordarme:** la sesión no sobrevive al cierre del navegador.
- **Renovar la sesión sola** mientras la persona sigue usando la aplicación: a los 60 minutos se
  vuelve a identificar, esté haciendo lo que esté haciendo.
- **Identificarse con una cuenta de un tercero** (Google, GitHub u otros).
- **Segundo factor** y expiración forzada de claves.
- **Bloqueo permanente de la cuenta** por intentos fallidos: ninguna cuenta queda inhabilitada
  hasta que alguien la libere. El límite de intentos **sí** está dentro del alcance (`RF-21` a
  `RF-26`), pero es una espera que se levanta sola.
- **Cerrar la sesión en las otras ventanas** donde la misma persona esté adentro: `Cerrar sesión`
  termina la sesión de donde se lo activa.
- **La pantalla `Mis Acciones` en sí** —la grilla, el autocomplete, el alta y la baja— y el
  **Detalle de Acción**. Acá sólo se define que, al ingresar, se llega a `Mis Acciones` y que su
  cabecera muestra el nombre del usuario y el enlace para salir. El resto es
  `002-favorite-stocks` y `003-quote-chart`.
