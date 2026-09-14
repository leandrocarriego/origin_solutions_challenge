/**
 * The detail when our API does not answer -- the failures that are nobody's rule (`003-quote-chart`).
 *
 * **Why its own file.** The files of this feature are split by capability and not by screen:
 * `quoteRefresh` owns the polling, `quoteHistoric` the date range and the refusals it earns,
 * `quoteNotice` the four states of a series that did arrive. What is left is a capability of its
 * own -- what the screen owes when the answer teaches it nothing -- and it is not one request but
 * two: the series behind `Graficar` and the list of favourites that decides whether the address
 * opens at all. Reading them together is the point, because they are the same fact from the
 * person's side and used to be the same silence.
 *
 * **The three things fixed here.**
 *
 *   * A failure that is not one of the two range refusals says so, above the chart, and
 *     leaves the chart that was there exactly as it was -- the same node with the same points
 *     drawn in it.
 *   * A list of favourites that never arrived is not a list that came back without the symbol.
 *     The second means the action is not this person's and sends them to the list; the
 *     first means nothing at all, and answering it with a redirect asserts something the server
 *     never said. Both are asserted here, side by side, because what makes either of them right
 *     is the contrast.
 *   * A cancellation is not a failure. Every query aborts the one before it, so the one before it
 *     rejects; a screen that read that as "we could not connect" would accuse itself of a failure
 *     every time somebody changed their mind.
 *
 * The cancellation is observed from outside, the way the screen produces it: the first series is
 * held pending, `Graficar` is pressed again, and the stub rejects the held call with an
 * `AbortError` exactly as `fetch` does with a signal that fires. Nothing here reaches into
 * `ActionDetail` to find the controller.
 *
 * `fetch` is replaced in every test and restored afterwards: a frontend test that goes to the
 * network is not a frontend test.
 */

import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import Highcharts from 'highcharts';
import { MemoryRouter } from 'react-router';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { App } from '../src/App';
import { writeStoredSession } from '../src/auth/storage';

/* Verbatim from the `Detalle de Acción` table of docs/design/COPY.md. */
const INTERVALO = 'Intervalo';
const GRAFICAR = 'Graficar';
const COTIZACION = 'Cotización';

/* Verbatim from *Detalle: navegación, horarios y validación* of docs/design/COPY.md. */
const MIS_ACCIONES = 'Mis Acciones';

/*
 * Verbatim from the *Sesión y validación* table of docs/design/COPY.md, row `No se pudo conectar`.
 * It is the sentence the login already shows when it could not reach us, and the client wrote one
 * text for the fact and not one per screen.
 */
const NO_SE_PUDO_CONECTAR =
  'No pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.';

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

/** A symbol deliberately outside the list, which is how "not yours" is told from a failed list. */
const NOT_HERS = 'MSFT';

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

/** The series our API answers while it is answering one. */
const THE_SERIES: QuoteSeries = {
  symbol: TSLA.symbol,
  interval: '5min',
  status: 'ok',
  session_date: null,
  points: FIVE_CANDLES,
};

/**
 * How an endpoint behaves in a given test.
 *
 * `'ok'` is the answer of the contract; a number is the status our API refuses with; `'rejects'`
 * is the call never getting there at all -- the server down, the network gone -- which is what
 * `fetch` itself rejecting looks like to whoever called it.
 */
type Behaviour = 'ok' | 'rejects' | number;

/** What `GET /api/quotes/{symbol}` does next. */
let quotesDo: Behaviour = 'ok';

/** What `GET /api/favorites` does next. */
let favoritesDo: Behaviour = 'ok';

/** Which favourites the list answers with, when it answers. */
let theFavorites: Favorite[] = THE_LIST;

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
 * too: the platform's `DOMException` inherits from it. jsdom's does **not**, so building one with
 * the runner's global would be testing the runner instead of the screen. What is produced here is
 * the shape the browser produces -- an error carrying that name -- which is what the screen reads.
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

/** What an endpoint answers, given how this test set it up. */
function answerOf(behaviour: Behaviour, body: unknown): Promise<Response> {
  if (behaviour === 'rejects') return Promise.reject(aDeadNetwork());
  if (typeof behaviour === 'number') {
    return Promise.resolve(new Response(JSON.stringify({ detail: 'boom' }), { status: behaviour }));
  }

  return Promise.resolve(new Response(JSON.stringify(body), { status: 200 }));
}

