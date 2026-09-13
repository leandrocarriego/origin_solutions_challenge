# Specs entregadas

Acá vive la carpeta de cada feature **después** de que su PR se mergeó a `main`. La mueve
`/ship` (`agents/skills/ship_changes.md`), en el mismo commit que completa la columna **Test**
de la tabla de trazabilidad de `docs/PROJECT_BRIEF.md`.

```bash
git mv docs/specs/<NNN-feature> docs/specs/archive/<NNN-feature>
```

## Por qué existe esta carpeta

Sin ella el árbol de specs crece sin límite y deja de distinguir **lo que está por construirse de
lo que ya está en producción**. Alguien que abre `docs/specs/` tiene que poder leer la lista como
"esto es lo que falta", y eso sólo funciona si lo entregado se va.

Se mueve, no se borra: la spec es el documento que el cliente firmó, y es la única forma de
contestar más adelante *"¿esto se pidió así?"*.

## El número no se reutiliza, nunca

La próxima feature toma **el siguiente al mayor entre las activas y las archivadas**. Si
`001-authentication` está acá y `002-favorite-stocks` está activa, la que sigue es `003`, aunque
alguna se haya cancelado y su carpeta ya no exista en ningún lado.

La razón es la misma que la de los identificadores retirados de `CONVENTIONS.md`: desde el primer
día el número aparece en el nombre de una rama, en mensajes de commit y en un PR. Reasignarlo
haría que el historial diga una cosa y el árbol diga otra, y el historial no se puede editar.

## Qué NO va acá

Una spec abandonada antes de entregarse. Si una feature se cancela, su carpeta se borra y su
número queda como hueco — archivar algo que nunca se construyó haría que esta carpeta deje de
significar "está en producción", que es lo único que significa.
