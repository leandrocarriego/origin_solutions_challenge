# Mis Acciones favoritas — Especificación

<!--
  ESTE ES EL ÚNICO ARTEFACTO CARA AL CLIENTE. Se lee, se discute y se firma con él.
  NO lleva decisiones técnicas: nada de stack, endpoints, schemas, tablas ni rutas
  de archivo. Todo eso va en plan.md.
  Las notas como esta no salen en el PDF: el exportador las descarta.
-->

**Estado:** Aprobado · **Feature:** `002-favorite-stocks` · **Fecha:** 2026-09-13

**Aprobada por:** Leandro Carriego · **Fecha de aprobación:** 2026-09-13

## Problema

Una persona ya puede identificarse y entrar a la aplicación (`001-authentication`), pero cuando
llega no hay nada adentro: la pantalla `Mis Acciones` existe sólo como destino del ingreso.

Quien invierte sigue tres o cuatro acciones, no siete mil. Hoy no tiene dónde anotarlas: cada vez
que quiere mirar una cotización tiene que acordarse del símbolo exacto y escribirlo de memoria, y
lo que arma en una sesión se pierde cuando se va. Tampoco hay forma de buscar una acción por su
nombre cuando el símbolo no se recuerda — `Netflix` no se escribe `NFLX` por ninguna regla obvia.

## Objetivo

Que cada usuario arme y mantenga su propia lista de acciones a seguir: que busque una acción por
su símbolo o por su nombre, la agregue a su lista, la quite cuando deja de interesarle, y la
encuentre igual la próxima vez que entre.

Es la pantalla que hace de índice del producto: desde su lista, el usuario elige de qué acción
quiere ver el gráfico.

## Actores

| Actor | Qué hace con esta feature |
|---|---|
| **Usuario** | Una persona ya identificada. Busca acciones, arma su lista, la mira y la modifica. Es dueño de su lista: no ve ni toca la de nadie más. |
| **El sistema** | Ofrece las acciones disponibles para buscar, guarda la lista de cada usuario, la muestra actualizada y mantiene al día el listado de acciones que ofrece. |

No hay un segundo tipo de usuario: no existen roles, ni administrador del listado de acciones.

## Historias de usuario

<!--
  Priorizadas y ENTREGABLES DE FORMA INDEPENDIENTE: si sólo se construye H1, el
  cliente ya tiene algo que usar. Ese corte es lo que permite entregar por partes
  y es la razón de que estén numeradas por prioridad, no por orden narrativo.
-->

### H1 — Ver mis acciones *(prioridad más alta)*
Como **usuario**, quiero **ver la lista de las acciones que sigo, con su símbolo, su nombre y su
moneda**, para **tener juntas de un vistazo las que me interesan**.

**Cómo se prueba que anda:** se ingresa con el usuario de prueba `juan` y en `Mis Acciones`
aparece una grilla con `TSLA`, `AAPL` y `NFLX`, cada una con su nombre y su moneda. Se cierra
sesión, se ingresa con el otro usuario de prueba y la grilla que aparece es otra.

*Entregable por sí sola:* con los datos de prueba que el proyecto ya carga, H1 sola muestra la
pantalla del wireframe andando y demuestra que la lista es de cada usuario.

### H2 — Agregar una acción a mi lista
Como **usuario**, quiero **buscar una acción escribiendo parte de su símbolo o de su nombre y
agregarla a mi lista**, para **empezar a seguirla sin tener que acordarme del símbolo exacto**.

**Cómo se prueba que anda:** se escribe `micro` en el campo `Símbolo`, aparecen sugerencias entre
las que está `MSFT — Microsoft Corp`, se la elige, se aprieta `Agregar Símbolo` y la acción
aparece en la grilla sin recargar la página. Se sale y se vuelve a entrar: sigue ahí.

*Entregable por sí sola:* H2 agrega el alta sobre la grilla que H1 ya muestra; no cambia nada de
lo que H1 resolvió.

### H3 — Sacar una acción de mi lista
Como **usuario**, quiero **quitar de mi lista una acción que ya no sigo**, para **que la pantalla
muestre sólo lo que me importa hoy**.

**Cómo se prueba que anda:** en la fila de `NFLX` se activa `Eliminar`, se confirma, y la fila
desaparece de la grilla sin recargar la página. Se vuelve a entrar más tarde y sigue sin estar; la
acción se puede volver a agregar buscándola de nuevo.

*Entregable por sí sola:* H3 es la operación inversa de H2 y no depende de ella: se puede quitar
cualquiera de las acciones que los datos de prueba ya dejaron cargadas.

