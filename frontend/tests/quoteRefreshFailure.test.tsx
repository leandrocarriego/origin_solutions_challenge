/**
 * A chart of `Tiempo Real` whose automatic refresh stopped landing (`003-quote-chart`).
 *
 * **Why its own file.** The files of this feature are split by capability and not by screen, and
 * this is a capability that did not exist until the client decided it: what the screen owes when
 * the chart is still there but has stopped being current. `quoteRefresh` owns the rhythm of the
 * polling -- one request per interval, the same node, the tab hidden and come back to -- and every
 * request in it succeeds. `quoteNotice` owns the four states of a series that *did* arrive, and
 * reads them off `status`. `apiUnreachable` owns the failure of a query somebody asked for, by
 * pressing `Graficar`. What is fixed here is none of those three: nobody asked for anything, the
 * series on screen is the one that arrived a while ago, and the fact to be told is that it is old.
 * It needs the clock of the first file and the literals of the second, which is precisely why
 * putting it in either would make that file about two things.
 *
 * **The decision.** *(Decided by the client on 2026-09-14, `docs/design/COPY.md` → *Avisos de
 * estado*.)* Until then the refresh swallowed its own error: a chart that had stopped updating
 * half an hour ago looked exactly like one that was current, which is the reading these notices
 * exist to prevent. The text is the `stale` row **reused and not written a second time** -- the
 * fact the person needs is the same one, and a second wording for it is one that will one day
 * disagree with the first.
 *
 * **Precedence.** A failed refresh wins over whatever the series says. After a failure what is on
 * screen is the last thing known and nothing newer was learnt, so naming any other state would
 * describe a moment that has already passed -- which is what the fourth test nails down.
 *
 * **What stays.** The chart. Taking it away would punish the reader for a network they do not
 * control, so the node is compared by identity and what it has drawn inside it is compared too: a
 * chart kept but emptied is not a chart left alone.
 *
 * The timers are the test's: `vi.useFakeTimers` is what turns "a minute goes by" into an assertion
 * that runs in milliseconds and always says the same thing. `shouldAdvanceTime` is on so that
 * Testing Library's waiting still works while the clock is ours.
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
const HISTORICO = 'Histórico';

/*
 * Verbatim from the *Avisos de estado* table of docs/design/COPY.md, row `stale`: the sentence a
 * refresh that did not land reuses, and the one `market_closed` has to lose to.
 */
const STALE = 'Mostrando la última cotización disponible: no se pudo consultar el proveedor.';
const MERCADO_CERRADO =
  /^El mercado está cerrado\. Se muestra la última rueda disponible: .*\d.*\.$/;

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

/** The session a `market_closed` answer says it is showing, as the contract carries it. */
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

/**
 * How `GET /api/quotes/{symbol}` behaves on the next call.
 *
 * `'ok'` is the answer of the contract; a number is the status our API refuses with; `'rejects'`
 * is the call never getting there at all -- the server down, the network gone -- which is what
 * `fetch` itself rejecting looks like to whoever called it. Both failures are the same fact from
 * the person's side, and the refresh has no reading for either: nothing newer was learnt.
 */
type Behaviour = 'ok' | 'rejects' | number;

/** What `GET /api/quotes/{symbol}` does next. A test changes it to break a refresh. */
let quotesDo: Behaviour = 'ok';

/** What our API answers while it is answering. A test changes it to change the state. */
let theSeries: QuoteSeries = seriesOf('ok', FIVE_CANDLES);

/** How many of the next series calls are held pending, so the one after has one to cancel. */
let heldSeries = 0;

/** Every call our API received for a series, so a test can count them and read their address. */
let quoteCalls: { url: string; signal: AbortSignal | null }[] = [];

/** The URL of a fetch call, whichever of the three shapes it was made with. */
function urlOf(input: RequestInfo | URL): string {
  if (typeof input === 'string') return input;
  if (input instanceof URL) return input.href;

  return input.url;
}

/**
 * The rejection `fetch` produces when the signal of a call fires.
 *
 * A browser rejects with a `DOMException` named `AbortError`, and in a browser that is an `Error`
 * too. jsdom's is not, so building one with the runner's global would be testing the runner
 * instead of the screen: what is produced here is an error carrying that name, which is what the
 * screen reads.
 */
function anAbortError(): Error {
  const error = new Error('the request was aborted');
  error.name = 'AbortError';

  return error;
}

/** The rejection `fetch` produces when the call never got anywhere. */
function aDeadNetwork(): Error {
  return new TypeError('Failed to fetch');
}

/** What the series endpoint answers, given how this test set it up. */
function answerOf(behaviour: Behaviour, body: unknown): Promise<Response> {
  if (behaviour === 'rejects') return Promise.reject(aDeadNetwork());
  if (typeof behaviour === 'number') {
    return Promise.resolve(new Response(JSON.stringify({ detail: 'boom' }), { status: behaviour }));
  }

  return Promise.resolve(new Response(JSON.stringify(body), { status: 200 }));
}

