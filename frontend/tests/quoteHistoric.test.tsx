/**
 * `Histórico` -- asking the detail for a period that already went by (H3 of `003-quote-chart`).
 *
 * The screen is opened the way a person opens it: the application is mounted at an address with a
 * session already in the browser, and everything else is read off what is painted. Nothing here
 * imports `ActionDetail`, `QuoteChart`, `quotes/market` or `api/quotes` -- which of those draws a
 * given control, and which one computes the default range, is an internal arrangement of
 * `plan.md`, and a test that fixed it would go red the day somebody moves a control between two
 * components without the screen changing for anybody.
 *
 * Today every test here is red because `/stocks/:symbol` has nothing behind it: the address falls
 * through to `Mis Acciones`, so there is no `Graficar` to press. That is the intended red --
 * absence of implementation -- and it is told apart from a broken test by what the assertion says
 * it could not find: a control of wireframe 03, by its role or by its text.
 *
 * **What the chart can be asked in jsdom.** Highcharts draws into an SVG and gives no roles: what
 * a test can see is the *text* it writes -- the title and the two axis titles -- and the identity
 * of the node it drew into. So "there is a chart" here means "the vertical axis title `Cotización`
 * is on screen", and "it was left as it was" means the SVG that carries it is the same node as
 * before (RF-48).
 *
 * **The validation is split, and this file reads both halves from outside.** What is *presence* --
 * an empty date field -- the screen resolves on its own and never turns into a request (RF-40).
 * What is a *rule of the business* -- the dates the wrong way round, the range longer than its
 * interval allows -- the backend decides, and the screen only draws what the 422 tells it, filling
 * `{intervalo}` and `{N}` from the body (RF-41, RF-45). The caps are not copied into the browser.
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

/* Verbatim from the `Detalle de Acción` table of docs/design/COPY.md (UI-02). */
const HISTORICO = 'Histórico';
const INTERVALO = 'Intervalo';
const GRAFICAR = 'Graficar';
const COTIZACION = 'Cotización';
const FECHA_DESDE = 'Fecha hora desde';
const FECHA_HASTA = 'Fecha hora hasta';

/*
 * Verbatim from *Detalle: navegación, horarios y validación* of docs/design/COPY.md. The two
 * templates are written here already filled in, because what a person reads is the filled text:
 * `{intervalo}` and `{N}` come from the body of the 422 and not from a copy of the caps kept in
 * the browser.
 */
const FECHAS_AL_REVES = 'La fecha desde tiene que ser anterior a la fecha hasta.';
const RANGO_EXCEDIDO_1MIN =
  'El rango es demasiado largo para el intervalo 1min. El máximo es 7 días.';
const RANGO_EXCEDIDO_5MIN =
  'El rango es demasiado largo para el intervalo 5min. El máximo es 30 días.';

/*
 * Verbatim from *Sesión y validación*: an empty field is the same oversight on the login and on
 * the detail, and the client deliberately wrote one text for it and not two (`COPY.md`).
 */
const COMPLETA_ESTE_CAMPO = 'Completá este campo.';

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

/** A series in the state the test needs. */
function seriesOf(status: QuoteSeries['status'], points: QuotePoint[]): QuoteSeries {
  return { symbol: TSLA.symbol, interval: '5min', status, session_date: null, points };
}

/** What `GET /api/quotes/{symbol}` answers next, while it is not refusing. */
let theSeries: QuoteSeries = seriesOf('ok', FIVE_CANDLES);

/** A refusal our API answers instead of a series, or `null` while it answers one. */
let theRefusal: { status: number; body: unknown } | null = null;

/** Every call our API received for a series, so a test can count them and read their address. */
let quoteCalls: { url: string }[] = [];

/** The URL of a fetch call, whichever of the three shapes it was made with. */
function urlOf(input: RequestInfo | URL): string {
  if (typeof input === 'string') return input;
  if (input instanceof URL) return input.href;

  return input.url;
}

