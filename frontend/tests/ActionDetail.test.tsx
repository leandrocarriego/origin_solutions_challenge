/**
 * `Detalle de Acción` -- wireframe 03, looked at through the screen.
 *
 * The screen is opened the way a person opens it: the application is mounted at an address, with a
 * session restored from the browser, and everything else is read off what is painted. Nothing here
 * imports `ActionDetail`, `QuoteChart` or `api/quotes` -- which of those draws a given control is
 * an internal arrangement of `plan.md`, and a test that fixed it would go red the day somebody
 * moves a control between two components without the screen changing for anybody.
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
 * layout, which jsdom does not compute, and `src/quotes/market.ts` (where the two formatters live)
 * does not exist yet, so a unit test of them cannot even be imported. They are reported as an
 * escalation rather than written as a test that could only go green by accident.
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

const FECHA_DESDE = 'Fecha hora desde';
const FECHA_HASTA = 'Fecha hora hasta';

// Verbatim from *Detalle: navegación, horarios y validación* of docs/design/COPY.md.
const MIS_ACCIONES = 'Mis Acciones';
const HORARIOS = 'Horarios en hora del mercado.';
const ELEGI_INTERVALO = 'Elegí un intervalo.';
const FECHAS_AL_REVES = 'La fecha desde tiene que ser anterior a la fecha hasta.';
const RANGO_EXCEDIDO_1MIN =
  'El rango es demasiado largo para el intervalo 1min. El máximo es 7 días.';

// Verbatim from *Sesión y validación*: an empty field is the same oversight on both screens, and
// the client deliberately gave it one text and not two (`COPY.md`).
const COMPLETA_ESTE_CAMPO = 'Completá este campo.';

const ME_URL = '/api/auth/me';
const FAVORITES_URL = '/api/favorites';
const QUOTES_URL = '/api/quotes';

/** The button of the login, which is what a visitor with no session is left looking at (RF-02). */
const INGRESAR = 'Ingresar';

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

/**
 * A refusal our API answers instead of a series, or `null` while it answers one.
 *
 * The two failures of the range are decided by the backend and not by the screen (`plan.md`: a
 * rule of the business duplicated on both ends is a rule that one day disagrees with itself), so
 * what the screen owes is to turn the `code` of a 422 into the text of `COPY.md`.
 */
let theRefusal: { status: number; body: unknown } | null = null;

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

        if (theRefusal) {
          return Promise.resolve(
            new Response(JSON.stringify(theRefusal.body), { status: theRefusal.status }),
          );
        }

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

/**
 * One of the two date fields, by its label or -- as the wireframe draws it -- by the text inside.
 *
 * The wireframe writes `Fecha hora desde` *inside* the box, so a screen that draws it as a
 * placeholder is reproducing the wireframe and one that adds a `<label>` is doing better; both are
 * ways of saying which end of the range the field is, and both are found here. A field that can be
 * found by neither is one nobody using a screen reader can fill, which is a finding about the
 * screen and not about this test.
 */
function dateField(name: string): HTMLInputElement {
  const labelled = screen.queryByLabelText<HTMLInputElement>(name);
  if (labelled) return labelled;

  return screen.getByPlaceholderText(name);
}

/** One minute, in milliseconds: the shortest interval the brief offers (`1min`). */
const ONE_MINUTE = 60_000;

/** Put the tab in the background, the way changing to another tab does (RF-21). */
function hideTheTab(): void {
  Object.defineProperty(document, 'visibilityState', {
    configurable: true,
    get: () => 'hidden',
  });
  document.dispatchEvent(new Event('visibilitychange'));
}

