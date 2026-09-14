# Detalle de Acción y gráfico de cotizaciones — Especificación

<!--
  ESTE ES EL ÚNICO ARTEFACTO CARA AL CLIENTE. Se lee, se discute y se firma con él.
  NO lleva decisiones técnicas: nada de stack, endpoints, schemas, tablas ni rutas
  de archivo. Todo eso va en plan.md.
  Las notas como esta no salen en el PDF: el exportador las descarta.
-->

**Estado:** Aprobado · **Feature:** `003-quote-chart` · **Fecha:** 2026-09-13

<!-- `/approve-spec` completa Aprobada por y Fecha de aprobación, y pasa Estado a Aprobado. -->

**Aprobada por:** Leandro Carriego · **Fecha de aprobación:** 2026-09-13

## Problema

Una persona ya puede identificarse (`001-authentication`) y armar su lista de acciones favoritas
(`002-favorite-stocks`), pero esa lista sólo dice **qué** acciones le interesan: símbolo, nombre y
moneda. No dice **cuánto valen**, ni cómo se movieron en el día, ni cómo se movieron ayer.

Es exactamente lo que el cliente pidió en la primera línea del enunciado —*"graficar la cotización
de una acción en tiempo real"*— y es lo único que todavía no existe. Sin esta pantalla, la
aplicación es una lista de nombres.

Hay además una restricción que forma parte del problema y no de la solución: **la fuente de datos
externa tiene una cuota diaria finita**. Una pantalla que consulte esa fuente cada vez que alguien
mira un gráfico deja de funcionar a media mañana, y deja de funcionar para todos a la vez.

## Objetivo

Que un usuario pueda abrir cualquiera de sus acciones favoritas y ver su cotización graficada: la
del día, actualizándose sola mientras la mira, o la de un período pasado que él elija.

Y que eso siga funcionando el día de la demostración: con el mercado cerrado, con la fuente de
datos caída o con varias personas mirando al mismo tiempo, la pantalla muestra algo y explica qué
está mostrando.

## Actores

| Actor | Qué hace con esta feature |
|---|---|
| **Usuario** | Una persona ya identificada. Abre el detalle de una de **sus** acciones favoritas, elige cómo quiere verla —el día de hoy o un período pasado— y con qué intervalo, y mira el gráfico. |
| **El sistema** | Reúne las cotizaciones de la acción, las grafica, las mantiene al día mientras alguien está mirando, y avisa cuando lo que muestra no es lo que se esperaría ver. |
| **La fuente de datos externa** | El servicio del que salen las cotizaciones. No lo ve ni lo conoce el usuario, y tiene un límite diario de consultas que la aplicación tiene que respetar. |

## Historias de usuario

<!--
  Priorizadas y ENTREGABLES DE FORMA INDEPENDIENTE: si sólo se construye H1, el
  cliente ya tiene algo que usar. Ese corte es lo que permite entregar por partes
  y es la razón de que estén numeradas por prioridad, no por orden narrativo.
-->

### H1 — Ver el gráfico de una acción *(prioridad más alta)*
Como **usuario**, quiero **abrir una de mis acciones favoritas y ver su cotización del día
graficada con el intervalo que yo elija**, para **entender cómo se está moviendo**.

**Cómo se prueba que anda:** desde `Mis Acciones` se abre `TSLA`; arriba se lee
`TSLA - Tesla Inc - USD`, se elige el intervalo `5min`, se aprieta `Graficar` y aparece un gráfico
titulado `TSLA` con la cotización del día.

*Entregable por sí sola:* con sólo H1 el cliente ya tiene la pantalla del enunciado andando y
puede verificar que los datos que se grafican son los de la acción que abrió. Incluye el caso de
apretar `Graficar` sin haber elegido un intervalo: la pantalla dice qué falta, no grafica y no
consulta la fuente de datos.

### H2 — Que el gráfico se mantenga solo
Como **usuario**, quiero **que el gráfico se actualice automáticamente mientras lo estoy
mirando**, para **seguir la cotización sin tener que recargar la pantalla**.