### H4 — Llegar al detalle de una acción
Como **usuario**, quiero **entrar al detalle de una acción desde mi lista**, para **ver su
gráfico sin tener que buscarla de nuevo**.

**Cómo se prueba que anda:** en la grilla, el símbolo `TSLA` se ve como un enlace; al activarlo,
la aplicación va a la pantalla de Detalle de Acción de `TSLA`.

*Entregable por sí sola:* H4 sólo agrega la salida hacia la otra pantalla. Se puede construir y
verificar aunque el gráfico todavía no exista: lo que esta feature promete es llegar al detalle
de la acción correcta, no lo que ese detalle muestra.

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
| RF-01 | El sistema debe mostrar en la pantalla `Mis Acciones` una grilla con las acciones favoritas del usuario identificado. | H1 | REQ-08 |
| RF-02 | El sistema debe mostrar en la grilla las columnas `Símbolo`, `Nombre` y `Moneda`, más una cuarta columna sin encabezado. | H1 | REQ-08 |
| RF-03 | El sistema debe mostrar en cada fila de la grilla el símbolo, el nombre y la moneda de esa acción. | H1 | REQ-08 |
| RF-04 | El sistema debe mostrar en la grilla únicamente las acciones favoritas del usuario identificado. | H1 | NFR-03 |
| RF-05 | El sistema debe conservar las acciones favoritas de un usuario entre una sesión y la siguiente. | H1 | REQ-08 |
| RF-06 | El sistema debe ordenar las filas de la grilla de la acción agregada más recientemente a la agregada hace más tiempo. | H1 | `/clarify` |
| RF-07 | Si el usuario no tiene ninguna acción favorita, entonces el sistema debe mostrar los encabezados de la grilla y el texto `Todavía no agregaste ninguna acción.` en lugar de las filas. | H1 | `/clarify` |
| RF-08 | Cuando el usuario escribe en el campo `Símbolo`, el sistema debe sugerir las acciones cuyo símbolo contenga el texto escrito. | H2 | REQ-05 |
| RF-09 | Cuando el usuario escribe en el campo `Símbolo`, el sistema debe sugerir también las acciones cuyo nombre contenga el texto escrito. | H2 | REQ-05 |
| RF-10 | Cuando el usuario escribe en el campo `Símbolo`, el sistema debe buscar las coincidencias sin distinguir mayúsculas de minúsculas. | H2 | REQ-05 |
| RF-11 | El sistema debe mostrar como máximo 20 sugerencias por búsqueda. | H2 | REQ-05 |
| RF-12 | El sistema debe excluir de las sugerencias las acciones que dejaron de cotizar. | H2 | REQ-05 |
| RF-13 | Mientras el texto escrito tenga menos de 2 caracteres, el sistema no debe mostrar sugerencias. | H2 | `/clarify` |
| RF-14 | Si ninguna acción coincide con el texto escrito, entonces el sistema debe mostrar el texto `No se encontró ninguna acción con ese texto.` en lugar de las sugerencias. | H2 | `/clarify` |
| RF-15 | Cuando el usuario selecciona una sugerencia y activa `Agregar Símbolo`, el sistema debe agregar esa acción a las favoritas del usuario identificado. | H2 | REQ-06 |
| RF-16 | Cuando el sistema agrega una acción a las favoritas, debe mostrarla en la grilla sin que el usuario recargue la página. | H2 | REQ-07 |
| RF-17 | El sistema debe guardar de cada acción agregada su símbolo, su nombre y su moneda. | H2 | REQ-08 |
| RF-18 | Si la acción seleccionada ya está entre las favoritas del usuario, entonces el sistema debe dejar la lista sin cambios, sin agregar una segunda fila. | H2 | REQ-06 |
| RF-19 | Si la acción seleccionada ya está entre las favoritas del usuario, entonces el sistema debe mostrar el aviso `Esa acción ya está en tu lista.` | H2 | `/clarify` |
| RF-20 | Si el usuario activa `Agregar Símbolo` sin haber seleccionado una acción de las sugerencias, entonces el sistema no debe agregar ninguna acción a sus favoritas. | H2 | `/clarify` |
| RF-21 | Si el usuario confirma el alta sin haber seleccionado una acción de las sugerencias, entonces el sistema debe mostrar el aviso `Elegí una acción de las sugerencias.` | H2 | `/clarify` |
| RF-22 | Cuando un usuario agrega una acción a sus favoritas, el sistema no debe modificar las favoritas de ningún otro usuario. | H2 | NFR-03 |
| RF-23 | El sistema debe mostrar en cada fila de la grilla el enlace `Eliminar`. | H3 | REQ-09 |
| RF-24 | Cuando el usuario confirma la eliminación, el sistema debe quitar esa acción de las favoritas del usuario identificado. | H3 | REQ-09 |
| RF-25 | Cuando el usuario activa `Eliminar` en una fila, el sistema debe pedir una confirmación con el texto `¿Quitar {símbolo} de tus acciones?` antes de quitar la acción. | H3 | `/clarify` |
| RF-26 | Cuando el sistema quita una acción de las favoritas, debe dejar de mostrarla en la grilla sin que el usuario recargue la página. | H3 | REQ-10 |
| RF-27 | Cuando el usuario quita una acción de sus favoritas, el sistema debe seguir ofreciéndola entre las sugerencias. | H3 | REQ-09 |
| RF-28 | Si un usuario intenta quitar una acción que no está entre sus favoritas, entonces el sistema no debe modificar las favoritas de ningún otro usuario. | H3 | NFR-03 |
| RF-29 | El sistema debe mostrar el símbolo de cada fila de la grilla como un enlace. | H4 | REQ-11 |
| RF-30 | Cuando el usuario activa el enlace de un símbolo, el sistema debe llevarlo al Detalle de Acción de esa misma acción. | H4 | REQ-11 |
| RF-31 | Mientras no haya una sugerencia seleccionada, el sistema debe mostrar el botón `Agregar Símbolo` deshabilitado. | H2 | `/clarify` |
| RF-32 | Si el usuario cancela la confirmación de la eliminación, entonces el sistema debe dejar esa acción entre sus favoritas. | H3 | `/clarify` |