/**
 * Replace fetch: `/me` recognises the session, `/favorites` answers the list and
 * `/quotes/{symbol}` answers whatever the test set up.
 *
 * Anything else is refused, so a call this feature never agreed to make shows up as a failure and
 * not as a silent success.
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
        quoteCalls.push({ url });

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

/**
 * One of the two date fields, by its label or -- as the wireframe draws it -- by the text inside.
 *
 * The wireframe writes `Fecha hora desde` *inside* the box, so a screen that draws it as a
 * placeholder is reproducing the wireframe and one that adds a `<label>` is doing better; both say
 * which end of the range the field is, and both are found here. A field that can be found by
 * neither is one nobody using a screen reader can fill, which is a finding about the screen and
 * not about this test.
 */
function dateField(name: string): HTMLInputElement {
  const labelled = screen.queryByLabelText<HTMLInputElement>(name);
  if (labelled) return labelled;

  return screen.getByPlaceholderText(name);
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

/** Move the screen to `Histórico`, which is the only gesture the two date fields need. */
async function chooseHistoric(): Promise<void> {
  const person = userEvent.setup();

  await person.click(screen.getByRole('radio', { name: new RegExp(HISTORICO) }));
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

/** One minute, in milliseconds: the shortest interval the brief offers (`1min`). */
const ONE_MINUTE = 60_000;

beforeEach(() => {
  sessionStorage.clear();
  quoteCalls = [];
  theRefusal = null;
  theSeries = seriesOf('ok', FIVE_CANDLES);
  stubTheApi();
});

afterEach(() => {
  vi.unstubAllGlobals();
  sessionStorage.clear();
});

/**
 * The clock is the test's here, and for a reason of its own: the two fields come already filled
 * with the last 24 hours **of market time** (RF-10), so what they say depends on when the screen
 * was opened. With the system time fixed, that becomes an assertion.
 *
 * What they are asserted against is the *market* hour and not the hour of the machine running the
 * suite: that is the whole point of RF-36. The format is left alone on purpose -- neither
 * `plan.md` nor `COPY.md` fixes `datetime-local` or a mask -- so each value is required to carry
 * the day, the month, the year and the hour of the instant it stands for, and nothing is said
 * about the order they are written in.
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
    // RF-09, verbatim: `Fecha hora desde` and `Fecha hora hasta`.
    await theDetailOf(TSLA.symbol);
    await chooseHistoric();

    expect(dateField(FECHA_DESDE)).toBeInTheDocument();
    expect(dateField(FECHA_HASTA)).toBeInTheDocument();
  });

  it('come already filled with the last 24 hours of market time', async () => {
    // RF-10, which is A6 resolved: nobody has to type a date to get a chart out of the historic
    // mode. The two values are told in the market's hour and not in the machine's (RF-36), and
    // they are there from the moment the screen opens -- before anybody touches the radio.
    await theDetailOf(TSLA.symbol);

    const twentyFourHoursEarlier = new Date(WHEN_IT_WAS_OPENED.getTime() - 24 * 60 * ONE_MINUTE);

    expectFieldToCarry(dateField(FECHA_DESDE), twentyFourHoursEarlier);
    expectFieldToCarry(dateField(FECHA_HASTA), WHEN_IT_WAS_OPENED);
  });

  it('are the window the screen asks our API for', async () => {
    // The two fields are not decoration: what they carry is what travels, and it travels as the
    // person wrote it -- market time -- for the backend to localise (`plan.md` → *Contratos*).
    await theDetailOf(TSLA.symbol);
    await chooseHistoric();

    await plotWith('15min');
    await waitForTheChart();

    const asked = quoteCalls.at(-1)?.url ?? '';
    expect(asked).toContain(`${QUOTES_URL}/${TSLA.symbol}`);
    expect(asked).toContain('interval=15min');
    expect(asked).toContain('from=');
    expect(asked).toContain('to=');
  });
});

describe('Graficar in Histórico with a date field left empty', () => {
  /** Open the detail in `Histórico`, with an interval chosen and one of the fields emptied. */
  async function emptyTheField(name: string): Promise<HTMLInputElement> {
    await theDetailOf(TSLA.symbol);
    await chooseHistoric();

    const person = userEvent.setup();
    await person.selectOptions(theIntervalSelect(), '1min');

    const field = dateField(name);
    await person.clear(field);

    return field;
  }

  it('says what is missing under the field that is missing it, and not under the other', async () => {
    // RF-40, with the text the login already uses for an empty field: the client wrote one text
    // for the same oversight, not two (`COPY.md`). Under *that* field, because that is the one
    // that has to be corrected -- a notice under the field that is filled sends the person to fix
    // what is not broken.
    const emptied = await emptyTheField(FECHA_HASTA);

    await pressGraficar();

    const notice = await screen.findByText(COMPLETA_ESTE_CAMPO);
    expect(comesAfter(emptied, notice)).toBe(true);
    expect(comesAfter(notice, dateField(FECHA_DESDE))).toBe(false);
  });

  it('says it under the other field when that is the empty one', async () => {
    // RF-40 again, on the other end of the range: which field the notice hangs off is decided by
    // which one is empty, and not by which one the screen happens to draw first.
    const emptied = await emptyTheField(FECHA_DESDE);

    await pressGraficar();

    const notice = await screen.findByText(COMPLETA_ESTE_CAMPO);
    expect(comesAfter(emptied, notice)).toBe(true);
  });

  it('asks our API for nothing, so the provider is never reached', async () => {
    // RF-47: an empty field is presence, which the screen resolves on its own -- there is not even
    // a request to build, so no credit of the provider's quota can be spent on it (Article II).
    await emptyTheField(FECHA_DESDE);

    await pressGraficar();
    await screen.findByText(COMPLETA_ESTE_CAMPO);

    expect(timesAskedForASeries()).toBe(0);
  });

  it('draws no chart', async () => {
    // RF-46: a query that was not made cannot be plotted.
    await emptyTheField(FECHA_DESDE);

    await pressGraficar();
    await screen.findByText(COMPLETA_ESTE_CAMPO);

    expect(chartOrNull()).toBeNull();
  });

  it('leaves the chart that was already there exactly as it was', async () => {
    // RF-48, the first of the three range failures. The node is compared by identity, because a
    // chart thrown away and drawn again "looks right" and is not what the requirement says.
    await theDetailOf(TSLA.symbol);
    await plotWith('5min');
    const before = await waitForTheChart();
    const callsBefore = timesAskedForASeries();

    await chooseHistoric();
    const person = userEvent.setup();
    await person.clear(dateField(FECHA_HASTA));
    await pressGraficar();
    await screen.findByText(COMPLETA_ESTE_CAMPO);

    expect(theChart()).toBe(before);
    expect(timesAskedForASeries()).toBe(callsBefore);
  });
});

