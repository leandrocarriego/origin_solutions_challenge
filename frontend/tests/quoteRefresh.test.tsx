/**
 * The chart of `Tiempo Real` keeping itself up to date -- H2 of `003`, task 10 of `tasks.md`.
 *
 * It is a capacity and not a screen, so it is named after the capacity (`add_tests` -> *Donde viven
 * y como se llaman*): what wireframe 03 looks like is `ActionDetail.test.tsx`, and what happens to
 * a chart that is left alone on it is here.
 *
 * The screen is driven the way a person drives it -- the application mounted at the address of the
 * detail, an interval chosen, `Graficar` pressed -- and then the clock is taken away from it. The
 * timers are the test's: `vi.useFakeTimers` is what turns "a minute goes by" into an assertion that
 * runs in milliseconds and always says the same thing. `shouldAdvanceTime` is on so that Testing
 * Library's waiting still works while the clock is ours.
 *
 * What is asserted about a refresh is what distinguishes the requirement from something that merely
 * looks right: **the chart node is the same one** (RF-19). A screen that threw the chart away and
 * drew a new one every interval would show the same points and flicker once a minute, and no
 * assertion about content would notice -- so the node is compared by identity, before and after.
 *
 * **What jsdom cannot be asked.** Highcharts draws into an SVG and jsdom computes no layout: there
 * is no way to read a *point* off the chart. So RF-18 and RF-20 are asserted where they are
 * decided and where they can be seen -- one request per interval, and a request for the whole
 * session rather than for "what is new", which is the shape that makes dropping a point
 * impossible. That the answer is then drawn is RF-19, which is the identity of the node.
 *
 * Today every test here is red because `/stocks/:symbol` has nothing behind it: the address falls
 * through to `Mis Acciones` and there is no `Graficar` to press. That is the intended red --
 * absence of implementation.
 *
 * `fetch` is replaced in every test and restored afterwards (`add_tests`, `TEST-03`).
 */

import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { App } from '../src/App';
import { writeStoredSession } from '../src/auth/storage';

// Verbatim from docs/design/COPY.md (UI-02): the controls this file has to drive, and the
// axis title that is the only thing a chart writes that jsdom can read.
const INTERVALO = 'Intervalo';
const GRAFICAR = 'Graficar';
const COTIZACION = 'Cotización';
const MIS_ACCIONES = 'Mis Acciones';

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

/** The candle that closes while the chart is on screen, and that a refresh has to bring (RF-18). */
const A_SIXTH_CANDLE: QuotePoint = { ts: '2026-09-11T20:05:00Z', price: '365.52000' };

/** What `GET /api/quotes/{symbol}` answers next. A test changes it to change the state. */
let theSeries: QuoteSeries = seriesOf('ok', FIVE_CANDLES);

/** Every call our API received for a series, so a test can count them and read their address. */
let quoteCalls: { url: string; signal: AbortSignal | null }[] = [];

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
  theSeries = seriesOf('ok', FIVE_CANDLES);
  stubTheApi();
});

afterEach(() => {
  vi.unstubAllGlobals();
  sessionStorage.clear();
});

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
    // not on one of its own. The series that answers the refresh carries the candle that closed
    // meanwhile, which is the whole reason to ask -- that the extra point is *drawn* is RF-19
    // below, because the node it is drawn into is the only thing jsdom lets a test see of it.
    const chart = await plotAndTakeTheClock('1min');
    const asked = timesAskedForASeries();
    theSeries = seriesOf('ok', [...FIVE_CANDLES, A_SIXTH_CANDLE]);

    await vi.advanceTimersByTimeAsync(ONE_MINUTE);

    expect(timesAskedForASeries()).toBe(asked + 1);
    expect(theChart()).toBe(chart);
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