**Cómo se prueba que anda:** con el gráfico del día a la vista y el intervalo `1min` elegido, se
deja la pantalla quieta un minuto y aparece un punto nuevo a la derecha, sin que la pantalla
parpadee ni se recargue. Al cambiar a otra solapa del navegador y volver un rato después, el
gráfico sigue ahí y vuelve a actualizarse.

*Entregable por sí sola:* H2 agrega movimiento a un gráfico que H1 ya dibuja; se construye encima,
sin rehacer nada de H1.

### H3 — Consultar un período pasado
Como **usuario**, quiero **elegir una fecha y hora desde y una fecha y hora hasta**, para **ver
cómo se movió la acción en un momento que ya pasó**.

**Cómo se prueba que anda:** se elige `Histórico`, se cargan las dos fechas, se elige `15min`, se
aprieta `Graficar` y el gráfico muestra únicamente ese período. El gráfico se queda quieto: en
`Histórico` no se actualiza solo.

*Entregable por sí sola:* H3 es un segundo modo de consulta sobre el mismo gráfico; H1 y H2 siguen
funcionando igual si H3 no existe. Lo que H3 agrega son las tres consultas inválidas propias del
modo `Histórico` —campo de fecha vacío, fechas al revés y rango demasiado largo—; el rechazo de una
consulta sin intervalo ya viene de H1.

### H4 — Entender qué estoy viendo cuando no hay datos de hoy
Como **usuario**, quiero **que la pantalla me diga por qué el gráfico muestra lo que muestra**,
para **no confundir un domingo, o un problema de la fuente de datos, con una aplicación rota**.

**Cómo se prueba que anda:** se abre el detalle un sábado; el gráfico muestra la rueda del viernes
y arriba se lee `El mercado está cerrado. Se muestra la última rueda disponible: {fecha}.` La
pantalla nunca queda en blanco y sin explicación.

*Entregable por sí sola:* H4 agrega los avisos sobre un gráfico que ya anda; sin H4 el gráfico
sigue dibujándose, sólo que sin explicar qué período está mostrando.

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
  La columna Enunciado conecta cada requisito con `docs/PROJECT_BRIEF.md`: sus REQ-NN, sus NFR-NN
  y sus ambigüedades declaradas (A5, A6, A7). Es lo que /analyze recorre para verificar que la
  cadena no tenga huecos.
-->

### La pantalla

| ID | Requisito | Historia | Enunciado |
|----|-----------|----------|-----------|
| RF-01 | El sistema debe presentar la pantalla de Detalle de Acción con una cabecera que muestre `{símbolo} - {nombre} - {moneda}` de la acción abierta. | H1 | REQ-12 · A7 |
| RF-02 | Si alguien abre el Detalle de Acción sin estar identificado, entonces el sistema debe llevarlo a la pantalla de ingreso. | H1 | NFR-03 |
| RF-03 | El sistema debe presentar dos opciones de consulta excluyentes entre sí, `Tiempo Real` e `Histórico`. | H1 | REQ-13 · REQ-15 |
| RF-04 | Cuando el usuario abre la pantalla, el sistema debe dejar elegida la opción `Tiempo Real`. | H1 | REQ-13 |
| RF-05 | El sistema debe mostrar junto a `Tiempo Real` la aclaración `( utiliza la fecha actual, al graficar esta opcion, se debe actualizar el gráfico en forma automática segun el intervalo seleccionado)`. | H1 | REQ-13 |
| RF-06 | El sistema debe presentar un selector `Intervalo` cuyas únicas opciones sean `1min`, `5min` y `15min`. | H1 | REQ-16 |
| RF-07 | Cuando el usuario abre la pantalla, el sistema debe dejar el selector `Intervalo` sin ninguna opción elegida. | H1 | REQ-16 |
| RF-08 | El sistema debe mostrar junto al selector `Intervalo` la aclaración `( opciones 1min / 5min / 15min)`. | H1 | REQ-16 |
| RF-09 | El sistema debe presentar un campo `Fecha hora desde` y un campo `Fecha hora hasta` para el modo `Histórico`. | H3 | REQ-15 |
| RF-10 | Cuando el usuario abre la pantalla, el sistema debe dejar `Fecha hora desde` y `Fecha hora hasta` cargados con las últimas 24 horas de mercado. | H3 | A6 |
| RF-11 | El sistema debe presentar un botón `Graficar`. | H1 | REQ-17 |
| RF-12 | Mientras el usuario no haya activado `Graficar`, el sistema no debe mostrar ningún gráfico. | H1 | NFR-05 |
| RF-34 | El sistema debe presentar en la cabecera, a la izquierda de `{símbolo} - {nombre} - {moneda}`, un enlace `Mis Acciones` que lleva a esa pantalla. | H1 | Cliente 2026-09-13 |
| RF-35 | Si el usuario abre el Detalle de una acción que no está entre sus favoritas, entonces el sistema debe llevarlo a la pantalla `Mis Acciones`. | H1 | Cliente 2026-09-13 |

