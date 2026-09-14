# Textos de interfaz

**Fuente única de los strings visibles.** Casi todos están tomados del enunciado o de sus
wireframes, y se copian **verbatim**, faltas de ortografía incluidas (`CONVENTIONS.md` → `UI-02`).

Los que el enunciado no da van en las dos últimas secciones, separados a propósito: son decisiones
del cliente, no citas, y quien compare una pantalla contra su wireframe tiene que poder ver de un
vistazo cuál es cuál.

> Por qué verbatim: el enunciado especifica textos concretos. Un evaluador que busca
> `usuario o clave invalida` tiene que encontrarlo tal cual. "Corregirlo" a `usuario o clave
> inválida` es apartarse de un requisito explícito para ganar una tilde.

## Login — `docs/design/wireframes/01-login.png`

| Elemento | Texto |
|---|---|
| Etiqueta usuario | `Usuario` |
| Placeholder usuario | `Ingresar nombre de usuario` |
| Etiqueta clave | `Clave` |
| Botón | `Ingresar` |
| Error de credenciales | `usuario o clave invalida` |

El campo clave es `type="password"`. El wireframe no muestra título de página ni logo: no se
agregan.

Esta pantalla muestra además dos textos que el enunciado no da: el aviso de sesión vencida y el de
campo vacío. Están abajo, en *Sesión y validación*.

## Mis Acciones — `docs/design/wireframes/02-mis-acciones.png`

| Elemento | Texto |
|---|---|
| Título (cabecera, izquierda) | `Mis Acciones` |
| Usuario (cabecera, derecha) | `Usuario: {nombre completo}` |
| Cierre de sesión (cabecera, derecha) | `Cerrar sesión` — ver *Sesión y validación* |
| Etiqueta del autocomplete | `Símbolo` |
| Placeholder del autocomplete | `(Autocomplete)` |
| Botón | `Agregar Símbolo` |
| Columnas de la grilla | `Símbolo` · `Nombre` · `Moneda` · *(sin encabezado)* |
| Link de baja | `Eliminar` |

La cuarta columna **no tiene encabezado** en el wireframe. La celda de `Símbolo` es un enlace que
navega al detalle; `Eliminar` es un enlace que ejecuta la baja.

Esta pantalla muestra además cinco textos que el enunciado no da: la lista vacía, la búsqueda sin
resultados, los dos avisos del campo `Símbolo` y la confirmación de la baja. Están abajo, en
*Lista de favoritas*.

## Detalle de Acción — `docs/design/wireframes/03-detalle-accion.png`

| Elemento | Texto |
|---|---|
| Cabecera (izquierda) | `{símbolo} - {nombre} - {moneda}` — ej. `TSLA - Tesla Inc - USD` |
| Usuario (cabecera, derecha) | `Usuario: {nombre completo}` |
| Cierre de sesión (cabecera, derecha) | `Cerrar sesión` — ver *Sesión y validación* |
| Radio 1 | `Tiempo Real` |
| Aclaración del radio 1 | `( utiliza la fecha actual, al graficar esta opcion, se debe actualizar el gráfico en forma automática segun el intervalo seleccionado)` |
| Radio 2 | `Histórico` |
| Placeholder desde | `Fecha hora desde` |
| Placeholder hasta | `Fecha hora hasta` |
| Etiqueta intervalo | `Intervalo` |
| Aclaración del intervalo | `( opciones 1min / 5min / 15min)` |
| Botón | `Graficar` |
| Título del gráfico | `{símbolo}` |
| Eje Y | `Cotización` |
| Eje X | `Intervalo` |

Las dos aclaraciones entre paréntesis **están en el wireframe** y se muestran, con sus faltas de
ortografía (`opcion`, `segun`). La tercera del wireframe —`( utilizar highcharts o similar para
graficar)`— es una instrucción para el desarrollador, **no** un texto de la pantalla: no se muestra.

## Avisos de estado — no están en el wireframe

Los cuatro estados de `ERR-05` necesitan un texto que el enunciado no da. Se definen acá, y van
arriba del gráfico (`UI-05`):

| Estado | Texto |
|---|---|
| `stale` | `Mostrando la última cotización disponible: no se pudo consultar el proveedor.` |
| `market_closed` | `El mercado está cerrado. Se muestra la última rueda disponible: {fecha}.` |
| `no_data` | `No hay cotizaciones para {símbolo} en el rango e intervalo seleccionados.` |
| `ok` | *(sin aviso)* |

**El aviso de `stale` se muestra también cuando falla el refresco automático**, y no sólo cuando el
backend manda ese estado. *(Decidido por el cliente el 2026-09-14, al cerrar el `/review-feature`.)*
Hasta entonces el refresco de `Tiempo Real` se tragaba su error en silencio: un gráfico que había
dejado de actualizarse media hora antes se veía idéntico a uno al día, que es exactamente la
lectura equivocada que estos avisos existen para evitar.