## Reglas de negocio

<!-- Lo que siempre vale, independientemente del flujo. Si una regla viene de la constitución (la cuota es finita, los datos de un usuario son de ese usuario), nombrala en términos del negocio, no del artículo. -->

- **La lista es de cada usuario.** Un usuario no ve, no agrega ni quita nada de la lista de otro,
  ni siquiera si conoce su nombre de usuario. La aplicación toma la identidad de quien ya se
  identificó, nunca de un dato que venga escrito en la pantalla o en la dirección.
- **Sólo se agregan acciones del listado que la aplicación ofrece.** No se escribe un símbolo a
  mano: se elige una de las sugerencias. Lo que no está en el listado no se puede agregar.
- **El listado cubre NYSE y NASDAQ.** El enunciado nombra NYSE, pero las tres acciones de su
  propio wireframe cotizan en NASDAQ: se ofrecen los dos mercados para que la pantalla del
  enunciado se pueda reproducir (`docs/PROJECT_BRIEF.md` → A4).
- **Buscar una acción no consume cuota del proveedor de datos.** Las sugerencias salen de un
  listado que la aplicación mantiene por su cuenta, y se refresca solo. Tipear rápido no le cuesta
  al proyecto ni le quita capacidad al gráfico de otro usuario (A3).
- **Una acción que deja de cotizar deja de sugerirse, pero no desaparece de la lista de quien ya
  la tenía**: se sigue viendo con su símbolo, su nombre y su moneda.
- **La misma acción no se repite en la lista de un usuario.** Agregar dos veces la misma acción
  deja la lista igual que agregarla una sola vez.
- **Quitar una acción de una lista no la saca del listado de la aplicación**, ni la quita de la
  lista de otro usuario que también la siga. Se puede volver a agregar cuando se quiera.
- **La grilla muestra símbolo, nombre y moneda, y nada más.** No muestra la cotización: el precio
  vive en el Detalle de Acción.
- **Los textos de la pantalla son los del wireframe del enunciado**, literales: `Símbolo`,
  `(Autocomplete)`, `Agregar Símbolo`, `Nombre`, `Moneda`, `Eliminar`. La cuarta columna de la
  grilla no lleva encabezado, tal como está dibujada.
- **La lista se ordena por lo último que se agregó.** La acción recién agregada aparece primera:
  es la confirmación de que el alta funcionó, sin tener que buscarla entre las demás.
- **La búsqueda empieza en el segundo carácter.** Con una sola letra coincide casi cualquier
  acción, y las veinte sugerencias que aparecerían no ayudan a elegir.
- **Una acción sólo se quita después de confirmarlo.** `Eliminar` no es el último paso: es el
  primero.

### Lo que se aparta de los wireframes

El cliente resolvió el 2026-09-13 siete puntos que el enunciado no define. Cinco de ellos son
textos nuevos —no salen del enunciado ni de sus wireframes— y quedan acá para que no se lean como
un descuido cuando alguien compare la pantalla contra su wireframe:

| Qué | Dónde | Por qué |
|---|---|---|
| `Todavía no agregaste ninguna acción.` | `Mis Acciones`, en lugar de las filas, con los encabezados de la grilla a la vista | Una grilla con encabezados y nada debajo se lee como que algo falló; los encabezados se mantienen para que se entienda qué va a haber ahí. |
| `No se encontró ninguna acción con ese texto.` | En el desplegable del campo `Símbolo`, en lugar de las sugerencias | Distingue "no hay coincidencias" de "todavía está buscando", que es lo que confunde cuando no aparece nada. |
| `Esa acción ya está en tu lista.` | Debajo del campo `Símbolo` | Sin el aviso, agregar algo que ya se tenía no produce ningún cambio visible y se lee como que el botón no funciona. |
| `Elegí una acción de las sugerencias.` | Debajo del campo `Símbolo` | Explica qué falta hacer cuando el alta se intenta sin haber elegido nada. |
| `¿Quitar {símbolo} de tus acciones?`, con las opciones `Eliminar` y `Cancelar` | Al activar `Eliminar` en una fila | Nombrar el símbolo es lo que permite darse cuenta de que se activó la fila equivocada. |

Los otros dos puntos no agregan texto: el orden de la grilla (`RF-06`) y el mínimo de dos
caracteres para que aparezcan sugerencias (`RF-13`).

**Los dos avisos del campo `Símbolo` son excluyentes**: `Esa acción ya está en tu lista.` sólo
aparece cuando hay una sugerencia elegida, y `Elegí una acción de las sugerencias.` sólo cuando no
la hay. Nunca se muestran a la vez.

**El botón deshabilitado y el aviso no se pisan.** `Agregar Símbolo` está deshabilitado mientras no
haya una sugerencia elegida (`RF-31`): esa es la primera defensa, y evita el intento. El aviso de
`RF-21` es la segunda, para cuando el alta se dispara igual por otro camino —la tecla Enter en el
campo, por ejemplo—: ahí no se agrega nada y se explica por qué.

## Criterios de aceptación

<!-- Uno por requisito funcional, redactado como algo observable. Es lo que el cliente marca cuando lo ve andando, y lo que /converge contrasta contra el código. -->

- [ ] **RF-01** — Al ingresar con el usuario de prueba `juan`, en `Mis Acciones` se ve una grilla
      con sus acciones: `TSLA`, `AAPL` y `NFLX`.
- [ ] **RF-02** — La grilla tiene cuatro columnas: tres con los encabezados `Símbolo`, `Nombre` y
      `Moneda`, y una cuarta con el encabezado en blanco, como en el wireframe.
- [ ] **RF-03** — La fila de `TSLA` muestra `TSLA` en `Símbolo`, un nombre en `Nombre` —`Tesla Inc`
      en el enunciado— y `USD` en `Moneda`. Lo que se verifica es que estén los tres datos que el
      catálogo de acciones tenga para ese símbolo, no el nombre exacto: el nombre lo publica la
      fuente del catálogo y puede escribirse de otra forma.
- [ ] **RF-04** — Ingresando con el otro usuario de prueba se ve una lista distinta, y ninguna de
      las acciones de `juan` que ese usuario no tenga guardadas.
- [ ] **RF-05** — Se cierra sesión, se vuelve a ingresar con el mismo usuario y la grilla muestra
      exactamente las mismas acciones que antes de salir.
- [ ] **RF-06** — La acción recién agregada queda en la primera fila de la grilla, y las demás
      siguen en orden de alta hacia abajo; recargar la pantalla dos veces seguidas no las cambia
      de lugar.
- [ ] **RF-07** — Con un usuario que no tiene ninguna acción guardada, se ven los encabezados
      `Símbolo`, `Nombre` y `Moneda` y, en lugar de las filas, el texto `Todavía no agregaste
      ninguna acción.`
- [ ] **RF-08** — Al escribir `TSL` en el campo `Símbolo` aparece `TSLA` entre las sugerencias.
- [ ] **RF-09** — Al escribir `Tesla` en el campo `Símbolo` aparece igual `TSLA` entre las
      sugerencias, aunque lo tipeado no sea el símbolo.
- [ ] **RF-10** — Escribir `tsla`, `TSLA` o `TsLa` produce las mismas sugerencias.
- [ ] **RF-11** — Al escribir un texto muy común, la lista de sugerencias no pasa de veinte.
- [ ] **RF-12** — Una acción que dejó de cotizar no aparece entre las sugerencias, aunque se
      escriba su símbolo completo.
- [ ] **RF-13** — Con un solo carácter escrito en el campo no se despliega ninguna sugerencia; al
      escribir el segundo, aparecen.