### Fechas y horas

| ID | Requisito | Historia | Enunciado |
|----|-----------|----------|-----------|
| RF-36 | El sistema debe expresar en la hora del mercado donde cotiza la acción todas las fechas y horas de la pantalla: `Fecha hora desde`, `Fecha hora hasta` y el eje horizontal del gráfico. | H1 | Cliente 2026-09-13 |
| RF-37 | El sistema debe mostrar en la cabecera, debajo de `{símbolo} - {nombre} - {moneda}`, la aclaración `Horarios en hora del mercado.` | H1 | Cliente 2026-09-13 |
| RF-38 | Cuando el usuario apoya el puntero sobre un punto del gráfico, el sistema debe mostrar el momento de esa cotización en hora del mercado y en hora de Argentina. | H1 | Cliente 2026-09-13 |

### Graficar

| ID | Requisito | Historia | Enunciado |
|----|-----------|----------|-----------|
| RF-13 | Cuando el usuario activa `Graficar` con `Tiempo Real` elegido, el sistema debe graficar las cotizaciones de la acción correspondientes a la fecha del día, con el intervalo elegido. | H1 | REQ-13 |
| RF-14 | El sistema debe graficar la serie con el símbolo de la acción como título, `Cotización` como nombre del eje vertical e `Intervalo` como nombre del eje horizontal. | H1 | REQ-17 |
| RF-15 | El sistema debe ubicar cada cotización sobre el eje horizontal en el momento al que corresponde. | H1 | REQ-17 |
| RF-16 | Cuando el usuario activa `Graficar` con `Histórico` elegido, el sistema debe graficar las cotizaciones comprendidas entre `Fecha hora desde` y `Fecha hora hasta`, con el intervalo elegido. | H3 | REQ-15 |
| RF-17 | Cuando el usuario activa `Graficar` habiendo ya un gráfico a la vista, el sistema debe reemplazarlo por el de la nueva consulta. | H1 | REQ-13 · REQ-15 |

### Actualización automática

| ID | Requisito | Historia | Enunciado |
|----|-----------|----------|-----------|
| RF-18 | Mientras haya un gráfico de `Tiempo Real` a la vista, el sistema debe actualizarlo cada vez que transcurre el intervalo elegido. | H2 | REQ-14 |
| RF-19 | Cuando el sistema actualiza el gráfico de `Tiempo Real`, debe hacerlo sin recargar la pantalla. | H2 | REQ-14 |
| RF-20 | Cuando el sistema actualiza el gráfico de `Tiempo Real`, debe agregar las cotizaciones nuevas sin quitar las ya graficadas. | H2 | REQ-14 |
| RF-21 | Cuando la pantalla de Detalle deja de estar a la vista, el sistema debe suspender la actualización automática. | H2 | NFR-05 |
| RF-22 | Cuando la pantalla de Detalle vuelve a estar a la vista, el sistema debe reanudar la actualización automática. | H2 | NFR-05 |
| RF-23 | Mientras haya un gráfico de `Histórico` a la vista, el sistema no debe actualizarlo por su cuenta. | H3 | REQ-15 |

### Cuando la consulta no es válida