/** Come back to the tab (RF-22). */
function showTheTab(): void {
  Object.defineProperty(document, 'visibilityState', {
    configurable: true,
    get: () => 'visible',
  });
  document.dispatchEvent(new Event('visibilitychange'));
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
  theRefusal = null;
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

describe('the address of the detail pasted into a browser with no session', () => {
  it('leaves the visitor on the login and not on the chart', async () => {
    // RF-02. `tasks.md` puts this in `session.test.tsx`, which was signed in `001` and is not
    // reopened here: the guard it describes is the same one, read at this address. It is green
    // today -- with no route behind it the address already falls through to the guard -- so what
    // it buys is that it stays true the day `/stocks/:symbol` becomes a screen of its own.
    sessionStorage.clear();

    openAt(`/stocks/${TSLA.symbol}`);

    expect(await screen.findByRole('button', { name: INGRESAR })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: GRAFICAR })).toBeNull();
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

/**
 * H2 -- the chart keeps itself up to date while somebody is looking at it.
 *
 * The timers are the test's: `vi.useFakeTimers` is what turns "a minute goes by" into an assertion
 * that runs in milliseconds and always says the same thing. `shouldAdvanceTime` is on so that
 * Testing Library's waiting still works while the clock is ours.
 *
 * What is asserted about a refresh is what distinguishes the requirement from something that
 * merely looks right: **the chart node is the same one** (RF-19). A screen that threw the chart
 * away and drew a new one every interval would show the same points and flicker once a minute,
 * and no assertion about content would notice.
 */
describe('a chart of Tiempo Real that is left on screen', () => {
  /** Open the detail, plot, and hand the clock to the test from the moment of the first plot. */
  async function plotAndTakeTheClock(interval: string): Promise<SVGSVGElement> {
    await theDetailOf(TSLA.symbol);
    vi.useFakeTimers({ shouldAdvanceTime: true });
    await plotWith(interval);

    return await waitForTheChart();
  }

  afterEach(() => {
    vi.useRealTimers();
  });

  it('asks our API again once the chosen interval has gone by', async () => {
    // RF-18. One interval, one request: the screen refreshes on the rhythm the person chose, and
    // not on one of its own.
    await plotAndTakeTheClock('1min');
    const asked = timesAskedForASeries();

    await vi.advanceTimersByTimeAsync(ONE_MINUTE);

    expect(timesAskedForASeries()).toBe(asked + 1);
  });

  it('draws the refresh into the chart that is already there', async () => {
    // RF-19, and it is the heart of this story: the same node, not an equivalent one. `setData`
    // on the chart that exists is what makes the update invisible; a remount "works" and blinks.
    const chart = await plotAndTakeTheClock('1min');

    await vi.advanceTimersByTimeAsync(ONE_MINUTE);

    expect(theChart()).toBe(chart);
  });

  it('keeps asking for the whole session, so nothing that was drawn is dropped', async () => {
    // RF-20. The realtime answer is the whole session (`plan.md` → *Alternativas descartadas*):
    // the screen does not ask for "what is new", which is where a chart loses its left-hand side.
    await plotAndTakeTheClock('1min');

    await vi.advanceTimersByTimeAsync(ONE_MINUTE);

    const refresh = quoteCalls.at(-1)?.url ?? '';
    expect(refresh).toContain('interval=1min');
    expect(refresh).not.toContain('from=');
    expect(refresh).not.toContain('to=');
  });

  it('refreshes on the interval that was chosen, and not on another one', async () => {
    // RF-18 again, with the interval changed: at `5min` a minute is not a refresh. A screen that
    // polled on a fixed rhythm would pass the test above and spend five times the quota here.
    await plotAndTakeTheClock('5min');
    const asked = timesAskedForASeries();

    await vi.advanceTimersByTimeAsync(ONE_MINUTE);
    expect(timesAskedForASeries()).toBe(asked);

    await vi.advanceTimersByTimeAsync(4 * ONE_MINUTE);
    expect(timesAskedForASeries()).toBe(asked + 1);
  });

  it('stops asking while the tab is not being looked at', async () => {
    // RF-21, and Article II: a forgotten tab renewing the TTL of its symbol all session long is
    // quota spent by nobody.
    await plotAndTakeTheClock('1min');
    const asked = timesAskedForASeries();

    hideTheTab();
    await vi.advanceTimersByTimeAsync(3 * ONE_MINUTE);

    expect(timesAskedForASeries()).toBe(asked);
  });

  it('catches up as soon as the tab is looked at again', async () => {
    // RF-22. Coming back asks immediately -- waiting a whole interval would show a chart that is
    // visibly out of date -- and arms the timer again, which the second half checks.
    await plotAndTakeTheClock('1min');
    hideTheTab();
    await vi.advanceTimersByTimeAsync(3 * ONE_MINUTE);
    const asked = timesAskedForASeries();

    showTheTab();
    await vi.advanceTimersByTimeAsync(0);
    expect(timesAskedForASeries()).toBe(asked + 1);

    await vi.advanceTimersByTimeAsync(ONE_MINUTE);
    expect(timesAskedForASeries()).toBe(asked + 2);
  });

  it('stops asking when the screen is left', async () => {
    // The leak nobody sees: an interval that survives its screen keeps spending requests for a
    // chart that is not on screen any more.
    await theDetailOf(TSLA.symbol);
    vi.useFakeTimers({ shouldAdvanceTime: true });
    await plotWith('1min');
    await waitForTheChart();

    const person = userEvent.setup();
    await person.click(screen.getByRole('link', { name: MIS_ACCIONES }));
    const asked = timesAskedForASeries();

    await vi.advanceTimersByTimeAsync(3 * ONE_MINUTE);

    expect(timesAskedForASeries()).toBe(asked);
  });

  it('cancels the request in flight when the interval changes', async () => {
    // The answer to a question nobody is asking any more must not land on the chart: at `5min`
    // the reply to the `1min` request is a series of another shape. `plan.md` says every request
    // cancels the previous one with an `AbortController`, so the signal of the first call is
    // aborted once the second one starts.
    await plotAndTakeTheClock('1min');
    const first = quoteCalls[0];

    await plotWith('5min');
    await waitForTheChart();

    expect(first?.signal?.aborted).toBe(true);
  });
});

describe('a chart of Histórico that is left on screen', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it('is never refreshed on its own', async () => {
    // RF-23. A period that already ended does not change, so no timer is armed for it: this is
    // the other half of RF-18, and the one that quietly spends quota if it is got wrong.
    await theDetailOf(TSLA.symbol);

    const person = userEvent.setup();
    await person.click(screen.getByRole('radio', { name: new RegExp(HISTORICO) }));

    vi.useFakeTimers({ shouldAdvanceTime: true });
    await plotWith('1min');
    await waitForTheChart();
    const asked = timesAskedForASeries();

    await vi.advanceTimersByTimeAsync(10 * ONE_MINUTE);

    expect(timesAskedForASeries()).toBe(asked);
  });
});

/**
 * H3 -- asking for a period that already went by.
 *
 * The clock is the test's here too, and for a different reason than in H2: the two date fields
 * come already filled with the last 24 hours **of market time** (RF-10), so what they say depends
 * on when the screen was opened. With the system time fixed, that becomes an assertion.
 *
 * What the fields are asserted against is *the market hour*, not the hour of the machine running
 * the suite: the whole point of RF-36 is that the screen tells the time on the exchange's clock.
 * The format is left alone on purpose -- the plan fixes neither `datetime-local` nor a mask -- so
 * each value is required to carry the day, the month, the year and the hour of the instant it
 * stands for, and nothing is said about the order they are written in.
 */
describe('the two date fields of Histórico', () => {
  /** An instant inside a session: 15:55 on the market clock, which is 19:55 UTC. */
  const WHEN_IT_WAS_OPENED = new Date('2026-09-11T19:55:00Z');

  /** Day, month, year and hour of an instant, as the market's clock tells them. */
  function marketParts(instant: Date): { day: string; month: string; year: string; time: string } {
    const parts = new Intl.DateTimeFormat('en-CA', {
      timeZone: 'America/New_York',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hourCycle: 'h23',
    }).formatToParts(instant);

    const part = (type: string): string => parts.find((one) => one.type === type)?.value ?? '';

    return {
      day: part('day'),
      month: part('month'),
      year: part('year'),
      time: `${part('hour')}:${part('minute')}`,
    };
  }

  /** Whether a field carries the instant it should, whichever way it writes it down. */
  function expectFieldToCarry(field: HTMLInputElement, instant: Date): void {
    const { day, month, year, time } = marketParts(instant);

    expect(field.value).toContain(year);
    expect(field.value).toContain(month);
    expect(field.value).toContain(day);
    expect(field.value).toContain(time);
  }

  beforeEach(() => {
    vi.useFakeTimers({ shouldAdvanceTime: true, now: WHEN_IT_WAS_OPENED });
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('are both on screen, each saying which end of the range it is', async () => {
    // RF-09, verbatim: `Fecha hora desde` and `Fecha hora hasta`. A field that can be found by
    // neither its label nor the text inside it is a field nobody using a screen reader can fill.
    await theDetailOf(TSLA.symbol);

    expect(dateField(FECHA_DESDE)).toBeInTheDocument();
    expect(dateField(FECHA_HASTA)).toBeInTheDocument();
  });

  it('come already filled with the last 24 hours of market time', async () => {
    // RF-10, which is A6 resolved: nobody has to type a date to get a chart out of `Histórico`,
    // and the two values are told in the market's hour and not in the machine's (RF-36).
    await theDetailOf(TSLA.symbol);

    const twentyFourHoursEarlier = new Date(WHEN_IT_WAS_OPENED.getTime() - 24 * 60 * ONE_MINUTE);

    expectFieldToCarry(dateField(FECHA_DESDE), twentyFourHoursEarlier);
    expectFieldToCarry(dateField(FECHA_HASTA), WHEN_IT_WAS_OPENED);
  });

  it('are the window the screen asks our API for', async () => {
    // The two fields are not decoration: what they carry is what travels, and it travels as the
    // person wrote it -- market time -- for the backend to localise (`plan.md` → *Contratos*).
    await theDetailOf(TSLA.symbol);

    const person = userEvent.setup();
    await person.click(screen.getByRole('radio', { name: new RegExp(HISTORICO) }));
    await plotWith('15min');
    await waitForTheChart();

    const asked = quoteCalls.at(-1)?.url ?? '';
    expect(asked).toContain('interval=15min');
    expect(asked).toContain('from=');
    expect(asked).toContain('to=');
  });
});

describe('Graficar in Histórico with a date field left empty', () => {
  /** Open the detail in `Histórico`, with an interval chosen and one of the fields emptied. */
  async function emptyTheField(name: string): Promise<HTMLInputElement> {
    await theDetailOf(TSLA.symbol);

    const person = userEvent.setup();
    await person.click(screen.getByRole('radio', { name: new RegExp(HISTORICO) }));
    await person.selectOptions(theIntervalSelect(), '1min');

    const field = dateField(name);
    await person.clear(field);

    return field;
  }

  it('says what is missing, under the field that is missing it', async () => {
    // RF-40, and the text is the one the login already uses for an empty field: the client wrote
    // one text for the same oversight, not two (`COPY.md`). Under *that* field, because that is
    // the one that has to be corrected.
    const field = await emptyTheField(FECHA_HASTA);

    const person = userEvent.setup();
    await person.click(screen.getByRole('button', { name: GRAFICAR }));

    const notice = await screen.findByText(COMPLETA_ESTE_CAMPO);
    const position = field.compareDocumentPosition(notice);
    expect(position & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  });

  it('asks our API for nothing', async () => {
    // RF-47: a missing field is presence, which the screen resolves on its own -- there is not
    // even a request to build, so no credit of the provider's quota can be spent on it.
    await emptyTheField(FECHA_DESDE);

    const person = userEvent.setup();
    await person.click(screen.getByRole('button', { name: GRAFICAR }));
    await screen.findByText(COMPLETA_ESTE_CAMPO);

    expect(timesAskedForASeries()).toBe(0);
  });

  it('draws no chart', async () => {
    // RF-46.
    await emptyTheField(FECHA_DESDE);

    const person = userEvent.setup();
    await person.click(screen.getByRole('button', { name: GRAFICAR }));
    await screen.findByText(COMPLETA_ESTE_CAMPO);

    expect(chartOrNull()).toBeNull();
  });
});

describe('Graficar in Histórico with a range our API refuses', () => {
  /** Plot in `Histórico` while our API answers the refusal the test set up. */
  async function plotAndBeRefused(refusal: { status: number; body: unknown }): Promise<void> {
    await theDetailOf(TSLA.symbol);

    const person = userEvent.setup();
    await person.click(screen.getByRole('radio', { name: new RegExp(HISTORICO) }));

    theRefusal = refusal;
    await plotWith('1min');
  }

  it('says the dates are the wrong way round, in the words of the copy', async () => {
    // RF-41. The rule lives in the backend and only there (`plan.md`: a rule of the business
    // written on both ends is a rule that one day disagrees with itself), so what the screen owes
    // is turning `range_invalid` into the text the client wrote.
    await plotAndBeRefused({ status: 422, body: { detail: { code: 'range_invalid' } } });

    expect(await screen.findByText(FECHAS_AL_REVES)).toBeInTheDocument();
  });

  it('says how long the range may be, with the interval and the number of the answer', async () => {
    // RF-45. `{intervalo}` and `{N}` are filled in from the body and not from a copy of the limits
    // kept in the browser: the day the limits change, the screen says the new ones.
    await plotAndBeRefused({
      status: 422,
      body: { detail: { code: 'range_too_long', interval: '1min', max_days: 7 } },
    });

    expect(await screen.findByText(RANGO_EXCEDIDO_1MIN)).toBeInTheDocument();
  });

  it('never names the provider when something is refused', async () => {
    // RF-26. What the person reads is what the client wrote; the `code` of the answer is an
    // identifier for the screen to read, and neither it nor the provider's name is on display.
    await plotAndBeRefused({ status: 422, body: { detail: { code: 'range_invalid' } } });
    await screen.findByText(FECHAS_AL_REVES);

    expect(document.body.textContent ?? '').not.toMatch(/twelvedata/i);
  });

  it('draws no chart', async () => {
    // RF-46.
    await plotAndBeRefused({ status: 422, body: { detail: { code: 'range_invalid' } } });
    await screen.findByText(FECHAS_AL_REVES);

    expect(chartOrNull()).toBeNull();
  });

  it('leaves the chart that was already there exactly as it was', async () => {
    // RF-48, the third and fourth of the four invalid queries: whatever is on screen stays on
    // screen, the same node and not a redrawn copy of it.
    await theDetailOf(TSLA.symbol);
    await plotWith('5min');
    const before = await waitForTheChart();

    const person = userEvent.setup();
    await person.click(screen.getByRole('radio', { name: new RegExp(HISTORICO) }));
    theRefusal = {
      status: 422,
      body: { detail: { code: 'range_too_long', interval: '1min', max_days: 7 } },
    };
    await plotWith('1min');
    await screen.findByText(RANGO_EXCEDIDO_1MIN);

    expect(theChart()).toBe(before);
  });
});

/**
 * H4 -- the screen says what it is showing when what it shows is not today's session.
 *
 * The four states are the contract of `ERR-05` and all four answer 200: a failure of the provider
 * is not a failure of the request, and the screen finds out which of the four it got by reading
 * `status` -- never a 4xx, never the name of whoever could not be reached (RF-26).
 *
 * The date inside the `market_closed` notice is checked by the fixed parts the copy fixes plus
 * *something with a digit in it* where `{fecha}` goes. How that date is written down is not fixed
 * anywhere -- `COPY.md` writes the placeholder and `plan.md` says only that it is in market time
 * -- and a test that demanded one spelling would be inventing a requirement.
 */
describe('the notices above the chart', () => {
  const STALE = 'Mostrando la última cotización disponible: no se pudo consultar el proveedor.';
  const MERCADO_CERRADO =
    /^El mercado está cerrado\. Se muestra la última rueda disponible: .*\d.*\.$/;
  const SIN_COTIZACIONES = `No hay cotizaciones para ${TSLA.symbol} en el rango e intervalo seleccionados.`;

  /** Open the detail, have our API answer this series, and plot. */
  async function plotAnswering(series: QuoteSeries): Promise<void> {
    await theDetailOf(TSLA.symbol);
    theSeries = series;
    await plotWith('5min');
  }

  it('explains a closed market, with the session that is being shown', async () => {
    // RF-28, and it is the Sunday of the demo: the chart shows the last session there was, and
    // the notice says which one, so an empty-looking screen is never mistaken for a broken one.
    await plotAnswering(seriesOf('market_closed', FIVE_CANDLES, '2026-09-11'));

    expect(await screen.findByText(MERCADO_CERRADO)).toBeInTheDocument();
  });

  it('puts that notice above the chart and not at its foot', async () => {
    // UI-05: a notice qualifies the data that is about to be read, so it goes before it. At the
    // foot it is a footnote to something already misread.
    await plotAnswering(seriesOf('market_closed', FIVE_CANDLES, '2026-09-11'));

    const notice = await screen.findByText(MERCADO_CERRADO);
    const chart = await waitForTheChart();

    expect(notice.compareDocumentPosition(chart) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  });

  it('explains quotes it could not refresh, without naming who did not answer', async () => {
    // RF-30, verbatim, and RF-26 in the same breath: the person has no account with any provider,
    // so the notice says what is on screen and not whose fault it is.
    await plotAnswering(seriesOf('stale', FIVE_CANDLES));

    expect(await screen.findByText(STALE)).toBeInTheDocument();
    expect(document.body.textContent ?? '').not.toMatch(/twelvedata/i);
  });

  it('puts the stale notice above the chart too', async () => {
    // UI-05 again, for the state where there *is* a chart underneath: the notice is what says the
    // prices being read are not the latest ones.
    await plotAnswering(seriesOf('stale', FIVE_CANDLES));

    const notice = await screen.findByText(STALE);
    const chart = await waitForTheChart();

    expect(notice.compareDocumentPosition(chart) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  });

  it('says which action has no quotes when there are none at all', async () => {
    // RF-31, with the symbol inside the text: the same screen can be open on another action, and
    // a notice that did not name one would be ambiguous exactly when it matters.
    await plotAnswering(seriesOf('no_data', []));

    expect(await screen.findByText(SIN_COTIZACIONES)).toBeInTheDocument();
  });

  it('shows no notice at all when the quotes are up to date', async () => {
    // RF-32. A screen that always explains itself teaches people to stop reading the explanation.
    await plotAnswering(seriesOf('ok', FIVE_CANDLES));
    await waitForTheChart();

    expect(screen.queryByText(STALE)).toBeNull();
    expect(screen.queryByText(MERCADO_CERRADO)).toBeNull();
    expect(screen.queryByText(SIN_COTIZACIONES)).toBeNull();
  });

  it('never leaves the screen with neither a chart nor a notice', async () => {
    // RF-33, the invariant of the four states: something is always shown, and something always
    // explains it -- a chart, a notice, or both. Nothing is what reads as an application that
    // broke. Each state gets a screen of its own, so that what is on it was drawn by that state
    // and is not left over from the one before.
    const states: QuoteSeries[] = [
      seriesOf('ok', FIVE_CANDLES),
      seriesOf('stale', FIVE_CANDLES),
      seriesOf('market_closed', FIVE_CANDLES, '2026-09-11'),
      seriesOf('no_data', []),
    ];

    for (const state of states) {
      const mounted = await theDetailOf(TSLA.symbol);
      theSeries = state;
      await plotWith('5min');

      await waitFor(() => {
        const notice =
          screen.queryByText(STALE) ??
          screen.queryByText(MERCADO_CERRADO) ??
          screen.queryByText(SIN_COTIZACIONES);

        expect(
          chartOrNull() !== null || notice !== null,
          `with status "${state.status}" the screen shows neither a chart nor a notice (RF-33)`,
        ).toBe(true);
      });

      mounted.unmount();
      sessionStorage.clear();
    }
  });
});