Tiene **precedencia sobre el estado de la serie**, por la misma razón que la tiene en el backend:
después de una falla lo que hay en pantalla es lo último que se supo, y nombrar cualquier otro
estado describiría un momento que ya pasó. El gráfico se queda —sacárselo a quien lo está leyendo
castigaría a la persona por una red que no maneja— y el aviso dice qué es.

**La salvedad, para que esté escrita:** el texto dice `no se pudo consultar el proveedor.` y en este
caso quien no contestó fue **nuestra** API. Se eligió igual sobre redactar un quinto aviso, porque
el hecho que la persona necesita —lo que está viendo no es lo último— es el mismo, y una segunda
redacción para el mismo hecho es una que un día se va a separar de ésta. Si alguna vez se quiere
distinguir las dos fallas, es un texto nuevo y lo decide el cliente.

**Este aviso y el de `No se pudo conectar` pueden aparecer los dos a la vez, y está bien así.**
*(Decidido por el cliente el 2026-09-14.)* Pasa cuando un refresco falla y después la persona
aprieta `Graficar` y esa consulta también falla. No se le dio precedencia a ninguno porque **no
dicen lo mismo**: uno dice que la consulta que se acaba de pedir no salió, el otro que lo que está
dibujado quedó viejo. Tapar el segundo con el primero dejaría a alguien reintentando contra un
gráfico viejo sin saber que lo es, que es justo lo que este aviso vino a arreglar.

## Lista de favoritas — no están en el enunciado

Los cinco textos que `002-favorite-stocks` obliga a inventar. No salen del enunciado ni de sus
wireframes: los decidió el cliente el 2026-09-13, y su spec los registra con el porqué
(`docs/specs/002-favorite-stocks/spec.md` → *Lo que se aparta de los wireframes*).

| Elemento | Texto | Dónde |
|---|---|---|
| Lista vacía | `Todavía no agregaste ninguna acción.` | `Mis Acciones`, en lugar de las filas; los encabezados de la grilla se siguen viendo |
| Búsqueda sin resultados | `No se encontró ninguna acción con ese texto.` | En el desplegable del campo `Símbolo`, en lugar de las sugerencias |
| Acción repetida | `Esa acción ya está en tu lista.` | Debajo del campo `Símbolo` |
| Alta sin selección | `Elegí una acción de las sugerencias.` | Debajo del campo `Símbolo` |
| Confirmación de baja | `¿Quitar {símbolo} de tus acciones?` — opciones `Eliminar` y `Cancelar` | Al activar `Eliminar` en una fila de la grilla |

`{símbolo}` es el de la fila que se está por quitar: `¿Quitar NFLX de tus acciones?`. Nombrarlo es
lo que permite darse cuenta de que se activó la fila equivocada.

**Los dos avisos del campo `Símbolo` son excluyentes.** `Esa acción ya está en tu lista.` aparece
sólo cuando hay una sugerencia elegida; `Elegí una acción de las sugerencias.`, sólo cuando no la
hay. Nunca se muestran a la vez.

## Detalle: navegación, horarios y validación — no están en el wireframe

Los siete textos que `003-quote-chart` obliga a inventar. No salen del enunciado ni de sus
wireframes: los cinco primeros los decidió el cliente el 2026-09-13, y su spec los registra con el
porqué (`docs/specs/003-quote-chart/spec.md` → *Lo que se aparta de los wireframes*).

Las **dos etiquetas del tooltip** las decidió el cliente el 2026-09-14, cuando fijar el contrato de
`RF-38` dejó a la vista que dos horas una debajo de la otra no dicen cuál es cuál. Se eligieron
sobre `Mercado:` / `Argentina:` y sobre `Nueva York:` / `Buenos Aires:`: las primeras son más
cortas pero no dicen que hablan de una hora, y las segundas atan el texto a la ciudad del mercado —
el día que entre uno que no sea de Nueva York, la etiqueta miente. Estas calcan el vocabulario de
la spec y el `Horarios en hora del mercado.` que la cabecera ya muestra.

| Elemento | Texto | Dónde |
|---|---|---|
| Volver a la lista | `Mis Acciones` | Cabecera del Detalle, a la izquierda de `{símbolo} - {nombre} - {moneda}` |
| Aclaración de horarios | `Horarios en hora del mercado.` | Cabecera del Detalle, debajo del nombre de la acción |
| Intervalo sin elegir | `Elegí un intervalo.` | Debajo del selector `Intervalo`, al activar `Graficar` sin haber elegido uno |
| Fechas al revés | `La fecha desde tiene que ser anterior a la fecha hasta.` | Debajo de los campos de fecha, en modo `Histórico` |
| Rango excedido | `El rango es demasiado largo para el intervalo {intervalo}. El máximo es {N} días.` | Debajo de los campos de fecha, en modo `Histórico` |
| Hora del mercado (tooltip) | `Hora del mercado: {fecha y hora}` | Primera línea de hora del tooltip, al apoyar el puntero sobre un punto del gráfico |
| Hora de Argentina (tooltip) | `Hora de Argentina: {fecha y hora}` | Segunda línea de hora del mismo tooltip, debajo de la anterior |