| ID | Requisito | Historia | Enunciado |
|----|-----------|----------|-----------|
| RF-39 | Cuando el usuario activa `Graficar` sin haber elegido un intervalo, el sistema debe mostrar `Elegí un intervalo.` debajo del selector `Intervalo`. | H1 | Cliente 2026-09-13 |
| RF-40 | Cuando el usuario activa `Graficar` con `Histórico` elegido y un campo de fecha vacío, el sistema debe mostrar `Completá este campo.` debajo de ese campo. | H3 | A6 |
| RF-41 | Cuando el usuario activa `Graficar` con `Histórico` elegido y `Fecha hora desde` igual o posterior a `Fecha hora hasta`, el sistema debe mostrar `La fecha desde tiene que ser anterior a la fecha hasta.` debajo de los campos de fecha. | H3 | A6 |
| RF-42 | El sistema debe admitir en `Histórico` con el intervalo `1min` un rango máximo de 7 días. | H3 | A6 |
| RF-43 | El sistema debe admitir en `Histórico` con el intervalo `5min` un rango máximo de 30 días. | H3 | A6 |
| RF-44 | El sistema debe admitir en `Histórico` con el intervalo `15min` un rango máximo de 90 días. | H3 | A6 |
| RF-45 | Cuando el usuario activa `Graficar` con `Histórico` elegido y un rango mayor al máximo de su intervalo, el sistema debe mostrar `El rango es demasiado largo para el intervalo {intervalo}. El máximo es {N} días.` debajo de los campos de fecha. | H3 | A6 |
| RF-46 | Cuando el usuario activa `Graficar` con una consulta que no cumple RF-39, RF-40, RF-41 o RF-45, el sistema no debe graficar esa consulta. | H1 · H3 | Cliente 2026-09-13 |
| RF-47 | Cuando el usuario activa `Graficar` con una consulta que no cumple RF-39, RF-40, RF-41 o RF-45, el sistema no debe consultar la fuente de datos externa. | H1 · H3 | NFR-05 |
| RF-48 | Cuando el usuario activa `Graficar` con una consulta que no cumple RF-39, RF-40, RF-41 o RF-45 habiendo ya un gráfico a la vista, el sistema debe dejar ese gráfico como está. | H1 · H3 | Cliente 2026-09-13 |

### La cuota de la fuente de datos

| ID | Requisito | Historia | Enunciado |
|----|-----------|----------|-----------|
| RF-24 | El sistema no debe consultar la fuente de datos externa cuando las cotizaciones pedidas ya son conocidas y siguen vigentes para el intervalo elegido. | H1 | NFR-05 |
| RF-25 | El sistema debe consumir de la fuente de datos externa lo mismo cuando varias personas miran la misma acción con el mismo intervalo que cuando la mira una sola. | H1 | NFR-05 |
| RF-26 | El sistema no debe mostrar en la pantalla el nombre ni la dirección de la fuente de datos externa. | H1 | NFR-02 |

### Cuando lo que hay no es lo esperado

| ID | Requisito | Historia | Enunciado |
|----|-----------|----------|-----------|
| RF-27 | Si la fecha del día no tiene cotizaciones para la acción, entonces el sistema debe graficar la última rueda disponible. | H4 | A5 · NFR-04 |
| RF-28 | Cuando el sistema grafica la última rueda disponible porque el mercado está cerrado, debe mostrar arriba del gráfico `El mercado está cerrado. Se muestra la última rueda disponible: {fecha}.` | H4 | A5 · NFR-04 |
| RF-29 | Si el sistema no logra obtener cotizaciones nuevas de la fuente de datos externa, entonces debe graficar las últimas cotizaciones que ya conocía. | H4 | NFR-04 |
| RF-30 | Cuando el sistema grafica cotizaciones que no pudo actualizar, debe mostrar arriba del gráfico `Mostrando la última cotización disponible: no se pudo consultar el proveedor.` | H4 | NFR-04 |
| RF-31 | Si no existe ninguna cotización de la acción para el rango y el intervalo elegidos, entonces el sistema debe mostrar `No hay cotizaciones para {símbolo} en el rango e intervalo seleccionados.` | H4 | NFR-04 |
| RF-32 | Mientras las cotizaciones graficadas estén al día, el sistema no debe mostrar ningún aviso de estado. | H4 | NFR-04 |
| RF-33 | El sistema nunca debe dejar la pantalla sin gráfico y sin aviso al mismo tiempo. | H4 | NFR-04 |

