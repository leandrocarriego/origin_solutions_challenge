# Textos de interfaz

**Fuente única de los strings visibles.** Cada uno está tomado del enunciado o de sus wireframes.
Se copian **verbatim**, faltas de ortografía incluidas (`CONVENTIONS.md` → `UI-02`).

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

## Mis Acciones — `docs/design/wireframes/02-mis-acciones.png`

| Elemento | Texto |
|---|---|
| Título (cabecera, izquierda) | `Mis Acciones` |
| Usuario (cabecera, derecha) | `Usuario: {nombre}` |
| Etiqueta del autocomplete | `Símbolo` |
| Placeholder del autocomplete | `(Autocomplete)` |
| Botón | `Agregar Símbolo` |
| Columnas de la grilla | `Símbolo` · `Nombre` · `Moneda` · *(sin encabezado)* |
| Link de baja | `Eliminar` |

La cuarta columna **no tiene encabezado** en el wireframe. La celda de `Símbolo` es un enlace que
navega al detalle; `Eliminar` es un enlace que ejecuta la baja.

## Detalle de Acción — `docs/design/wireframes/03-detalle-accion.png`

| Elemento | Texto |
|---|---|
| Cabecera (izquierda) | `{símbolo} - {nombre} - {moneda}` — ej. `TSLA - Tesla Inc - USD` |
| Usuario (cabecera, derecha) | `Usuario: {nombre}` |
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
