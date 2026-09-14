/**
 * The notices that say what the chart is showing (H4 of `003-quote-chart`).
 *
 * The four states are the contract and all four answer **200**: a failure of the
 * provider is not a failure of the request, and the screen finds out which of the four it got by
 * reading `status` -- never a 4xx, and never the name of whoever could not be reached.
 *
 * The screen is opened the way a person opens it: the application is mounted at an address with a
 * session already in the browser, and everything else is read off what is painted. Nothing here
 * imports `ActionDetail`, `Notice` or `QuoteChart` -- which component draws the notice is an
 * internal arrangement of `plan.md`, and what the requirement fixes is that the person reads it,
 * and reads it *before* the chart.
 *
 * Today every test here is red because `/stocks/:symbol` has nothing behind it: the address falls
 * through to `Mis Acciones`, so there is no `Graficar` to press. That is the intended red --
 * absence of implementation.
 *
 * **What the chart can be asked in jsdom.** Highcharts draws into an SVG and gives no roles: what
 * a test can see is the *text* it writes -- the title and the two axis titles -- and the identity
 * of the node it drew into. So "there is a chart" here means "the vertical axis title `Cotización`
 * is on screen".
 *
 * **The date inside `market_closed`** is checked by the fixed parts of the copy plus *something
 * with a digit in it* where `{fecha}` goes. How that date is written down is fixed nowhere --
 * `COPY.md` writes the placeholder and `plan.md` says only that it is in market time -- so a test
 * that demanded one spelling would be inventing a requirement.
 *
 * `fetch` is replaced in every test and restored afterwards: a frontend test that goes to the
 * network is not a frontend test.
 */

import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { App } from '../src/App';
import { writeStoredSession } from '../src/auth/storage';

/* Verbatim from the `Detalle de Acción` table of docs/design/COPY.md. */
const INTERVALO = 'Intervalo';
const GRAFICAR = 'Graficar';
const COTIZACION = 'Cotización';

const ME_URL = '/api/auth/me';
const FAVORITES_URL = '/api/favorites';
const QUOTES_URL = '/api/quotes';

const FULL_NAME = 'Juan Perez';
const A_TOKEN = 'a.signed.token';
const WHO_IT_IS = { id: 1, full_name: FULL_NAME };

/** One row of `GET /api/favorites` (`002` → *Contratos*), which is where the header comes from. */
interface Favorite {
  symbol: string;
  name: string;
  currency: string;
}

const THE_LIST: Favorite[] = [{ symbol: 'TSLA', name: 'Tesla Inc', currency: 'USD' }];
const TSLA = THE_LIST[0] as Favorite;

/*
 * Verbatim from the *Avisos de estado* table of docs/design/COPY.md. Three of the four rows carry
 * a literal; the fourth is `ok`, whose cell says *(sin aviso)* -- and that one is checked by what
 * is **not** on screen, which is the only way it can be checked.
 */
const STALE = 'Mostrando la última cotización disponible: no se pudo consultar el proveedor.';
const MERCADO_CERRADO =
  /^El mercado está cerrado\. Se muestra la última rueda disponible: .*\d.*\.$/;
const SIN_COTIZACIONES = `No hay cotizaciones para ${TSLA.symbol} en el rango e intervalo seleccionados.`;

/** One candle as `GET /api/quotes/{symbol}` answers it: an instant in UTC and a price as string. */
interface QuotePoint {
  ts: string;
  price: string;
}

/** The body of `GET /api/quotes/{symbol}` (`plan.md` → *Contratos*), 200 in the four states. */
interface QuoteSeries {
  symbol: string;
  interval: string;
  status: 'ok' | 'stale' | 'market_closed' | 'no_data';
  session_date: string | null;
  points: QuotePoint[];
}

/** Five candles of a session, five minutes apart, as instants in UTC with their offset. */
const FIVE_CANDLES: QuotePoint[] = [
  { ts: '2026-09-11T19:40:00Z', price: '365.10000' },
  { ts: '2026-09-11T19:45:00Z', price: '365.22000' },
  { ts: '2026-09-11T19:50:00Z', price: '365.31000' },
  { ts: '2026-09-11T19:55:00Z', price: '365.43839' },
  { ts: '2026-09-11T20:00:00Z', price: '365.47000' },
];

/** The session the `market_closed` answer says it is showing, as the contract carries it. */
const THE_LAST_SESSION = '2026-09-11';

/** A series in whichever of the four states the test needs. */
function seriesOf(
  status: QuoteSeries['status'],
  points: QuotePoint[],
  sessionDate: string | null = null,
): QuoteSeries {
  return {
    symbol: TSLA.symbol,
    interval: '5min',
    status,
    session_date: sessionDate,
    points,
  };
}