/**
 * Replace fetch: `/me` recognises the session, `/favorites` answers the list and
 * `/quotes/{symbol}` behaves the way the test set it up.
 *
 * A held series is a promise that only settles when its signal fires, which is what a request in
 * flight is: it lets the next one cancel it, and the rejection it then produces is the one `fetch`
 * produces, so the screen is told apart from the test.
 *
 * Anything else is refused, so a call this feature never agreed to make shows up as a failure and
 * not as a silent success.
 */
function stubTheApi(): void {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockImplementation((input: RequestInfo | URL, init?: RequestInit) => {
      const url = urlOf(input);
      const signal = init?.signal ?? null;

      if (url.includes(ME_URL)) {
        return Promise.resolve(new Response(JSON.stringify(WHO_IT_IS), { status: 200 }));
      }
      if (url.includes(FAVORITES_URL)) {
        return Promise.resolve(new Response(JSON.stringify(THE_LIST), { status: 200 }));
      }
      if (url.includes(QUOTES_URL)) {
        quoteCalls.push({ url, signal });

        if (heldSeries > 0 && quotesDo === 'ok') {
          heldSeries -= 1;

          return new Promise<Response>((_resolve, reject) => {
            signal?.addEventListener('abort', () => {
              reject(anAbortError());
            });
          });
        }

        return answerOf(quotesDo, theSeries);
      }

      return Promise.resolve(
        new Response(JSON.stringify({ detail: 'not authenticated' }), { status: 401 }),
      );
    }),
  );
}

/** Open the detail of a symbol at its own address, with a session already in the browser. */
function openTheDetail(symbol: string): void {
  writeStoredSession({
    token: A_TOKEN,
    fullName: FULL_NAME,
    expiresAt: Date.now() + 3_600_000,
  });

  render(
    <MemoryRouter initialEntries={[`/stocks/${symbol}`]}>
      <App />
    </MemoryRouter>,
  );
}

/** The detail, once its controls are painted: everything else is read after this. */
async function theDetailOf(symbol: string): Promise<void> {
  openTheDetail(symbol);
  await screen.findByRole('button', { name: GRAFICAR });
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

/** Choose an interval and press `Graficar`, which is the whole gesture of the wireframe. */
async function plotWith(interval: string): Promise<void> {
  const person = userEvent.setup();

  await person.selectOptions(theIntervalSelect(), interval);
  await person.click(screen.getByRole('button', { name: GRAFICAR }));
}

/** Move the screen to `Histórico`, whose two date fields are already filled in. */
async function chooseHistoric(): Promise<void> {
  const person = userEvent.setup();

  await person.click(screen.getByRole('radio', { name: new RegExp(HISTORICO) }));
}

/** One minute, in milliseconds: the shortest interval the brief offers (`1min`). */
const ONE_MINUTE = 60_000;

/** Long enough for a drawing to settle, and far short of the shortest refresh. */
const A_FEW_SECONDS = 5_000;

beforeEach(() => {
  sessionStorage.clear();
  quoteCalls = [];
  quotesDo = 'ok';
  heldSeries = 0;
  theSeries = seriesOf('ok', FIVE_CANDLES);
  stubTheApi();
});

afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
  sessionStorage.clear();
});