## Reglas de negocio

<!-- Lo que siempre vale, independientemente del flujo. Si una regla viene de la constitución (la cuota es finita, los datos de un usuario son de ese usuario), nombrala en términos del negocio, no del artículo. -->

- **Nada se consulta hasta que el usuario lo pide.** El selector de intervalo arranca vacío y el
  gráfico aparece recién al activar `Graficar`. Es lo que muestra el wireframe, y además es lo que
  evita que abrir la pantalla ya cueste una consulta a la fuente de datos.

- **La cuota diaria de la fuente de datos es finita, y eso es parte del producto.** El costo crece
  con la cantidad de **acciones distintas que alguien está mirando**, nunca con la cantidad de
  personas conectadas: diez usuarios mirando `TSLA` cuestan lo mismo que uno.

- **Mirar cuesta; haber mirado, no.** El gráfico se mantiene al día mientras alguien lo está
  viendo. Una solapa olvidada en segundo plano deja de actualizarse hasta que vuelvan a ella.

- **El intervalo lo elige el usuario, siempre entre los tres del enunciado.** La cuota no se
  administra sacándole opciones a la pantalla.

- **El gráfico nunca queda vacío y sin explicación.** Si no hay datos de hoy se muestra lo último
  que haya, y se dice qué es. Una pantalla en blanco se lee como una aplicación rota, aunque el
  motivo sea que es domingo.

- **El aviso va arriba del gráfico**, no al pie: califica al dato que está por leerse.

- **El usuario nunca ve de dónde salen los datos.** Ni el nombre del servicio, ni su dirección, ni
  sus errores en crudo.

- **Al detalle se llega estando identificado.** Sin sesión, la pantalla no se muestra.

- **Al detalle se llega con la acción en la lista propia.** El Detalle muestra una acción que el
  usuario tiene entre sus favoritas; si abre una que no está en su lista, vuelve a `Mis Acciones`.
  Para mirar una acción nueva, primero se agrega.

- **Los horarios son los del mercado donde cotiza la acción.** Es la hora en la que pasaron las
  cosas, y con ella una rueda es un día y no dos. La hora de Argentina está disponible sin salir
  de la pantalla: apoyando el puntero sobre un punto se ven las dos.

- **El rango del `Histórico` es coherente con el intervalo elegido**: hasta 7 días con `1min`,
  30 con `5min` y 90 con `15min`. No es una limitación de la fuente de datos: es lo que se puede
  leer en un gráfico sin que los puntos se pisen unos con otros.

- **Una consulta que no se puede hacer se avisa y no se ejecuta.** Sin intervalo, con una fecha
  vacía, con las fechas al revés o con un rango demasiado largo, la pantalla dice qué corregir,
  no consulta la fuente de datos y deja el gráfico anterior como está.

- **El aviso de una consulta inválida va debajo del campo que hay que corregir**, no arriba del
  gráfico: ahí viven los avisos sobre el dato que se está mostrando, y acá todavía no hay dato.

- **`Tiempo Real` se actualiza solo; `Histórico` no.** Un período que ya terminó no cambia.

- **Los textos del wireframe se copian tal cual**, incluidas las dos aclaraciones entre paréntesis
  y sus faltas de ortografía (`opcion`, `segun`). La tercera aclaración del wireframe
  —`( utilizar highcharts o similar para graficar)`— es una instrucción para quien construye, no
  un texto de la pantalla: no se muestra.

## Criterios de aceptación

<!-- Uno por requisito funcional, redactado como algo observable. Es lo que el cliente marca cuando lo ve andando, y lo que /converge contrasta contra el código. -->

- [ ] **RF-01** — Abriendo el detalle de `TSLA`, arriba a la izquierda se lee exactamente
      `TSLA - Tesla Inc - USD`; abriendo el de `AAPL`, los datos son los de esa acción.