/** What `GET /api/quotes/{symbol}` answers next. A test changes it to change the state. */
let theSeries: QuoteSeries = seriesOf('ok', FIVE_CANDLES);

/** The URL of a fetch call, whichever of the three shapes it was made with. */
function urlOf(input: RequestInfo | URL): string {
  if (typeof input === 'string') return input;
  if (input instanceof URL) return input.href;

  return input.url;
}

/**
 * Replace fetch: `/me` recognises the session, `/favorites` answers the list and
 * `/quotes/{symbol}` answers whatever the test set up -- always with 200, which is the contract of
 * The reason the screen has to read `status` to know what it got.
 */
function stubTheApi(): void {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockImplementation((input: RequestInfo | URL) => {
      const url = urlOf(input);

      if (url.includes(ME_URL)) {
        return Promise.resolve(new Response(JSON.stringify(WHO_IT_IS), { status: 200 }));
      }
      if (url.includes(FAVORITES_URL)) {
        return Promise.resolve(new Response(JSON.stringify(THE_LIST), { status: 200 }));
      }
      if (url.includes(QUOTES_URL)) {
        return Promise.resolve(new Response(JSON.stringify(theSeries), { status: 200 }));
      }

      return Promise.resolve(
        new Response(JSON.stringify({ detail: 'not authenticated' }), { status: 401 }),
      );
    }),
  );
}

/** Open the detail of a symbol at its own address, with a session already in the browser. */
function openTheDetail(symbol: string): { unmount: () => void } {
  writeStoredSession({
    token: A_TOKEN,
    fullName: FULL_NAME,
    expiresAt: Date.now() + 3_600_000,
  });

  return render(
    <MemoryRouter initialEntries={[`/stocks/${symbol}`]}>
      <App />
    </MemoryRouter>,
  );
}

/** The detail, once its controls are painted: everything else is read after this. */
async function theDetailOf(symbol: string): Promise<{ unmount: () => void }> {
  const mounted = openTheDetail(symbol);
  await screen.findByRole('button', { name: GRAFICAR });

  return mounted;
}

/** The interval selector, by the label the wireframe puts next to it. */
function theIntervalSelect(): HTMLSelectElement {
  return screen.getByRole('combobox', { name: new RegExp(INTERVALO) });
}

/** The chart's SVG, found by the axis title it writes, or `null` while there is no chart. */
function chartOrNull(): SVGSVGElement | null {
  const axisTitle = screen.queryByText(COTIZACION);

  return axisTitle?.closest('svg') ?? null;
}

/** The chart, once the series our API answered has been drawn. */
async function waitForTheChart(): Promise<SVGSVGElement> {
  const axisTitle = await screen.findByText(COTIZACION);
  const chart = axisTitle.closest('svg');

  if (!chart) {
    throw new Error(`the "${COTIZACION}" axis title is on screen but not inside a chart (RF-14)`);
  }

  return chart;
}

/** Whichever of the three notices is on screen, or `null` when none of them is. */
function noticeOrNull(): HTMLElement | null {
  return (
    screen.queryByText(STALE) ??
    screen.queryByText(MERCADO_CERRADO) ??
    screen.queryByText(SIN_COTIZACIONES)
  );
}

/** Choose an interval and press `Graficar`, which is the whole gesture of the wireframe. */
async function plotWith(interval: string): Promise<void> {
  const person = userEvent.setup();

  await person.selectOptions(theIntervalSelect(), interval);
  await person.click(screen.getByRole('button', { name: GRAFICAR }));
}

/** Open the detail, have our API answer this series, and plot. */
async function plotAnswering(series: QuoteSeries): Promise<{ unmount: () => void }> {
  const mounted = await theDetailOf(TSLA.symbol);
  theSeries = series;
  await plotWith('5min');

  return mounted;
}

/** Whether one node comes after another in the document, which is what "above" means here. */
function comesAfter(before: Element, after: Element): boolean {
  return Boolean(before.compareDocumentPosition(after) & Node.DOCUMENT_POSITION_FOLLOWING);
}

beforeEach(() => {
  sessionStorage.clear();
  theSeries = seriesOf('ok', FIVE_CANDLES);
  stubTheApi();
});

afterEach(() => {
  vi.unstubAllGlobals();
  sessionStorage.clear();
});