- [ ] **RF-14** — Al escribir un texto que no coincide con ninguna acción aparece `No se encontró
      ninguna acción con ese texto.` y ninguna sugerencia.
- [ ] **RF-15** — Elegir `MSFT` de las sugerencias y apretar `Agregar Símbolo` deja `MSFT` en la
      grilla.
- [ ] **RF-16** — Esa fila aparece sin que haga falta recargar la pantalla ni volver a entrar.
- [ ] **RF-17** — La fila recién agregada muestra el nombre y la moneda de la acción, no sólo su
      símbolo, y los sigue mostrando después de salir y volver a entrar.
- [ ] **RF-18** — Agregar `MSFT` dos veces seguidas deja una sola fila de `MSFT` en la grilla.
- [ ] **RF-19** — En ese segundo intento aparece `Esa acción ya está en tu lista.` debajo del
      campo `Símbolo`.
- [ ] **RF-20** — Apretar `Agregar Símbolo` sin haber elegido nada de las sugerencias deja la
      grilla exactamente igual que antes, sin filas nuevas ni filas vacías.
- [ ] **RF-21** — Al intentar agregar sin haber elegido una sugerencia aparece `Elegí una acción
      de las sugerencias.` debajo del campo `Símbolo`.
- [ ] **RF-22** — Después de que `juan` agrega `MSFT`, el otro usuario de prueba ingresa y su
      lista sigue siendo la de antes.
- [ ] **RF-23** — Cada fila de la grilla termina con el enlace `Eliminar`, escrito así.
- [ ] **RF-24** — Confirmar la eliminación en la fila de `NFLX` deja la grilla sin `NFLX`, y al
      volver a entrar más tarde `NFLX` sigue sin estar.
- [ ] **RF-25** — Al activar `Eliminar` en la fila de `NFLX` aparece `¿Quitar NFLX de tus
      acciones?` con las opciones `Eliminar` y `Cancelar`, y hasta confirmar la fila sigue en la
      grilla.
- [ ] **RF-26** — La fila desaparece sin que haga falta recargar la pantalla.
- [ ] **RF-27** — Después de eliminar `NFLX`, escribir `NFLX` en el campo `Símbolo` la vuelve a
      sugerir, y se la puede agregar de nuevo.
- [ ] **RF-28** — Mientras `juan` elimina acciones de su lista, la lista del otro usuario de
      prueba no cambia.
- [ ] **RF-29** — En la grilla, el símbolo de cada fila se ve y se comporta como un enlace, no
      como texto suelto.
- [ ] **RF-30** — Activar el enlace `AAPL` lleva al Detalle de Acción de `AAPL`, no al de otra
      acción de la lista.
- [ ] **RF-31** — Con el campo `Símbolo` vacío, y también con texto escrito pero sin ninguna
      sugerencia elegida, `Agregar Símbolo` se ve deshabilitado y no responde.
- [ ] **RF-32** — Cancelar la confirmación deja la fila de `NFLX` en la grilla, y al volver a
      entrar más tarde sigue ahí.

## Fuera de alcance

<!-- Lo que alguien podría suponer incluido y no lo está. Esta sección evita discusiones en la entrega. -->

- **Todo lo que muestra el Detalle de Acción**: el gráfico, los modos Tiempo Real e Histórico y el
  intervalo. Acá sólo se define que el símbolo de la grilla lleva a esa pantalla. El resto es
  `003-quote-chart`.
- **La cabecera y la sesión**: `Mis Acciones` en el título, `Usuario: {nombre completo}`,
  `Cerrar sesión` y el hecho de que un visitante sin identificar no pueda abrir esta pantalla ya
  están definidos y firmados en `001-authentication`.
- **Mostrar la cotización en la grilla.** El enunciado pide símbolo, nombre y moneda; el precio se
  ve en el detalle.
- **Cantidad de acciones, precio de compra, notas o alertas** sobre una acción de la lista: la
  lista guarda cuáles sigue el usuario, nada más.
- **Editar una fila.** No hay nada editable: una acción se agrega o se quita.
- **Ordenar, filtrar, buscar o paginar la grilla** desde la pantalla. El volumen por usuario no lo
  justifica.
- **Un límite a la cantidad de acciones que un usuario puede seguir.**
- **Mercados distintos de NYSE y NASDAQ**, y agregar a mano una acción que no esté en el listado
  de la aplicación.
- **Compartir la lista con otro usuario**, importarla o exportarla.
- **Deshacer una eliminación.** Una acción quitada se vuelve a agregar buscándola de nuevo.
- **Administrar el listado de acciones desde la aplicación**: se mantiene solo, y ningún usuario
  lo edita.
