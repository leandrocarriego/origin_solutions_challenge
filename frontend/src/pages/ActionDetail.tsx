/**
 * Detalle de Acción -- a shell, and deliberately so.
 *
 * H4 promises getting to the right action, not what that screen shows: the chart, the intervals
 * and the quote are `003`, which replaces this file whole. It is the same move `001` made with
 * `Mis Acciones`, which was a title until this feature filled it in.
 *
 * It renders the symbol that comes in the address and no text of its own, so `COPY.md` does not
 * change because of this screen (`plan.md`).
 */

import type { JSX } from 'react';
import { useParams } from 'react-router';

import { Header } from '../components/Header';

export function ActionDetail(): JSX.Element {
  const { symbol } = useParams<{ symbol: string }>();

  return (
    <div className="mx-auto max-w-5xl px-6">
      <Header title={symbol ?? ''} />
    </div>
  );
}