- [ ] **RF-02** — Pegando en el navegador la dirección del detalle en una ventana donde nunca se
      ingresó, queda a la vista la pantalla de ingreso y no el gráfico.
- [ ] **RF-03** — Se ven las opciones `Tiempo Real` e `Histórico`, y marcar una desmarca la otra.
- [ ] **RF-04** — Recién abierta la pantalla, la opción marcada es `Tiempo Real`.
- [ ] **RF-05** — Al lado de `Tiempo Real` se lee el texto entre paréntesis del enunciado, palabra
      por palabra, con `opcion` y `segun` sin tilde.
- [ ] **RF-06** — Al desplegar el selector `Intervalo` se ofrecen `1min`, `5min` y `15min`, y nada
      más.
- [ ] **RF-07** — Recién abierta la pantalla, el selector `Intervalo` se ve vacío.
- [ ] **RF-08** — Al lado del selector `Intervalo` se lee `( opciones 1min / 5min / 15min)`.
- [ ] **RF-09** — Se ven dos campos de fecha y hora, con los textos de ayuda `Fecha hora desde` y
      `Fecha hora hasta`.
- [ ] **RF-10** — Recién abierta la pantalla, los dos campos ya vienen cargados con un período que
      cubre las últimas 24 horas de mercado, sin tener que escribir nada.
- [ ] **RF-11** — Se ve un botón con la palabra `Graficar`.
- [ ] **RF-12** — Recién abierta la pantalla, debajo de los controles no hay ningún gráfico ni un
      área de gráfico vacía.
- [ ] **RF-13** — Con `Tiempo Real` marcado, eligiendo `5min` y apretando `Graficar`, aparece un
      gráfico cuyos puntos son del día de hoy y están separados de a cinco minutos.
- [ ] **RF-14** — Sobre el gráfico se lee el símbolo de la acción; a la izquierda, `Cotización`; y
      debajo, `Intervalo`.
- [ ] **RF-15** — Cada punto del gráfico cae en la hora que le corresponde, y las horas avanzan de
      izquierda a derecha.
- [ ] **RF-16** — Con `Histórico` marcado, cargando desde y hasta de un día hábil pasado y
      apretando `Graficar`, el gráfico muestra únicamente cotizaciones de ese período: el primer
      punto no es anterior a `Fecha hora desde` ni el último posterior a `Fecha hora hasta`.
- [ ] **RF-17** — Graficar `5min`, después cambiar a `15min` y volver a apretar `Graficar` deja a
      la vista un solo gráfico, el de `15min`, y no los dos superpuestos.
- [ ] **RF-18** — Con el gráfico de `Tiempo Real` a `1min` a la vista y el mercado abierto, al cabo
      de un minuto aparece un punto más a la derecha, sin haber tocado nada.
- [ ] **RF-19** — En ese momento la pantalla no se recarga: los controles conservan lo elegido y el
      navegador no muestra su indicador de carga de página.
- [ ] **RF-20** — Después de esa actualización, los puntos que ya estaban siguen en el gráfico.
- [ ] **RF-21** — Pasando a otra solapa del navegador durante varios intervalos, el gráfico no
      acumula puntos en ese tiempo.
- [ ] **RF-22** — Al volver a la solapa, el gráfico se pone al día y vuelve a sumar un punto por
      intervalo.
- [ ] **RF-23** — Con un gráfico de `Histórico` a la vista, dejar la pantalla quieta varios minutos
      no le agrega ni le cambia ningún punto.
- [ ] **RF-24** — Graficando la misma acción con el mismo intervalo dos veces seguidas, la segunda
      no genera ninguna consulta a la fuente de datos externa.
- [ ] **RF-25** — Con cinco navegadores abiertos sobre la misma acción y el mismo intervalo, la
      cantidad de consultas a la fuente de datos externa en un rato es la misma que con uno solo.
- [ ] **RF-26** — En ningún texto de la pantalla, ni en ningún mensaje de error visible, aparece el
      nombre ni la dirección del servicio del que salen las cotizaciones.