describe('Graficar in Histórico with a range our API refuses', () => {
  /** The 422 our API answers a range it will not serve (`plan.md` → *Contratos*). */
  function refusal(detail: Record<string, unknown>): { status: number; body: unknown } {
    return { status: 422, body: { detail } };
  }

  /** Open the detail in `Histórico` and plot while our API answers the refusal set up. */
  async function plotAndBeRefused(
    what: { status: number; body: unknown },
    interval = '1min',
  ): Promise<void> {
    await theDetailOf(TSLA.symbol);
    await chooseHistoric();

    theRefusal = what;
    await plotWith(interval);
  }

  it('says the dates are the wrong way round, in the words of the copy', async () => {
    // RF-41, verbatim. The rule lives in the backend and only there (`plan.md`: a rule of the
    // business written on both ends is a rule that one day disagrees with itself), so what the
    // screen owes is turning the `code` of the 422 into the text the client wrote.
    await plotAndBeRefused(refusal({ code: 'range_invalid' }));

    expect(await screen.findByText(FECHAS_AL_REVES)).toBeInTheDocument();
  });

  it('puts that notice underneath the two date fields', async () => {
    // RF-41 again: `COPY.md` says where it goes -- under the date fields, which are the controls
    // that have to be corrected -- and not above the chart, where the notices that qualify data
    // live (UI-05).
    await plotAndBeRefused(refusal({ code: 'range_invalid' }));

    const notice = await screen.findByText(FECHAS_AL_REVES);
    expect(comesAfter(dateField(FECHA_DESDE), notice)).toBe(true);
    expect(comesAfter(dateField(FECHA_HASTA), notice)).toBe(true);
  });

  it('says how long the range may be, with the interval and the number of the answer', async () => {
    // RF-45. `{intervalo}` and `{N}` are filled in from the body, and the body is the only place
    // they can come from: the caps live in the service and are not copied into the browser.
    await plotAndBeRefused(
      refusal({ code: 'range_too_long', interval: '1min', max_days: 7 }),
      '1min',
    );

    expect(await screen.findByText(RANGO_EXCEDIDO_1MIN)).toBeInTheDocument();
  });

  it('says the other interval and the other number when the answer carries those', async () => {
    // RF-45 again, and this is the one that tells a filled template from a hardcoded sentence: a
    // screen with `1min` and `7` written into it passes the test above and fails this one.
    await plotAndBeRefused(
      refusal({ code: 'range_too_long', interval: '5min', max_days: 30 }),
      '5min',
    );

    expect(await screen.findByText(RANGO_EXCEDIDO_5MIN)).toBeInTheDocument();
    expect(screen.queryByText(RANGO_EXCEDIDO_1MIN)).toBeNull();
  });

  it('puts the range notice underneath the two date fields as well', async () => {
    // RF-45, same place as RF-41: the two failures are about the same pair of controls.
    await plotAndBeRefused(refusal({ code: 'range_too_long', interval: '1min', max_days: 7 }));

    const notice = await screen.findByText(RANGO_EXCEDIDO_1MIN);
    expect(comesAfter(dateField(FECHA_DESDE), notice)).toBe(true);
    expect(comesAfter(dateField(FECHA_HASTA), notice)).toBe(true);
  });

  it('never names the provider when something is refused', async () => {
    // RF-26. What the person reads is what the client wrote; the `code` of the answer is an
    // identifier for the screen to read, and neither it nor the provider's name is on display.
    await plotAndBeRefused(refusal({ code: 'range_invalid' }));
    await screen.findByText(FECHAS_AL_REVES);

    expect(document.body.textContent ?? '').not.toMatch(/twelvedata/i);
  });

  it('draws no chart for either refusal', async () => {
    // RF-46: a 422 is not a series, and a screen that drew an empty chart for it would be showing
    // a period nobody could get.
    await plotAndBeRefused(refusal({ code: 'range_invalid' }));
    await screen.findByText(FECHAS_AL_REVES);

    expect(chartOrNull()).toBeNull();
  });

  it('leaves the chart that was already there exactly as it was', async () => {
    // RF-48, the second and third of the three range failures: whatever is on screen stays on
    // screen, the same node and not a redrawn copy of it.
    await theDetailOf(TSLA.symbol);
    await plotWith('5min');
    const before = await waitForTheChart();

    await chooseHistoric();
    theRefusal = refusal({ code: 'range_too_long', interval: '1min', max_days: 7 });
    await plotWith('1min');
    await screen.findByText(RANGO_EXCEDIDO_1MIN);

    expect(theChart()).toBe(before);

    theRefusal = refusal({ code: 'range_invalid' });
    await pressGraficar();
    await screen.findByText(FECHAS_AL_REVES);

    expect(theChart()).toBe(before);
  });
});