/**
 * Replace fetch: `/me` recognises the session, and `/favorites` and `/quotes/{symbol}` behave the
 * way the test set them up.
 *
 * A held series is a promise that only settles when its signal fires, which is what a request in
 * flight is: it lets the next `Graficar` cancel it, and the rejection it then produces is the one
 * `fetch` produces, so the screen is told apart from the test.
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
        return answerOf(favoritesDo, theFavorites);
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

        return answerOf(quotesDo, THE_SERIES);
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

/** Press `Graficar` on whatever is already chosen. */
async function pressGraficar(): Promise<void> {
  const person = userEvent.setup();

  await person.click(screen.getByRole('button', { name: GRAFICAR }));
}

/** Whether one node comes after another in the document, which is what "underneath" means here. */
function comesAfter(before: Element, after: Element): boolean {
  return Boolean(before.compareDocumentPosition(after) & Node.DOCUMENT_POSITION_FOLLOWING);
}

/*
 * The chart is drawn in one go, with nothing still moving once it is on screen.
 *
 * Highcharts animates a series it has just been handed, so for a second or so after the first draw
 * the markup is still changing on its own -- clip paths appearing and going -- and two snapshots
 * taken either side of that report a difference nobody caused. The test that compares what the
 * chart had drawn would then be green or red depending on how long the gestures before it took,
 * which is a test that says nothing on the day it speaks up.
 *
 * Turning the animation off removes the timing, not the check: the comparison of node and markup
 * is exactly as strict, and now it is answering the question it was written to ask. The library is
 * imported here and `ActionDetail` is not -- this stays a test that reads what is painted.
 */
beforeEach(() => {
  Highcharts.setOptions({ plotOptions: { series: { animation: false } } });
  sessionStorage.clear();
  quoteCalls = [];
  quotesDo = 'ok';
  favoritesDo = 'ok';
  theFavorites = THE_LIST;
  heldSeries = 0;
  stubTheApi();
});

afterEach(() => {
  vi.unstubAllGlobals();
  sessionStorage.clear();
});

describe('Graficar when our API fails for a reason that is not a rule of the range', () => {
  it('says we could not connect, in the words of the copy, when our API answers 500', async () => {
    // pressing `Graficar` and watching nothing happen at all was the failure
    // this closes. A 500 is not one of the two range refusals, so there is nothing to explain
    // about the query -- what is left to say is that the chart could not be got.
    await theDetailOf(TSLA.symbol);

    quotesDo = 500;
    await plotWith('5min');

    expect(await screen.findByText(NO_SE_PUDO_CONECTAR)).toBeInTheDocument();
  });

  it('says the same thing when the request never gets anywhere', async () => {
    // The other half of the same fact: a server that is down and a network that is gone are the
    // same thing from the person's side, and `fetch` rejecting is how the browser reports it.
    await theDetailOf(TSLA.symbol);

    quotesDo = 'rejects';
    await plotWith('5min');

    expect(await screen.findByText(NO_SE_PUDO_CONECTAR)).toBeInTheDocument();
  });

  it('never names the provider while saying it', async () => {
    // Whoever could not be reached is our business, and the person reads the
    // sentence the client wrote and nothing else.
    await theDetailOf(TSLA.symbol);

    quotesDo = 500;
    await plotWith('5min');
    await screen.findByText(NO_SE_PUDO_CONECTAR);

    expect(document.body.textContent ?? '').not.toMatch(/twelvedata/i);
  });

  it('draws no chart when there was none', async () => {
    // a failure is not a series, and an empty plotting area would show a period nobody
    // could get.
    await theDetailOf(TSLA.symbol);

    quotesDo = 500;
    await plotWith('5min');
    await screen.findByText(NO_SE_PUDO_CONECTAR);

    expect(chartOrNull()).toBeNull();
  });

  it('leaves the chart that was already there exactly as it was, points included', async () => {
    // This is the invariant the four invalid queries of the feature already have: a
    // query that failed does not touch what is on screen. The node is compared by identity --
    // a chart thrown away and drawn again "looks right" and is not what the requirement says --
    // and what it has drawn inside it is compared too, so a chart kept but emptied is not read as
    // a chart left alone.
    await theDetailOf(TSLA.symbol);
    await plotWith('5min');
    const before = await waitForTheChart();
    const whatItHadDrawn = before.innerHTML;

    quotesDo = 500;
    await plotWith('15min');
    await screen.findByText(NO_SE_PUDO_CONECTAR);

    expect(theChart()).toBe(before);
    expect(theChart().innerHTML).toBe(whatItHadDrawn);
  });

  it('puts the notice above the chart it could not replace', async () => {
    // the notice qualifies the data the person is about to read -- the chart on screen is
    // not the one they just asked for -- so it goes before it and not at its foot.
    await theDetailOf(TSLA.symbol);
    await plotWith('5min');
    const chart = await waitForTheChart();

    quotesDo = 500;
    await plotWith('15min');
    const notice = await screen.findByText(NO_SE_PUDO_CONECTAR);

    expect(comesAfter(notice, chart)).toBe(true);
  });

  it('lets the person try again, and the chart arrives when our API answers', async () => {
    // The notice is not a dead end: the same gesture that failed works when the other end comes
    // back, and what was said about the failure goes away with it.
    await theDetailOf(TSLA.symbol);

    quotesDo = 500;
    await plotWith('5min');
    await screen.findByText(NO_SE_PUDO_CONECTAR);

    quotesDo = 'ok';
    await pressGraficar();
    await waitForTheChart();

    await waitFor(() => {
      expect(screen.queryByText(NO_SE_PUDO_CONECTAR)).toBeNull();
    });
  });
});