- [ ] **RF-27** — Abriendo el detalle un domingo y apretando `Graficar` en `Tiempo Real`, el
      gráfico muestra los puntos de la última rueda que hubo, no una pantalla vacía.
- [ ] **RF-28** — En ese mismo caso, arriba del gráfico se lee `El mercado está cerrado. Se muestra
      la última rueda disponible:` seguido de la fecha de esa rueda.
- [ ] **RF-29** — Con la fuente de datos externa fuera de servicio, apretar `Graficar` sobre una
      acción ya consultada antes igual muestra un gráfico con lo último conocido.
- [ ] **RF-30** — En ese caso, arriba del gráfico se lee `Mostrando la última cotización
      disponible: no se pudo consultar el proveedor.`, escrito exactamente así.
- [ ] **RF-31** — Pidiendo un período en el que la acción no tuvo ninguna cotización, en la
      pantalla se lee `No hay cotizaciones para` seguido del símbolo y del resto del texto, y no
      queda un gráfico vacío sin explicación.
- [ ] **RF-32** — Graficando en horario de mercado con datos del día, arriba del gráfico no aparece
      ningún aviso.
- [ ] **RF-33** — En los cuatro casos anteriores —datos del día, mercado cerrado, fuente caída y
      sin cotizaciones— la pantalla siempre muestra un gráfico, un aviso, o los dos; nunca ninguno
      de los dos.
- [ ] **RF-34** — En la cabecera, a la izquierda de `TSLA - Tesla Inc - USD`, se ve el enlace `Mis
      Acciones`, y activarlo deja a la vista la grilla de favoritas.
- [ ] **RF-35** — Pegando en el navegador la dirección del detalle de una acción que no está en la
      lista propia, queda a la vista `Mis Acciones` y no el gráfico de esa acción.
- [ ] **RF-36** — Graficando `TSLA` en `Tiempo Real`, la primera hora del eje es la de apertura del
      mercado donde cotiza —no la hora que marca el reloj de la computadora en ese momento—, y las
      fechas que traen cargadas `Fecha hora desde` y `Fecha hora hasta` están en esa misma hora.
- [ ] **RF-37** — Debajo de `TSLA - Tesla Inc - USD` se lee `Horarios en hora del mercado.`
- [ ] **RF-38** — Apoyando el puntero sobre un punto del gráfico se leen dos horas para esa misma
      cotización: la del mercado y la de Argentina.
- [ ] **RF-39** — Recién abierta la pantalla, apretar `Graficar` sin tocar el selector muestra
      `Elegí un intervalo.` debajo del selector `Intervalo`.
- [ ] **RF-40** — En `Histórico`, borrando el contenido de `Fecha hora hasta` y apretando
      `Graficar`, debajo de ese campo se lee `Completá este campo.`
- [ ] **RF-41** — En `Histórico`, cargando un `desde` posterior al `hasta` y apretando `Graficar`,
      debajo de los campos se lee `La fecha desde tiene que ser anterior a la fecha hasta.`
- [ ] **RF-42** — En `Histórico` con `1min`, un rango de 7 días grafica y uno de 8 días no.
- [ ] **RF-43** — En `Histórico` con `5min`, un rango de 30 días grafica y uno de 31 días no.
- [ ] **RF-44** — En `Histórico` con `15min`, un rango de 90 días grafica y uno de 91 días no.
- [ ] **RF-45** — En `Histórico` con `1min` y un rango de 30 días, apretar `Graficar` deja a la
      vista `El rango es demasiado largo para el intervalo 1min. El máximo es 7 días.`
- [ ] **RF-46** — En los cuatro casos de consulta inválida —sin intervalo elegido, con un campo de
      fecha vacío, con `Fecha hora desde` igual o posterior a `Fecha hora hasta` y con un rango
      mayor al máximo del intervalo—, después de apretar `Graficar` no aparece ningún gráfico nuevo
      en la pantalla.
- [ ] **RF-47** — En esos mismos cuatro casos, revisando el consumo de la fuente de datos externa,
      apretar `Graficar` no generó ninguna consulta.