/**
 * RF-23 -- a period that already ended does not change, so nothing refreshes it.
 *
 * The timers are the test's: `vi.useFakeTimers` is what turns "ten minutes go by" into an
 * assertion that runs in milliseconds and always says the same thing. `shouldAdvanceTime` is on so
 * that Testing Library's waiting still works while the clock is ours.
 *
 * This is the half of the polling that quietly spends quota if it is got wrong: a timer armed in
 * `Histórico` renews the TTL of its symbol for nobody (Article II).
 */
describe('a chart of Histórico that is left on screen', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it('is never refreshed on its own, however long it is left there', async () => {
    await theDetailOf(TSLA.symbol);
    await chooseHistoric();

    vi.useFakeTimers({ shouldAdvanceTime: true });
    await plotWith('1min');
    await waitForTheChart();
    const asked = timesAskedForASeries();

    await vi.advanceTimersByTimeAsync(10 * ONE_MINUTE);

    expect(timesAskedForASeries()).toBe(asked);
  });

  it('keeps the chart it drew, with nothing added to it', async () => {
    // The other side of the same requirement: no timer means no request, and no request means the
    // chart a person is reading is still the one they asked for.
    await theDetailOf(TSLA.symbol);
    await chooseHistoric();

    vi.useFakeTimers({ shouldAdvanceTime: true });
    await plotWith('1min');
    const chart = await waitForTheChart();

    await vi.advanceTimersByTimeAsync(5 * ONE_MINUTE);

    await waitFor(() => {
      expect(theChart()).toBe(chart);
    });
  });
});
