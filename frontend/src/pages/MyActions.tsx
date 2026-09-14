/**
 * `Mis Acciones` -- wireframe 02, and in this feature only its header.
 *
 * It exists so that a successful login has somewhere to arrive at, and so that the guard has an
 * inner screen to guard. The autocomplete and the grid belong to `002`, which was asked for them,
 * and building them here would be scope nobody signed.
 */

import type { JSX } from 'react';

import { Header } from '../components/Header';

export function MyActions(): JSX.Element {
  return (
    <div className="mx-auto max-w-5xl px-6">
      <Header title="Mis Acciones" />
    </div>
  );
}