describe('the detail of an action whose list of favourites did not arrive', () => {
  it('says we could not connect instead of opening the screen', async () => {
    // the list is what the header and the membership are read from, so without
    // it there is no screen to draw -- and a blank page is the failure this closes.
    favoritesDo = 500;
    openTheDetail(TSLA.symbol);

    expect(await screen.findByText(NO_SE_PUDO_CONECTAR)).toBeInTheDocument();
  });

  it('does not send the person to Mis Acciones, because nobody said the action is not theirs', async () => {
    // The finding this file exists for. Redirecting asserts "this action is not yours" --
    // on the strength of a question the server never answered. The two cases are told apart by
    // what came back, not by what is convenient: no list is no answer.
    favoritesDo = 500;
    openTheDetail(TSLA.symbol);
    await screen.findByText(NO_SE_PUDO_CONECTAR);

    expect(screen.queryByRole('heading', { name: MIS_ACCIONES })).toBeNull();
    expect(screen.queryByRole('button', { name: GRAFICAR })).toBeNull();
  });

  it('says the same thing when the request never gets anywhere', async () => {
    // A rejected `fetch` is the same absence of an answer as a 500, and it is the one that used to
    // reach the redirect by another path.
    favoritesDo = 'rejects';
    openTheDetail(TSLA.symbol);

    expect(await screen.findByText(NO_SE_PUDO_CONECTAR)).toBeInTheDocument();
    expect(screen.queryByRole('heading', { name: MIS_ACCIONES })).toBeNull();
  });

  it('asks our API for no series, since there is no screen to plot on', async () => {
    // From the browser's side: a screen that never opened cannot spend a request, and
    // therefore cannot spend a credit of the provider's quota.
    favoritesDo = 500;
    openTheDetail(TSLA.symbol);
    await screen.findByText(NO_SE_PUDO_CONECTAR);

    expect(timesAskedForASeries()).toBe(0);
  });

  it('still goes to Mis Acciones when the list did arrive and the action is not on it', async () => {
    // The contrast that makes the case above right, and it is nailed down here so that it cannot
    // be lost while fixing the other: a list that came back without the symbol *is* an answer, and
    // That is what it says. This is the behaviour that did not change.
    theFavorites = THE_LIST;
    openTheDetail(NOT_HERS);

    expect(await screen.findByRole('heading', { name: MIS_ACCIONES })).toBeInTheDocument();
    expect(screen.queryByText(NO_SE_PUDO_CONECTAR)).toBeNull();
  });
});

describe('Graficar pressed again while the first answer is still on its way', () => {
  it('says nothing about connecting, because a cancellation is not a failure', async () => {
    // Every query aborts the one before it, so the one before it rejects with an `AbortError`.
    // That is the screen working -- somebody changed their mind -- and reading it as "we could not
    // connect" would accuse the server of a failure nobody suffered. The first call is held
    // pending and rejected by its own signal, exactly as `fetch` does it.
    //
    // Both calls are held on purpose, and that is what makes this readable: the only thing that
    // has settled when the assertion runs is the cancellation, so a screen that mistook it for a
    // failure has nothing left to hide the notice with.
    await theDetailOf(TSLA.symbol);

    heldSeries = 2;
    await plotWith('1min');
    await plotWith('5min');

    await waitFor(() => {
      expect(quoteCalls[0]?.signal?.aborted).toBe(true);
      expect(timesAskedForASeries()).toBe(2);
    });

    expect(screen.queryByText(NO_SE_PUDO_CONECTAR)).toBeNull();
  });

  it('draws the answer of the query that was not cancelled', async () => {
    // The other side of the same behaviour: what is on screen is the last thing asked for, and the
    // chart arrives even though a request of its own was dropped on the way.
    await theDetailOf(TSLA.symbol);

    heldSeries = 1;
    await plotWith('1min');
    await plotWith('5min');

    const chart = await waitForTheChart();
    expect(chart.textContent).toContain(TSLA.symbol);
    expect(timesAskedForASeries()).toBe(2);
  });
});
