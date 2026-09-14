/**
 * `Detalle de Acción` -- wireframe 03, H1, looked at through the screen.
 *
 * The screen is opened the way a person opens it: the application is mounted at an address, with a
 * session restored from the browser, and everything else is read off what is painted. Nothing here
 * imports `ActionDetail`, `QuoteChart` or `api/quotes` -- which of those draws a given control is
 * an internal arrangement of `plan.md`, and a test that fixed it would go red the day somebody
 * moves a control between two components without the screen changing for anybody.
 *
 * **Scope.** This file is task 3 of `tasks.md`: the screen of H1 -- the header, the two ways of
 * asking, the interval selector, `Graficar`, the chart it draws and the one invalid query of this
 * story. The refresh of H2 lives in `quoteRefresh.test.tsx`, the date fields and the range
 * failures of H3 in `quoteHistoric.test.tsx`, the notices of H4 in `quoteNotice.test.tsx`, and
 * that this address with no session lands on the login (RF-02) in `session.test.tsx`, where
 * `tasks.md` puts it.
 *
 * Today every test here is red because `/stocks/:symbol` has nothing behind it: `002` has not been
 * implemented either, so the address falls through to `Mis Acciones`. That is the intended red --
 * absence of implementation -- and it is told apart from a broken test by what the assertion says
 * it could not find: a control of wireframe 03, by its role or by its text.
 *
 * **What the chart can be asked in jsdom.** Highcharts draws into an SVG and gives no roles: what
 * a test can see is the *text* it writes -- the title, the two axis titles -- and the identity of
 * the node it drew into. So "there is a chart" here means "the vertical axis title `Cotización` is
 * on screen", and "it was not remounted" means the SVG that carries it is the same node as before
 * (RF-19). The point-level requirements -- each point at its own market hour (RF-15, RF-36) and
 * the tooltip with the two hours (RF-38) -- are *not* asserted here: they live inside the SVG
 * layout, which jsdom does not compute, and `plan.md` names `src/quotes/market.ts` and its two
 * formatters without fixing their signatures, so a unit test of them would have to invent one.
 * They are reported as an escalation rather than written as a test that could only go green by
 * accident (`add_tests`: if the plan does not name what is going to be called, it goes back to
 * `/plan`).
 *
 * `fetch` is replaced in every test and restored afterwards: a frontend test that goes to the
 * network is not a frontend test (`add_tests`, `TEST-03`).
 */

import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { App } from '../src/App';
import { writeStoredSession } from '../src/auth/storage';

// Verbatim from the `Detalle de Acción` table of docs/design/COPY.md (UI-02). The two parenthesised
// notes carry the misspellings of the brief on purpose -- `opcion` and `segun`, with no accent --
// and a test that "fixed" them would be asking for the opposite of what the client signed.
const TIEMPO_REAL = 'Tiempo Real';
const ACLARACION_TIEMPO_REAL =
  '( utiliza la fecha actual, al graficar esta opcion, se debe actualizar el gráfico en forma ' +
  'automática segun el intervalo seleccionado)';
const HISTORICO = 'Histórico';
const INTERVALO = 'Intervalo';
const ACLARACION_INTERVALO = '( opciones 1min / 5min / 15min)';
const GRAFICAR = 'Graficar';
const COTIZACION = 'Cotización';

// Verbatim from *Detalle: navegación, horarios y validación* of docs/design/COPY.md.
const MIS_ACCIONES = 'Mis Acciones';
const HORARIOS = 'Horarios en hora del mercado.';
const ELEGI_INTERVALO = 'Elegí un intervalo.';

const ME_URL = '/api/auth/me';
const FAVORITES_URL = '/api/favorites';
const QUOTES_URL = '/api/quotes';

const FULL_NAME = 'Juan Perez';
const A_SESSION = {
  access_token: 'a.signed.token',
  token_type: 'bearer',
  expires_in: 3600,
  full_name: FULL_NAME,
};
const WHO_IT_IS = { id: 1, full_name: FULL_NAME };