El aviso de **campo vacío** del Detalle es el mismo de la pantalla de ingreso —`Completá este
campo.`, en *Sesión y validación*—: un campo en blanco es el mismo olvido en las dos pantallas, y
dos textos distintos para lo mismo sólo agregan superficie que mantener.

Por la misma razón, el aviso de **no se pudo conectar** del Detalle también es el de la pantalla de
ingreso —`No pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.`, en *Sesión y
validación*—. Aparece en dos lugares: cuando no se pudo traer la lista de favoritas y por lo tanto
no se sabe de quién es la acción, y cuando `Graficar` no consiguió la serie por algo que no es
ninguna de las dos fallas de rango. En los dos casos el hecho es el mismo que en el login —no se
logró comunicar con el servidor—, y el gráfico que ya estaba en pantalla se queda como está.

**El reuso lo confirmó el cliente el 2026-09-14**, al cerrar el `/review-feature` de
`003-quote-chart`. La alternativa descartada era un texto propio del Detalle: se descartó porque
el hecho que comunica es idéntico al del login y dos redacciones para el mismo hecho se separan
sola el día que alguien toca una. No es un texto nuevo, así que no abre fila propia en ninguna
tabla: es esta fila de *Sesión y validación* dicha en dos pantallas más.

Las fechas y horas de la pantalla están en la hora del mercado donde cotiza la acción; al apoyar
el puntero sobre un punto del gráfico se muestran las dos, la del mercado y la de Argentina.
Los topes de rango del `{N}` son 7 días para `1min`, 30 para `5min` y 90 para `15min`.

## Sesión y validación — no están en el enunciado

Los cinco textos que `001-authentication` obliga a inventar. No salen del enunciado ni de sus
wireframes: los decidió el cliente el 2026-09-13, y su spec los registra con la alternativa que se
descartó (`docs/specs/001-authentication/spec.md` → *Lo que se aparta de los wireframes*).

| Elemento | Texto | Dónde |
|---|---|---|
| Cierre de sesión | `Cerrar sesión` | Cabecera de `Mis Acciones` y del Detalle, a la derecha, junto a `Usuario: {nombre completo}` |
| Sesión vencida | `Tu sesión expiró. Volvé a ingresar.` | Pantalla de login, cuando se llega ahí porque la sesión venció |
| Campo vacío | `Completá este campo.` | Login, debajo de cada campo que quedó vacío al apretar `Ingresar` |
| Demasiados intentos | `Demasiados intentos. Probá de nuevo en unos minutos.` | Login, cuando se alcanzó el límite de intentos fallidos (`RF-21` a `RF-26`) |
| No se pudo conectar | `No pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.` | Login, cuando no se logró comunicar para validar las credenciales (`RF-27`) |

`{nombre completo}` es el nombre de la persona, no el usuario con el que ingresa: `Usuario: Juan
Perez`, nunca `Usuario: juan`. Los datos de prueba guardan los dos por separado y son distintos,
así que la diferencia se ve en la primera pantalla.

**El aviso de campo vacío no reemplaza al de credenciales.** Un campo en blanco es un olvido y se
avisa antes de validar nada; `usuario o clave invalida` aparece sólo cuando los dos campos tienen
algo escrito y la credencial no sirve. Los dos textos nunca se muestran a la vez.

**Ninguno de los otros tampoco.** Los cuatro avisos del login son excluyentes y hay un orden:
primero el campo vacío, que ni siquiera llega a validarse; después el límite de intentos, que se
responde sin mirar la credencial; después el de no haber podido conectarse, porque tampoco llegó a
validarse nada; y sólo si ninguno de los tres aplica, `usuario o clave invalida`, que es el único
que afirma algo sobre la credencial de la persona.

Mientras el límite está activo, el aviso es el mismo se escriba la clave correcta o una equivocada:
decir cuál de las dos era le devolvería a un atacante justo el dato que el límite le está negando.

Los dos últimos se parecen en su segunda oración y se distinguen en la primera, que es la que carga
el significado: uno dice que hay que esperar porque se intentó demasiado, el otro que no se pudo
preguntar. Culpar a la credencial cuando la falla es del sistema manda a revisar una clave que
estaba bien.
