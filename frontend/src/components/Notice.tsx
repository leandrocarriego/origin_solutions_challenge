/**
 * What the chart is showing, when it is not simply today's quotes (RF-28, RF-30, RF-31).
 *
 * It is drawn **above** the chart and never at its foot (UI-05): a notice qualifies the data that
 * is about to be read, and at the foot it is a footnote to something already misread.
 *
 * `ok` draws nothing (RF-32). A screen that explains itself every time teaches people to stop
 * reading the explanation, and then the three that do mean something stop being read as well.
 */

import type { JSX } from 'react';

import type { QuoteSeries } from '../api/quotes';

/** Verbatim from the *Avisos de estado* table of docs/design/COPY.md (UI-02). */
const STALE = 'Mostrando la última cotización disponible: no se pudo consultar el proveedor.';
const MARKET_CLOSED = (session: string): string =>
  `El mercado está cerrado. Se muestra la última rueda disponible: ${session}.`;
const NO_DATA = (symbol: string): string =>
  `No hay cotizaciones para ${symbol} en el rango e intervalo seleccionados.`;

/**
 * The session date the way a person reads it, from the date our API sent (RF-28).
 *
 * `2026-09-11` is a day and not an instant, and it arrives already told in market hours. It is cut
 * into its three parts rather than parsed into a `Date`: midnight UTC in New York is the day
 * before, so a conversion here would name a day that never traded.
 */
function readable(session: string): string {
  const [year, month, day] = session.split('-');

  return `${day}/${month}/${year}`;
}

/**
 * Whether a date arrived in the shape this can read.
 *
 * `market_closed` always carries its day, so this never answers no in practice. It is here for
 * what happens if it ever did: cutting `''` into three parts writes `undefined/undefined/`, and a
 * notice that shows that is worse than one that shows nothing -- it puts a broken date in front of
 * a person and asks them to trust the chart under it (ERR-02).
 */
function isADay(session: string | null | undefined): session is string {
  return typeof session === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(session);
}

/**
 * The sentence for a state, or nothing when the state is `ok` and there is nothing to say.
 *
 * **A refresh that did not land reads as `stale`, and it wins over what the series says.** It is
 * the same precedence the backend uses for the same reason: once a fetch has failed, what is on
 * screen is the last thing known and nothing newer was learnt, so naming any other state would
 * describe a moment that has passed. What the chart holds is still drawn -- the person keeps
 * reading what they were reading -- and the notice says what it is.
 *
 * The literal is reused and not written a second time: the fact is the one `Avisos de estado`
 * already names, and a second wording for it would be a second thing to keep (decided by the
 * client on 2026-09-14, `COPY.md`).
 */
function textFor(series: QuoteSeries, refreshFailed: boolean): string | null {
  if (refreshFailed || series.status === 'stale') return STALE;
  if (series.status === 'market_closed') {
    return isADay(series.session_date) ? MARKET_CLOSED(readable(series.session_date)) : null;
  }
  if (series.status === 'no_data') return NO_DATA(series.symbol);

  return null;
}

export function Notice({
  series,
  refreshFailed = false,
}: {
  series: QuoteSeries;
  /** Whether the automatic refresh stopped landing, which makes what is drawn old (RF-18). */
  refreshFailed?: boolean;
}): JSX.Element | null {
  const text = textFor(series, refreshFailed);

  if (text === null) return null;

  return (
    <p role="status" className="my-3 border border-border bg-surface p-3 text-warn">
      {text}
    </p>
  );
}