/** One row of `GET /api/favorites` (`002` → *Contratos*), which is where the header comes from. */
interface Favorite {
  symbol: string;
  name: string;
  currency: string;
}

/** The favourites of the demo user. `MSFT` is deliberately not one of them (RF-35). */
const THE_LIST: Favorite[] = [
  { symbol: 'TSLA', name: 'Tesla Inc', currency: 'USD' },
  { symbol: 'AAPL', name: 'Apple Inc', currency: 'USD' },
];

const TSLA = THE_LIST[0] as Favorite;
/** RF-01, assembled the way `COPY.md` writes it: `{símbolo} - {nombre} - {moneda}`. */
const TSLA_HEADER = `${TSLA.symbol} - ${TSLA.name} - ${TSLA.currency}`;

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

/**
 * Five candles of a session, five minutes apart.
 *
 * The instants are UTC with offset, which is what the contract says travels on the wire; the
 * market hour they correspond to is four hours earlier, and turning one into the other is the
 * screen's job and not this file's.
 */
const FIVE_CANDLES: QuotePoint[] = [
  { ts: '2026-09-11T19:40:00Z', price: '365.10000' },
  { ts: '2026-09-11T19:45:00Z', price: '365.22000' },
  { ts: '2026-09-11T19:50:00Z', price: '365.31000' },
  { ts: '2026-09-11T19:55:00Z', price: '365.43839' },
  { ts: '2026-09-11T20:00:00Z', price: '365.47000' },
];

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

/** Every call our API received for a series, so a test can count them and read their address. */
let quoteCalls: { url: string; signal: AbortSignal | null }[] = [];

/** How many times the screen asked our API for the list of favourites. */
let listCalls = 0;

/** The URL of a fetch call, whichever of the three shapes it was made with. */
function urlOf(input: RequestInfo | URL): string {
  if (typeof input === 'string') return input;
  if (input instanceof URL) return input.href;

  return input.url;
}

/**
 * Replace fetch: the login succeeds, `/me` recognises the session, `/favorites` answers the list
 * and `/quotes/{symbol}` answers whatever the test set up.
 *
 * Anything else is refused, so a call this feature never agreed to make shows up as a failure and
 * not as a silent success.
 */
function stubTheApi(favorites: Favorite[] = THE_LIST): void {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockImplementation((input: RequestInfo | URL, init?: RequestInit) => {
      const url = urlOf(input);

      if (url.includes(ME_URL)) {
        return Promise.resolve(new Response(JSON.stringify(WHO_IT_IS), { status: 200 }));
      }
      if (url.includes(FAVORITES_URL)) {
        listCalls += 1;

        return Promise.resolve(new Response(JSON.stringify(favorites), { status: 200 }));
      }
      if (url.includes(QUOTES_URL)) {
        quoteCalls.push({ url, signal: init?.signal ?? null });

        return Promise.resolve(new Response(JSON.stringify(theSeries), { status: 200 }));
      }

      return Promise.resolve(
        new Response(JSON.stringify({ detail: 'not authenticated' }), { status: 401 }),
      );
    }),
  );
}

/** Open the application at an address, the way pasting one in the browser does. */
function openAt(address: string): { unmount: () => void } {
  return render(
    <MemoryRouter initialEntries={[address]}>
      <App />
    </MemoryRouter>,
  );
}

/**
 * Open the detail of a symbol at its own address, with a session already in the browser.
 *
 * The session is left where a reload leaves it -- `sessionStorage`, through the module of `001`
 * that owns it -- instead of being typed into the login on the way to every test here. What is
 * being tested is wireframe 03 and not the door: `Login.test.tsx` and `session.test.tsx` own the
 * door, and walking through it fifty times would add a minute to the suite to re-prove what they
 * already prove. That an address opened with no session lands on the login is RF-02, and it lives
 * in `session.test.tsx`.
 */
