# Respuestas fijadas de TwelveData

El JSON que devuelve el proveedor, guardado tal cual, para que la suite lo use en lugar de la API
real. Es el `TEST-03` de `CONVENTIONS.md`, que es **Blocker**.

## Por qué

Dos razones, y las dos son de la constitución.

**El Artículo II**: el plan gratuito da 800 requests por día. Una suite que sale a la red los gasta
sin que nadie lo decida, y lo hace de nuevo en cada corrida de CI y en cada `pytest` local.

**Un test que depende de la red no es un test**: falla cuando el proveedor está caído, cuando la
clave venció o cuando alguien corre la suite en un avión, y ninguna de esas tres cosas dice nada
sobre si el código está bien.

Corolario: **la suite completa corre sin red y sin API key.**

```
cd backend && MARKET_DATA_API_KEY= uv run pytest
```

## Cómo se fija una respuesta

Se pide una vez a mano, se guarda la respuesta **completa y sin editar**, y se le pone un nombre
que diga qué caso representa:

```
time_series_aapl_1min.json      la respuesta feliz
time_series_empty.json          símbolo sin datos en el rango
error_429_rate_limit.json       la cuota agotada
error_401_bad_key.json          credencial inválida
error_404_unknown_symbol.json   símbolo que no existe
```

Los modos de falla importan tanto como el camino feliz: `ERR-05` pide que estén cubiertos, y son
los que en producción llegan primero.

**Sin editar** es literal. Un JSON "arreglado a mano" describe un proveedor que no existe, y el día
que el real devuelva algo distinto el test va a seguir en verde mientras la aplicación se rompe.
Si hace falta anonimizar algo, se anota acá abajo qué y por qué.

## Qué no entra

Respuestas de cientos de kilobytes. Se recorta el arreglo de datos a las pocas entradas que el
test necesita — recortar **cuántos** elementos hay no cambia la forma, editar los campos sí.

## Qué se pidió, y cuándo

| Fixture | Cuándo | Qué se pidió |
|---|---|---|
| `time_series_tsla_1min.json` | 2026-09-14 | `/time_series` con `symbol=TSLA`, `interval=1min`, `start_date=2026-09-11 13:30:00`, `end_date=2026-09-11 20:00:00`, `timezone=UTC`, `outputsize=5000`. HTTP 200, 390 velas — la rueda completa del viernes 2026-09-11, que en hora de Nueva York va de 09:30 a 16:00. Recortado a las **cinco últimas** (19:55 a 19:59 UTC), que son las que los tests afirman; los campos no se tocaron. |

La captura del `time_series` es la de la tarea 1 de `003-quote-chart`, y **reemplaza** a una
anterior que pedía la serie sin `timezone`: el proveedor contestaba entonces en hora del mercado
(`America/New_York`) y el cliente le estampaba UTC encima, con lo que todo el gráfico quedaba
cuatro horas corrido sin que fallara nada. El fixture nuevo es la respuesta con los parámetros que
el cliente va a mandar de ahora en más, que es la única forma de que el test del huso signifique
algo.

Se pidió con la API key del entorno de producción, desde el host donde vive, para que no hiciera
falta traerla a una máquina de desarrollo (Artículo I). **La suite sigue corriendo sin red y sin
API key**: eso es lo que este archivo compra.
