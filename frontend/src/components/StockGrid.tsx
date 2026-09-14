/**
 * The grid of `Mis Acciones` -- wireframe 02 (RF-02, RF-03, RF-07).
 *
 * Four columns and only three headings: the fourth is drawn with its heading cell empty, and that
 * emptiness is the wireframe read literally (UI-01). "Fixing" the gap with a word -- `Acciones`,
 * `Opciones` -- is exactly the kind of improvement UI-01 exists to refuse.
 *
 * The empty state keeps the headings on screen and puts the notice where the rows would go
 * (`COPY.md` → *Lista de favoritas*): a grid with nothing at all reads as something having
 * failed, and the headings are what say the list is empty and not broken. It belongs to this
 * component and not to the screen above, because "in place of the rows" is a statement about
 * this table.
 *
 * The fourth column carries `Eliminar` (RF-23) and the first one carries the symbol as a link to
 * the detail (RF-29, RF-30). Both are links in the wireframe, and both are real controls here: a
 * `<span>` with a click handler cannot be reached by keyboard and is announced by nothing.
 *
 * Blue is only for what actually is a link -- the symbol and `Eliminar` -- which is the rule the
 * palette was written with (UI-03).
 */

import type { JSX } from 'react';
import { Link } from 'react-router';

import type { FavoriteItem } from '../api/favorites';

/** Verbatim from the `Mis Acciones` table of docs/design/COPY.md (UI-02). */
const COLUMNS = ['Símbolo', 'Nombre', 'Moneda'];

/** Verbatim from the *Lista de favoritas* table of docs/design/COPY.md (UI-02). */
const EMPTY_LIST = 'Todavía no agregaste ninguna acción.';

/** Verbatim from the `Mis Acciones` table of docs/design/COPY.md (UI-02). */
const REMOVE = 'Eliminar';

interface StockGridProps {
  favorites: FavoriteItem[];
  /** Asked to remove that favourite. The grid asks; the screen is the one that confirms. */
  onRemove: (favorite: FavoriteItem) => void;
}

export function StockGrid({ favorites, onRemove }: StockGridProps): JSX.Element {
  return (
    <table className="border-collapse border border-border bg-surface text-left">
      <thead>
        <tr className="bg-surface-muted">
          {COLUMNS.map((column) => (
            <th key={column} className="border border-border px-3 py-1 font-normal">
              {column}
            </th>
          ))}
          {/* No heading, and that is the wireframe: the column of the row's actions has none. */}
          <th className="border border-border px-3 py-1" />
        </tr>
      </thead>

      <tbody>
        {favorites.length === 0 && (
          // `COPY.md` puts the notice **in place of the rows**, so it is a row: one cell spanning
          // the four columns, inside the same table whose headings stay on screen. Drawn above
          // the table instead it would read as a notice about the grid rather than as its
          // content, and the headings would sit under it describing nothing.
          <tr>
            <td colSpan={COLUMNS.length + 1} className="border border-border px-3 py-1">
              <p className="m-0 text-text-muted">{EMPTY_LIST}</p>
            </td>
          </tr>
        )}

        {favorites.map((favorite) => (
          <tr key={favorite.symbol}>
            {/* UI-04: symbols line up only in tabular mono. The address carries the symbol in
                upper case, which is how the catalogue stores it and how `003` will read it. */}
            <td className="border border-border px-3 py-1 font-mono">
              <Link to={`/stocks/${favorite.symbol.toUpperCase()}`} className="text-link underline">
                {favorite.symbol}
              </Link>
            </td>
            <td className="border border-border px-3 py-1">{favorite.name}</td>
            <td className="border border-border px-3 py-1 font-mono">{favorite.currency}</td>
            <td className="border border-border px-3 py-1">
              {/* A button and not a link: it performs an action and navigates nowhere, drawn like
                  the link the wireframe draws. */}
              <button
                type="button"
                onClick={() => {
                  onRemove(favorite);
                }}
                className="bg-transparent p-0 text-link underline"
              >
                {REMOVE}
              </button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