function openTheDetail(symbol: string): { unmount: () => void } {
  writeStoredSession({
    token: A_SESSION.access_token,
    fullName: FULL_NAME,
    expiresAt: Date.now() + A_SESSION.expires_in * 1000,
  });

  return openAt(`/stocks/${symbol}`);
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

/** The chart, failing by name when there is none. */
function theChart(): SVGSVGElement {
  const chart = chartOrNull();

  if (!chart) {
    throw new Error(
      `there is no chart on screen: nothing writes the "${COTIZACION}" axis title (RF-14)`,
    );
  }

  return chart;
}

/** The chart, once the series our API answered has been drawn. */
async function waitForTheChart(): Promise<SVGSVGElement> {
  await screen.findByText(COTIZACION);

  return theChart();
}

/** How many times the screen asked our API for a series. */
function timesAskedForASeries(): number {
  return quoteCalls.length;
}

/** How many times the screen asked our API for the list of favourites. */
function timesAskedForTheList(): number {
  return listCalls;
}
/** Choose an interval and press `Graficar`, which is the whole gesture of the wireframe. */
async function plotWith(interval: string): Promise<void> {
  const person = userEvent.setup();

  await person.selectOptions(theIntervalSelect(), interval);
  await person.click(screen.getByRole('button', { name: GRAFICAR }));
}

beforeEach(() => {
  sessionStorage.clear();
  quoteCalls = [];
  listCalls = 0;
  theSeries = seriesOf('ok', FIVE_CANDLES);
  stubTheApi();
});

afterEach(() => {
  vi.unstubAllGlobals();
  sessionStorage.clear();
});

describe('the header of the detail', () => {
  it('shows the symbol, the name and the currency of the action that was opened', async () => {
    // RF-01, and the three values are the ones `GET /api/favorites` answered: the header is not
    // assembled from the address, which carries only the symbol.
    await theDetailOf(TSLA.symbol);

    expect(screen.getByRole('heading', { name: TSLA_HEADER })).toBeInTheDocument();
  });

  it('is one bar and not two: whoever is logged in appears once', async () => {
    // The detail reuses the `Header` of `001` (`plan.md`), it does not draw a second bar. A screen
    // with two bars shows `Usuario: {nombre completo}` twice, which is what this notices.
    await theDetailOf(TSLA.symbol);

    expect(screen.getAllByText(`Usuario: ${FULL_NAME}`)).toHaveLength(1);
  });

  it('offers the way back to the list as a link, and it goes there', async () => {
    // RF-34. A link and not a `<span>` with an `onClick`: the way back has to be reachable by its
    // role, which is how it is reachable with a keyboard.
    await theDetailOf(TSLA.symbol);

    const person = userEvent.setup();
    await person.click(screen.getByRole('link', { name: MIS_ACCIONES }));

    expect(await screen.findByRole('heading', { name: MIS_ACCIONES })).toBeInTheDocument();
  });

  it('says which clock the hours on this screen are told in', async () => {
    // RF-37, verbatim. An axis that starts at 09:30 has to say which clock it is talking about.
    await theDetailOf(TSLA.symbol);

    expect(screen.getByText(HORARIOS)).toBeInTheDocument();
  });
});

describe('the detail of an action that is not in the list of whoever asked', () => {
  it('leaves the person on Mis Acciones, with no chart to press', async () => {
    // RF-35. `MSFT` is not among the favourites the API answered, so the address does not open a
    // screen: it sends the visitor back to the list. The list is asked for first -- whose the
    // symbol is is not something the address can answer -- and that call is what tells a decision
    // apart from an address that simply leads nowhere.
    openTheDetail('MSFT');

    expect(await screen.findByRole('heading', { name: MIS_ACCIONES })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: GRAFICAR })).toBeNull();
    await waitFor(() => {
      expect(timesAskedForTheList()).toBeGreaterThan(0);
    });
  });
});

