/**
 * The header of an inner screen -- wireframe 02 (RF-08).
 *
 * The title on the left, who is logged in and the way out on the right, and a rule under the two.
 *
 * `Cerrar sesión` sits next to the name because that is where `COPY.md` puts it, and where it sits
 * is half of what it is: a way out found at the bottom of a long screen is a way out nobody finds
 * (RF-18). It is a `<button>` and not an `<a>` -- it performs an action and navigates nowhere on
 * its own -- drawn like the link the wireframe draws.
 *
 * Both are conditional on there being somebody logged in, which is the `Mientras haya un usuario
 * identificado` of the requirement: a way out offered to a visitor who is already out is an
 * invitation to press something that does nothing.
 *
 * `{nombre completo}` is the name of the person and not the user they typed to get in: `Usuario:
 * Juan Perez`, never `Usuario: juan` (`COPY.md`). The two are different values in the demo data on
 * purpose, so the difference shows on the first screen.
 *
 * The title is a prop because the Detail screen's header is the same bar with `{símbolo} - {nombre}
 * - {moneda}` on the left (wireframe 03).
 */

import type { JSX } from 'react';

import { useSession } from '../auth/session';

export function Header({ title }: { title: string }): JSX.Element {
  const { user, logOut } = useSession();

  return (
    <header className="flex items-baseline justify-between gap-4 border-b border-border py-3">
      <h1 className="m-0 text-base font-normal">{title}</h1>

      {user && (
        <div className="flex items-baseline gap-4">
          <span className="text-text-muted">Usuario: {user.fullName}</span>

          <button type="button" onClick={logOut} className="bg-transparent p-0 text-link underline">
            Cerrar sesión
          </button>
        </div>
      )}
    </header>
  );
}
