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
 *
 * The Detail adds two things this bar did not have, and they come in as **optional** props so that
 * `Mis Acciones` keeps calling it exactly as it did: the way back to the list, to the left of the
 * title (RF-34), and the note about which clock the hours are told in, under it (RF-37).
 *
 * Where each one falls is this component's decision and not the screen's: the screen says *what*
 * goes in each place, the bar says where the places are. `back` is one object and not two props
 * because a destination with no text -- or the other way round -- is not a state that exists:
 * either there is a way back or there is not. It is drawn with the `Link` of `react-router` and
 * not an `<a href>`, so it does not reload the whole application on the way.
 */

import type { JSX } from 'react';
import { Link } from 'react-router';

import { useSession } from '../auth/session';

export function Header({
  title,
  back,
  note,
}: {
  title: string;
  back?: { to: string; label: string };
  note?: string;
}): JSX.Element {
  const { user, logOut } = useSession();

  return (
    <header className="flex items-baseline justify-between gap-4 border-b border-border py-3">
      <div className="flex items-baseline gap-4">
        {back && (
          <Link to={back.to} className="text-link underline">
            {back.label}
          </Link>
        )}

        <div>
          <h1 className="m-0 text-base font-normal">{title}</h1>
          {note && <p className="m-0 text-text-muted">{note}</p>}
        </div>
      </div>

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