describe('the two ways of asking, as the wireframe draws them', () => {
  it('offers Tiempo Real and Histórico, and only one of them at a time', async () => {
    // RF-03. Two radios of the same group: marking one unmarks the other, which a pair of
    // checkboxes would not do.
    await theDetailOf(TSLA.symbol);

    const realtime = screen.getByRole('radio', { name: new RegExp(TIEMPO_REAL) });
    const historic = screen.getByRole('radio', { name: new RegExp(HISTORICO) });

    const person = userEvent.setup();
    await person.click(historic);

    expect(historic).toBeChecked();
    expect(realtime).not.toBeChecked();
  });

  it('opens with Tiempo Real already marked', async () => {
    // RF-04, which is what makes the first plot of the screen the one the brief describes.
    await theDetailOf(TSLA.symbol);

    expect(screen.getByRole('radio', { name: new RegExp(TIEMPO_REAL) })).toBeChecked();
    expect(screen.getByRole('radio', { name: new RegExp(HISTORICO) })).not.toBeChecked();
  });

  it('writes the note of the brief next to Tiempo Real, misspellings and all', async () => {
    // RF-05, verbatim from COPY.md: `opcion` and `segun` have no accent in the brief, and this is
    // what stops somebody from "fixing" them on the way to the screen (UI-02, Article VII).
    await theDetailOf(TSLA.symbol);

    expect(screen.getByText(ACLARACION_TIEMPO_REAL)).toBeInTheDocument();
  });
});

describe('the interval selector', () => {
  it('offers the three intervals of the brief, and nothing else', async () => {
    // RF-06. The empty option the selector opens on is not one of the three: what is asserted is
    // that the choices with a value are exactly the ones the brief names.
    await theDetailOf(TSLA.symbol);

    const options = Array.from(theIntervalSelect().options)
      .map((option) => option.text.trim())
      .filter((text) => text !== '');

    expect(options).toEqual(['1min', '5min', '15min']);
  });

  it('opens with nothing chosen', async () => {
    // RF-07, and it is the wireframe read literally: the selector is drawn empty. It is also what
    // keeps opening the screen from costing a call to the provider (Article II).
    await theDetailOf(TSLA.symbol);

    expect(theIntervalSelect().value).toBe('');
  });

  it('carries the note of the brief next to it', async () => {
    // RF-08, verbatim: `( opciones 1min / 5min / 15min)`, with the spacing the wireframe has.
    await theDetailOf(TSLA.symbol);

    expect(screen.getByText(ACLARACION_INTERVALO)).toBeInTheDocument();
  });
});

describe('the detail before anybody presses Graficar', () => {
  it('offers the button', async () => {
    // RF-11.
    await theDetailOf(TSLA.symbol);

    expect(screen.getByRole('button', { name: GRAFICAR })).toBeInTheDocument();
  });

  it('shows no chart, not even an empty one', async () => {
    // RF-12. An empty plotting area is still a chart on screen, and the wireframe draws the space
    // below the controls with nothing in it until the button is pressed.
    await theDetailOf(TSLA.symbol);

    expect(screen.queryByText(COTIZACION)).toBeNull();
    expect(chartOrNull()).toBeNull();
  });

  it('asks our API for nothing', async () => {
    // RF-12 again, on the side that costs money: opening the screen does not spend a request, and
    // therefore cannot spend a credit of the provider's quota (Article II).
    await theDetailOf(TSLA.symbol);

    expect(timesAskedForASeries()).toBe(0);
  });
});