describe('the automatic refresh of Tiempo Real when it stops landing', () => {
  /**
   * Open the detail, plot the series set up, and hand the clock to the test from that moment.
   *
   * The clock is taken after the screen is painted and before `Graficar`, which is the window the
   * timer of the refresh is armed in: `shouldAdvanceTime` keeps Testing Library's waiting working
   * while the clock is ours.
   */
  async function plotAndTakeTheClock(
    interval: string,
    series: QuoteSeries = seriesOf('ok', FIVE_CANDLES),
  ): Promise<SVGSVGElement> {
    await theDetailOf(TSLA.symbol);
    theSeries = series;
    vi.useFakeTimers({ shouldAdvanceTime: true });
    await plotWith(interval);

    return await waitForTheChart();
  }

  it('says the quotes are the last ones available when a refresh does not arrive', async () => {
    // The decision of 2026-09-14: the refresh no longer swallows its error. Until the interval
    // went by there was nothing to say -- the series arrived `ok` and said nothing -- and
    // from the moment one did not arrive, what is on screen is old and the notice says so, in the
    // sentence `Avisos de estado` already has for that fact.
    await plotAndTakeTheClock('1min');
    expect(screen.queryByText(STALE)).toBeNull();

    quotesDo = 500;
    await vi.advanceTimersByTimeAsync(ONE_MINUTE);

    expect(await screen.findByText(STALE)).toBeInTheDocument();
  });

  it('says the same thing when the refresh never gets anywhere', async () => {
    // The other half of the same fact: a server that is down and a network that is gone are the
    // same absence of an answer, and `fetch` rejecting is how the browser reports it. A screen
    // that only read the status code would stay silent on the failure that is more common.
    await plotAndTakeTheClock('1min');

    quotesDo = 'rejects';
    await vi.advanceTimersByTimeAsync(ONE_MINUTE);

    expect(await screen.findByText(STALE)).toBeInTheDocument();
  });

  it('keeps the chart that was being read, with the same node and the same points', async () => {
    // What the decision is careful about: the notice says the chart is old, it does not take it
    // away -- doing that would punish the reader for a network they do not control. The node is
    // compared by identity, because a chart thrown away and drawn again "looks right" and is not
    // what was decided, and what it has drawn inside it is compared too, so a chart kept but
    // emptied is not read as a chart left alone.
    const chart = await plotAndTakeTheClock('1min');
    // Let the drawing settle before it is written down. Highcharts animates the series it has just
    // been given, so the markup a moment after the first draw is still moving and comparing it
    // against a later one would report a difference the refresh had nothing to do with. A few
    // seconds is far short of the minute the refresh is due in.
    await vi.advanceTimersByTimeAsync(A_FEW_SECONDS);
    const whatItHadDrawn = chart.innerHTML;

    quotesDo = 500;
    await vi.advanceTimersByTimeAsync(ONE_MINUTE);
    await screen.findByText(STALE);

    expect(theChart()).toBe(chart);
    expect(theChart().innerHTML).toBe(whatItHadDrawn);
  });

  it('takes the notice away as soon as a refresh arrives again', async () => {
    // The notice describes the present and not a scar: one interval later the answer came back,
    // so the chart is current again and there is nothing left to explain. A notice that
    // stayed would be read as a screen that is still broken, and the next real one would not be
    // believed.
    await plotAndTakeTheClock('1min');

    quotesDo = 500;
    await vi.advanceTimersByTimeAsync(ONE_MINUTE);
    await screen.findByText(STALE);

    quotesDo = 'ok';
    await vi.advanceTimersByTimeAsync(ONE_MINUTE);

    await waitFor(() => {
      expect(screen.queryByText(STALE)).toBeNull();
    });
  });

  it('wins over the state the series arrived with, which is what precedence means', async () => {
    // The precedence the client decided, and the case that shows why: the series on screen came
    // with `market_closed`, so until the failure the notice named the last session there was. Once
    // a refresh does not land, that sentence describes a moment that has passed -- it says the
    // screen knows what the market is doing, and it does not. What is left to say is the only
    // thing still true: this is the last thing we knew.
    await plotAndTakeTheClock('1min', seriesOf('market_closed', FIVE_CANDLES, THE_LAST_SESSION));
    expect(await screen.findByText(MERCADO_CERRADO)).toBeInTheDocument();

    quotesDo = 'rejects';
    await vi.advanceTimersByTimeAsync(ONE_MINUTE);

    expect(await screen.findByText(STALE)).toBeInTheDocument();
    expect(screen.queryByText(MERCADO_CERRADO)).toBeNull();
  });

  it('says nothing when a refresh was cancelled, because that is not a failure', async () => {
    // Every request aborts the one before it, so a refresh still in flight when the next one is
    // armed rejects with an `AbortError`. That is the screen working, and reading it as "we could
    // not consult" would tell the person their chart is old every single interval. Both refreshes
    // are held on purpose: the only thing that has settled when the assertion runs is the
    // cancellation, so a screen that mistook it for a failure has nothing left to hide the notice
    // with.
    await plotAndTakeTheClock('1min');
    const asked = timesAskedForASeries();

    heldSeries = 2;
    await vi.advanceTimersByTimeAsync(ONE_MINUTE);
    await vi.advanceTimersByTimeAsync(ONE_MINUTE);

    await waitFor(() => {
      expect(timesAskedForASeries()).toBe(asked + 2);
      expect(quoteCalls[asked]?.signal?.aborted).toBe(true);
    });

    expect(screen.queryByText(STALE)).toBeNull();
  });
});

describe('a chart of Histórico left on screen while our API is failing', () => {
  it('never shows the notice of a refresh, because it arms no refresh at all', async () => {
    // a period that already ended does not change, so `Histórico` arms no timer -- and a
    // notice about a refresh that was never due is a screen calling itself old for no reason. The
    // endpoint is left failing for ten intervals, which is the state that would produce the notice
    // if a timer had been armed: no request is the assertion, and no notice is what it buys.
    await theDetailOf(TSLA.symbol);
    await chooseHistoric();

    vi.useFakeTimers({ shouldAdvanceTime: true });
    await plotWith('1min');
    const chart = await waitForTheChart();
    const asked = timesAskedForASeries();

    quotesDo = 500;
    await vi.advanceTimersByTimeAsync(10 * ONE_MINUTE);

    expect(timesAskedForASeries()).toBe(asked);
    expect(screen.queryByText(STALE)).toBeNull();
    expect(theChart()).toBe(chart);
  });
});