describe('a chart of a market that is closed', () => {
  it('explains that it is showing the last session there was, and which one', async () => {
    // It is the Sunday of the demo: the chart shows the last session available, and
    // the notice says which one, so an empty-looking screen is never mistaken for a broken one.
    await plotAnswering(seriesOf('market_closed', FIVE_CANDLES, THE_LAST_SESSION));

    expect(await screen.findByText(MERCADO_CERRADO)).toBeInTheDocument();
  });

  it('writes that date from the answer and not from the calendar of the machine', async () => {
    // Again: `{fecha}` is the `session_date` our API sent, in market time. A screen that
    // wrote "today" would say the wrong day every time somebody opens it on a Monday.
    await plotAnswering(seriesOf('market_closed', FIVE_CANDLES, THE_LAST_SESSION));

    const notice = await screen.findByText(MERCADO_CERRADO);
    expect(notice.textContent ?? '').toContain('11');
    expect(notice.textContent ?? '').toContain('2026');
  });

  it('puts that notice above the chart and not at its foot', async () => {
    // a notice qualifies the data that is about to be read, so it goes before it. At the
    // foot it is a footnote to something that has already been misread.
    await plotAnswering(seriesOf('market_closed', FIVE_CANDLES, THE_LAST_SESSION));

    const notice = await screen.findByText(MERCADO_CERRADO);
    const chart = await waitForTheChart();

    expect(comesAfter(notice, chart)).toBe(true);
  });
});

describe('a chart our API could not refresh', () => {
  it('says the quotes are the last ones available, in the words of the copy', async () => {
    // Verbatim.
    await plotAnswering(seriesOf('stale', FIVE_CANDLES));

    expect(await screen.findByText(STALE)).toBeInTheDocument();
  });

  it('never names who did not answer', async () => {
    // The person has no account with any provider, so the notice says what is
    // on screen and not whose fault it is. The copy already says `el proveedor`, in the common
    // noun and never by name.
    await plotAnswering(seriesOf('stale', FIVE_CANDLES));
    await screen.findByText(STALE);

    expect(document.body.textContent ?? '').not.toMatch(/twelvedata/i);
  });

  it('puts the stale notice above the chart too', async () => {
    // Again, for the state where there *is* a chart underneath: the notice is what says the
    // prices being read are not the latest ones.
    await plotAnswering(seriesOf('stale', FIVE_CANDLES));

    const notice = await screen.findByText(STALE);
    const chart = await waitForTheChart();

    expect(comesAfter(notice, chart)).toBe(true);
  });
});

describe('an action with no quotes at all for what was asked', () => {
  it('says which action has none, with the symbol inside the text', async () => {
    // the same screen can be open on another action, and a notice that did not name one
    // would be ambiguous exactly when it matters.
    await plotAnswering(seriesOf('no_data', []));

    expect(await screen.findByText(SIN_COTIZACIONES)).toBeInTheDocument();
  });

  it('shows that notice even though there is no chart to put it above', async () => {
    // Read on the one state where the chart may legitimately be missing: an empty screen
    // with nothing written on it is what reads as an application that broke.
    await plotAnswering(seriesOf('no_data', []));

    await screen.findByText(SIN_COTIZACIONES);
    expect(noticeOrNull()).not.toBeNull();
  });
});

describe('a chart whose quotes are up to date', () => {
  it('shows no notice at all', async () => {
    // A screen that always explains itself teaches people to stop reading the explanation,
    // and then the three notices that do mean something stop being read as well.
    await plotAnswering(seriesOf('ok', FIVE_CANDLES));
    await waitForTheChart();

    expect(screen.queryByText(STALE)).toBeNull();
    expect(screen.queryByText(MERCADO_CERRADO)).toBeNull();
    expect(screen.queryByText(SIN_COTIZACIONES)).toBeNull();
    expect(noticeOrNull()).toBeNull();
  });

  it('still shows the chart, which is the whole point of saying nothing', async () => {
    // On the happy path: `ok` keeps the invariant by having the chart, not the notice.
    await plotAnswering(seriesOf('ok', FIVE_CANDLES));

    expect(await waitForTheChart()).toBeInTheDocument();
  });
});

describe('the four states, one after another', () => {
  it('never leaves the screen with neither a chart nor a notice', async () => {
    // The invariant of the feature: something is always shown, and something always
    // explains it -- a chart, a notice, or both. Each state gets a screen of its own, so that what
    // is on it was drawn by that state and is not left over from the one before.
    const states: QuoteSeries[] = [
      seriesOf('ok', FIVE_CANDLES),
      seriesOf('stale', FIVE_CANDLES),
      seriesOf('market_closed', FIVE_CANDLES, THE_LAST_SESSION),
      seriesOf('no_data', []),
    ];

    for (const state of states) {
      const mounted = await plotAnswering(state);

      await waitFor(() => {
        expect(
          chartOrNull() !== null || noticeOrNull() !== null,
          `with status "${state.status}" the screen shows neither a chart nor a notice (RF-33)`,
        ).toBe(true);
      });

      mounted.unmount();
      sessionStorage.clear();
    }
  });
});