describe('Graficar in Tiempo Real', () => {
  it('draws the chart the brief describes: the symbol on top and the two axes named', async () => {
    // RF-14. The three texts are the ones `COPY.md` fixes for the chart, and they are what a
    // person reads on it: the title, the vertical axis and the horizontal one.
    await theDetailOf(TSLA.symbol);

    await plotWith('5min');

    const chart = await waitForTheChart();
    expect(chart.textContent).toContain(TSLA.symbol);
    expect(chart.textContent).toContain(COTIZACION);
    expect(chart.textContent).toContain(INTERVALO);
  });

  it('asks our API for the chosen interval, and for today', async () => {
    // The realtime window is the backend's decision (`plan.md` → *Contratos*): the screen asks for
    // the symbol and the interval and sends no `from`/`to`, which is what makes it "today".
    await theDetailOf(TSLA.symbol);

    await plotWith('5min');
    await waitForTheChart();

    const asked = quoteCalls.at(-1)?.url ?? '';
    expect(asked).toContain(`${QUOTES_URL}/${TSLA.symbol}`);
    expect(asked).toContain('interval=5min');
    expect(asked).not.toContain('from=');
    expect(asked).not.toContain('to=');
  });

  it('asks our API and never the provider', async () => {
    // RF-26 and Article I from the browser's side: every call this screen makes is origin-relative
    // and goes to `/api`. A screen that knew the provider's address would show up here.
    await theDetailOf(TSLA.symbol);

    await plotWith('5min');
    await waitForTheChart();

    for (const call of quoteCalls) {
      expect(call.url.startsWith(QUOTES_URL)).toBe(true);
    }
  });

  it('replaces the chart when it is pressed again, instead of stacking a second one', async () => {
    // RF-17. Two charts one under the other is the failure this describes, and counting the axis
    // title is what tells it apart from one chart redrawn.
    await theDetailOf(TSLA.symbol);

    await plotWith('5min');
    await waitForTheChart();
    await plotWith('15min');

    await waitFor(() => {
      expect(screen.getAllByText(COTIZACION)).toHaveLength(1);
    });
  });

  it('brings none of what Highcharts turns on and the spec leaves out', async () => {
    // UI-01. Zoom, range selection, the export menu and the credit at the foot come switched on
    // and are out of scope: a screen that offers them does something nobody asked for.
    await theDetailOf(TSLA.symbol);

    await plotWith('5min');
    const chart = await waitForTheChart();

    expect(chart.textContent).not.toContain('Highcharts.com');
    expect(screen.queryByRole('button', { name: /menu/i })).toBeNull();
  });
});

describe('Graficar with no interval chosen', () => {
  it('says which choice is missing, right under the selector', async () => {
    // RF-39, verbatim. Under the selector and not above the chart: there is no data yet, and the
    // notices above the chart are the ones that qualify data (UI-05).
    await theDetailOf(TSLA.symbol);

    const person = userEvent.setup();
    await person.click(screen.getByRole('button', { name: GRAFICAR }));

    const notice = await screen.findByText(ELEGI_INTERVALO);
    const position = theIntervalSelect().compareDocumentPosition(notice);
    expect(position & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  });

  it('asks our API for nothing, so the provider is never reached', async () => {
    // RF-47. A query that cannot be made does not travel: it is stopped on the screen, before
    // there is a request to answer.
    await theDetailOf(TSLA.symbol);

    const person = userEvent.setup();
    await person.click(screen.getByRole('button', { name: GRAFICAR }));
    await screen.findByText(ELEGI_INTERVALO);

    expect(timesAskedForASeries()).toBe(0);
  });

  it('draws no chart', async () => {
    // RF-46.
    await theDetailOf(TSLA.symbol);

    const person = userEvent.setup();
    await person.click(screen.getByRole('button', { name: GRAFICAR }));
    await screen.findByText(ELEGI_INTERVALO);

    expect(chartOrNull()).toBeNull();
  });

  it('leaves the chart that was already there exactly as it was', async () => {
    // RF-48, and it is the same invariant the three range failures of H3 have: an invalid query
    // does not touch what is on screen. The node is compared by identity, because a chart redrawn
    // from scratch "looks right" and is not what the requirement says.
    await theDetailOf(TSLA.symbol);

    await plotWith('5min');
    const before = await waitForTheChart();
    const callsBefore = timesAskedForASeries();

    const person = userEvent.setup();
    await person.selectOptions(theIntervalSelect(), '');
    await person.click(screen.getByRole('button', { name: GRAFICAR }));
    await screen.findByText(ELEGI_INTERVALO);

    expect(theChart()).toBe(before);
    expect(timesAskedForASeries()).toBe(callsBefore);
  });
});