- [ ] **RF-48** — Con un gráfico ya a la vista, apretar `Graficar` con cualquiera de esas cuatro
      consultas inválidas deja ese mismo gráfico en pantalla, sin borrarlo ni vaciarlo.

## Fuera de alcance

<!-- Lo que alguien podría suponer incluido y no lo está. Esta sección evita discusiones en la entrega. -->

- **El enlace del símbolo en la grilla de `Mis Acciones`**, que es por donde se llega acá: lo
  define `002-favorite-stocks`. Esta feature define la pantalla a la que se llega, no el enlace.
- **La cabecera a la derecha** —`Usuario: {nombre completo}` y `Cerrar sesión`—: ya la definió
  `001-authentication` para todas las pantallas internas.
- **Otros intervalos** además de `1min`, `5min` y `15min`. El enunciado da tres.
- **Otros tipos de gráfico**: velas, barras, volumen, indicadores técnicos, medias móviles.
- **Comparar dos acciones** en el mismo gráfico.
- **Zoom, desplazamiento o selección de rango arrastrando sobre el gráfico**: el rango se elige con
  los controles de arriba, que es lo que muestra el wireframe.
- **Exportar o descargar** el gráfico o la serie de cotizaciones.
- **Alertas de precio**, notificaciones o suscripciones a una acción.
- **Cotizaciones en vivo al segundo**: el enunciado define "tiempo real" como el día actual
  actualizándose según el intervalo elegido (`docs/PROJECT_BRIEF.md` → A2).
- **El detalle de una acción que el usuario no tiene entre sus favoritas.** Para mirar una acción
  nueva, primero se agrega desde `Mis Acciones`.
- **Elegir el huso horario.** Se muestra el del mercado, con la hora de Argentina al apoyar el
  puntero sobre un punto; no hay un selector de zona horaria ni otros husos.
- **Acciones fuera del catálogo del proyecto** (NYSE y NASDAQ).
- **Datos distintos de la cotización**: apertura, cierre, máximo, mínimo, volumen o capitalización
  no se muestran. El eje vertical del wireframe dice `Cotización`, y es un solo valor.

## Lo que se aparta de los wireframes

El cliente resolvió el 2026-09-13 los seis puntos que el enunciado dejaba abiertos. Cinco de esas
resoluciones agregan a la pantalla algo que el wireframe no dibuja. Quedan acá para que no se lean
como un descuido cuando alguien compare la pantalla contra el wireframe:

| Qué | Dónde | Por qué |
|---|---|---|
| El enlace `Mis Acciones` | Cabecera del Detalle, a la izquierda de `{símbolo} - {nombre} - {moneda}` | Sin él, la única forma de volver a la lista es el botón atrás del navegador. Mismo criterio con el que `001-authentication` agregó `Cerrar sesión`. |
| `Horarios en hora del mercado.` | Cabecera, debajo del nombre de la acción | Un eje que arranca a las 09:30 necesita decir de qué reloj habla; si no, se lee como un error de la aplicación. |
| Las dos horas al apoyar el puntero | Sobre cada punto del gráfico | Deja leer el gráfico en hora de Argentina sin cambiar el eje ni perder la hora del mercado. |
| `Elegí un intervalo.` | Debajo del selector `Intervalo` | El selector arranca vacío por diseño; apretar `Graficar` sin elegir tiene que decir qué falta y no quedarse mudo. |
| `Completá este campo.` · `La fecha desde tiene que ser anterior a la fecha hasta.` · `El rango es demasiado largo para el intervalo {intervalo}. El máximo es {N} días.` | Debajo de los campos de fecha, en modo `Histórico` | El enunciado pide validar el rango (`docs/PROJECT_BRIEF.md` → A6) y no da ningún texto para el caso. |

El primero de los textos —`Completá este campo.`— no es nuevo: es el mismo que ya usa la pantalla
de ingreso. Los otros cuatro sí, y por eso se deciden acá.

La sexta resolución no agrega nada a la pantalla: el Detalle es sólo para las acciones que el
usuario tiene entre sus favoritas, que es el único camino que el wireframe dibuja.
