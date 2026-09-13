# La suite del backend

Detalle de `TEST-07`. Las reglas con su severidad están en `CONVENTIONS.md` (`TEST-01` a
`TEST-07`); acá está cómo se aplican y dónde va cada cosa.

## Dónde va cada test

```
tests/
├── unit/           lógica pura: sin base, sin red, sin FastAPI
├── integration/    endpoints y repositorios contra una base real
├── architecture/   las reglas que el lenguaje no puede hacer cumplir
├── fixtures/       respuestas fijadas del proveedor (ver su README)
└── conftest.py     lo compartido, y lo que nunca sale al mundo
```

**`unit/`** prueba decisiones: dado este input, esta salida. Si necesita una sesión de base o un
cliente HTTP, o está en el directorio equivocado o la función tiene demasiadas responsabilidades.

**`integration/`** prueba que las piezas hablen: que el endpoint devuelva el status correcto, que
el repositorio escriba lo que dice escribir, que la transacción haga rollback.

**`architecture/`** es distinto de los otros dos: no prueba comportamiento, prueba **estructura**.
Lee el código con `ast` y falla nombrando archivo y línea. Son los tests que sostienen las
fronteras del Artículo IV, y existen porque Python no tiene visibilidad a nivel de módulo — el
guión bajo y `__all__` son convención, no enforcement.

## Cómo se escribe uno

**AAA explícito.** Arrange, Act, Assert, en ese orden y separados por una línea en blanco. No hace
falta comentar cada bloque; sí que se vean los tres.

```python
def test_the_cache_serves_a_quote_without_touching_the_provider() -> None:
    """A quote already in the database never spends quota."""
    repository = StubRepository(stored=[una_cotizacion()])

    resultado = get_quote(repository, symbol="AAPL", interval="1min")

    assert resultado.source == "cache"
```

**Un test, una afirmación sobre el comportamiento.** Varios `assert` están bien si describen la
misma cosa; si describen dos, son dos tests, porque cuando falla el primero el segundo nunca corre
y no te enterás de que también estaba roto.

**El nombre dice el comportamiento, no el método.** `test_get_quote_2` no dice nada cuando el CI
falla a las once de la noche. `test_a_symbol_with_no_data_returns_empty_instead_of_failing` sí.

**Docstring breve en inglés** en cada test, como cualquier otra función (`PY-11`).

**Async sin decorador.** `asyncio_mode = "auto"` en `pyproject.toml` ya lo resuelve: un `async def
test_...` corre solo, sin `@pytest.mark.asyncio`.

**Los marcadores se declaran.** `--strict-markers` está activo, así que un `@pytest.mark.loquesea`
sin declarar en `pyproject.toml` es un error y no un marcador que nadie aplica nunca. Es
deliberado: un marcador mal escrito silenciaría el test en vez de avisarte.

## Lo que no se hace

**Salir a la red.** Ni al proveedor, ni a ningún lado. Es `TEST-03`, es **Blocker**, y la razón
está en `fixtures/twelvedata/README.md`: la cuota es de 800 requests por día y una suite que la
gasta rompe el Artículo II en cada corrida.

```
cd backend && TWELVEDATA_API_KEY= uv run pytest
```

**Debilitar un test para pasar un gate.** Es el Artículo VI: si un test molesta, o el código está
mal o el test está mal, y las dos cosas se arreglan. Ninguna se silencia con un `skip`.

**Probar sólo el camino feliz.** Los modos de falla son los que llegan primero en producción:
`ERR-05` los exige cubiertos, y la cobertura del 80% (`TEST-05`) no distingue entre un camino y el
otro — se puede llegar al umbral sin haber probado un solo error.

**Escribir el test después.** El Tester va antes que el Developer y el humano firma los tests
antes de que exista la implementación. Un test escrito después describe lo que el código hace;
escrito antes, describe lo que tiene que hacer.

## Correrla

```
cd backend
uv run pytest                                   # todo, con cobertura
uv run pytest tests/unit tests/architecture --no-cov -q   # lo que corre el pre-commit
uv run pytest -k nombre_del_test                # uno solo
uv run pytest --cov-report=html && open htmlcov/index.html
```
