/**
 * `Detalle de Acción` -- wireframe 03: the two ways of asking, the interval, `Graficar` and the
 * chart they draw.
 *
 * **The header is the bar of `001` with two props more** (RF-01, RF-34, RF-37). This screen does
 * not draw a bar of its own: a second one would either duplicate `Usuario: {nombre completo}` and
 * `Cerrar sesión` or leave the Detail without them, and that half belongs to every inner screen.
 *
 * **The header and the membership come from the same request.** `GET /api/favorites` already
 * answers symbol, name and currency, so the title is assembled from it (RF-01) and the same list
 * decides whether the action is one of this person's (RF-35). An endpoint for that would be a
 * second way of asking the same question.
 *
 * **The chart is remounted only when somebody presses `Graficar`** (RF-17). The `key` is the
 * request that was served, so a refresh -- which changes the points and nothing else -- draws into
 * the chart that is already there (RF-19, RF-20).
 *
 * **The validation is split, and the split has a rule.** What is *presence* is resolved here,
 * because without it there is no request to build: no interval chosen (RF-39) and an empty date
 * field (RF-40). What is a *rule of the business* -- `desde` before `hasta`, and how long a range
 * may be -- is the backend's, and this screen only draws what the 422 says, filling `{intervalo}`
 * and `{N}` from the body (RF-41, RF-45). The caps live in one place and are not copied here: a
 * rule written on both ends is a rule that one day disagrees with itself.
 *
 * In all four refusals nothing is asked of our API or is drawn: `plotted` is untouched, so the
 * chart that was on screen stays exactly as it was (RF-46, RF-47, RF-48).
 */

import { useCallback, useEffect, useRef, useState, type JSX } from 'react';
import { Navigate, useParams } from 'react-router';

import { ApiError } from '../api/client';
import { listFavorites, type FavoriteItem } from '../api/favorites';
import { getQuotes, type QuoteInterval, type QuoteSeries } from '../api/quotes';
import { Notice } from '../components/Notice';
import { QuoteChart } from '../components/QuoteChart';
import { Header } from '../components/Header';
import { INTERVAL_MS, defaultHistoricRange } from '../quotes/market';

/** Verbatim from the `Detalle de Acción` table of docs/design/COPY.md (UI-02). */
const TIEMPO_REAL = 'Tiempo Real';
/* prettier-ignore -- one unbroken literal: UI-02 asks for the text of the brief verbatim, and a
   string split across two lines is a string no source file contains. */
const ACLARACION_TIEMPO_REAL =
  '( utiliza la fecha actual, al graficar esta opcion, se debe actualizar el gráfico en forma automática segun el intervalo seleccionado)';
const HISTORICO = 'Histórico';
const FECHA_DESDE = 'Fecha hora desde';
const FECHA_HASTA = 'Fecha hora hasta';
const INTERVALO = 'Intervalo';
const ACLARACION_INTERVALO = '( opciones 1min / 5min / 15min)';
const GRAFICAR = 'Graficar';

/** Verbatim from *Detalle: navegación, horarios y validación* of docs/design/COPY.md (UI-02). */
const MIS_ACCIONES = 'Mis Acciones';
const HORARIOS = 'Horarios en hora del mercado.';
const ELEGI_INTERVALO = 'Elegí un intervalo.';
const FECHAS_AL_REVES = 'La fecha desde tiene que ser anterior a la fecha hasta.';
const RANGO_EXCEDIDO = (interval: string, days: number): string =>
  `El rango es demasiado largo para el intervalo ${interval}. El máximo es ${days} días.`;

/** Verbatim from `Sesión y validación`: an empty field is the same oversight on every screen. */
const COMPLETA_ESTE_CAMPO = 'Completá este campo.';

/**
 * Verbatim from `Sesión y validación`, and the same sentence the login shows for the same fact.
 *
 * It is what is left when the request taught us nothing: no answer to read, or one that says
 * something this screen has no reading for. Inventing a second text for "we could not get the
 * data" would be one more string to keep for no fact the first one does not already carry, which
 * is the reason `Completá este campo.` is shared between the two screens as well.
 */
const NO_SE_PUDO_CONECTAR =
  'No pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.';

/** The three intervals of the statement, and the empty option the selector opens on (RF-06). */
const INTERVALS: QuoteInterval[] = ['1min', '5min', '15min'];

/** Which of the two ways of asking is marked (RF-03, RF-04). */
type Mode = 'realtime' | 'historic';

/** A query that was served: what the chart is showing, and what a refresh asks for again. */
interface PlotRequest {
  symbol: string;
  mode: Mode;
  interval: QuoteInterval;
  from: string;
  to: string;
}

/** The notices hanging off the controls, each under the one it talks about (RF-39 to RF-45). */
interface Errors {
  interval?: string;
  from?: string;
  to?: string;
  range?: string;
  // Not a control's notice but the query's: it qualifies the chart and so is drawn above it
  // (UI-05), next to the notices of the four states.
  plot?: string;
}

/**
 * Whether a rejection is this screen cancelling its own request rather than a failure.
 *
 * Every query aborts the one before it, so the one before it rejects. That is the screen working
 * and not the server missing, and telling the person we could not connect because they changed
 * the interval twice would be a lie about a request nobody is waiting for any more.
 *
 * The name and not `instanceof Error`, which is the shape this took first and is a trap: what an
 * aborted `fetch` rejects with is a `DOMException`, and `instanceof` is a question about the realm
 * the object was made in. A browser's inherits from that realm's `Error` and passes; jsdom's does
 * not, and neither would one crossing a frame. The check would then read a cancellation as a
 * failure and show a notice about a request nobody is waiting for -- which is the exact bug this
 * function exists to prevent. What every realm agrees on is the name.
 */
function wasCancelled(error: unknown): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    (error as { name?: unknown }).name === 'AbortError'
  );
}

/** What the 422 of our API means, in the words the client wrote (RF-41, RF-45). */
function refusalText(detail: unknown): string | null {
  if (typeof detail !== 'object' || detail === null) return null;

  const { code, interval, max_days: maxDays } = detail as Record<string, unknown>;

  if (code === 'range_invalid') return FECHAS_AL_REVES;
  if (code === 'range_too_long' && typeof interval === 'string' && typeof maxDays === 'number') {
    return RANGO_EXCEDIDO(interval, maxDays);
  }

  return null;
}

/**
 * The favourites of the session, or `null` when our API did not answer with a list.
 *
 * The two outcomes are kept apart by whoever calls this, and that is the point: a list that came
 * back without this symbol means the action is not this person's (RF-35), while a list that never
 * came back means nothing about whose it is. Reading the second as the first would answer a
 * question the server never got to.
 */
async function theListOfTheSession(): Promise<FavoriteItem[] | null> {
  try {
    return await listFavorites();
  } catch {
    return null;
  }
}

export function ActionDetail(): JSX.Element | null {
  const { symbol = '' } = useParams<{ symbol: string }>();

  // `undefined` is "still asking", `null` is "not one of this person's" (RF-35): while the first
  // is true nothing is painted, so no control of a screen that may not open flashes (TS-06).
  const [favorite, setFavorite] = useState<FavoriteItem | null | undefined>(undefined);
  const [mode, setMode] = useState<Mode>('realtime');
  const [interval, setInterval] = useState<QuoteInterval | ''>('');
  // RF-10: the last twenty-four hours of market time, filled in from the moment the screen opens.
  const [range, setRange] = useState(() => defaultHistoricRange());
  const [plotted, setPlotted] = useState<PlotRequest | null>(null);
  const [series, setSeries] = useState<QuoteSeries | null>(null);
  const [errors, setErrors] = useState<Errors>({});
  // The list never came back, which is not the same as the action not being on it (RF-35).
  const [listUnreachable, setListUnreachable] = useState(false);
  // The automatic refresh stopped landing, so what is drawn is older than it looks. The chart
  // stays -- taking it away would punish the reader for a network they do not control -- and the
  // notice says so, in the words `Avisos de estado` already has for that fact.
  const [refreshFailed, setRefreshFailed] = useState(false);

  // The request in flight, so the next one can cancel it: at `5min` the answer to a `1min`
  // question is a series of another shape, and one that lands late would draw a chart nobody is
  // asking for any more.
  const inFlight = useRef<AbortController | null>(null);

  useEffect(() => {
    let abandoned = false;

    void (async (): Promise<void> => {
      const list = await theListOfTheSession();
      if (abandoned) return;

      if (list === null) {
        setListUnreachable(true);
        return;
      }

      setFavorite(list.find((one) => one.symbol === symbol) ?? null);
    })();

    return () => {
      abandoned = true;
    };
  }, [symbol]);

  const ask = useCallback(async (request: PlotRequest): Promise<QuoteSeries> => {
    inFlight.current?.abort();
    const controller = new AbortController();
    inFlight.current = controller;

    return await getQuotes(
      request.symbol,
      request.interval,
      request.mode === 'historic' ? { from: request.from, to: request.to } : undefined,
      controller.signal,
    );
  }, []);

  // The refresh of `Tiempo Real` (RF-18): the same request again, and only `series` changes -- the
  // `key` of the chart is `plotted`, so what is on screen is redrawn and not rebuilt (RF-19).
  const refresh = useCallback(
    async (request: PlotRequest): Promise<void> => {
      try {
        setSeries(await ask(request));
        setRefreshFailed(false);
      } catch (error) {
        // The chart keeps the last series it was given: a refresh that did not land is not a
        // reason to take away what the person is reading. But it is a reason to say so -- silence
        // made a chart that stopped updating half an hour ago look exactly like one that is
        // current, which is the reading this notice exists to prevent (ERR-06).
        if (!wasCancelled(error)) setRefreshFailed(true);
      }
    },
    [ask],
  );

  useEffect(() => {
    // RF-23: a period that already ended does not change, so `Histórico` arms no timer at all.
    if (plotted === null || plotted.mode !== 'realtime') return undefined;

    let timer: ReturnType<typeof globalThis.setInterval> | null = null;

    const stop = (): void => {
      if (timer !== null) globalThis.clearInterval(timer);
      timer = null;
    };

    const arm = (): void => {
      stop();
      timer = globalThis.setInterval(() => {
        void refresh(plotted);
      }, INTERVAL_MS[plotted.interval]);
    };

    const onVisibilityChange = (): void => {
      // RF-21 and Article II: a forgotten tab renewing the TTL of its symbol all session long is
      // quota spent by nobody. RF-22: coming back asks at once, because waiting a whole interval
      // would show a chart that is visibly out of date.
      if (document.visibilityState === 'hidden') {
        stop();
        return;
      }

      void refresh(plotted);
      arm();
    };

    arm();
    document.addEventListener('visibilitychange', onVisibilityChange);

    return () => {
      stop();
      document.removeEventListener('visibilitychange', onVisibilityChange);
    };
  }, [plotted, refresh]);

  async function plot(): Promise<void> {
    // RF-39 and RF-40: what is missing is presence, and presence is resolved here -- without it
    // there is no request to build. In both cases nothing is asked of our API and nothing is
    // drawn, so whatever chart is on screen stays exactly as it is (RF-46, RF-47, RF-48).
    if (interval === '') {
      setErrors({ interval: ELEGI_INTERVALO });
      return;
    }

    if (mode === 'historic') {
      const missing: Errors = {};
      if (range.from === '') missing.from = COMPLETA_ESTE_CAMPO;
      if (range.to === '') missing.to = COMPLETA_ESTE_CAMPO;

      if (missing.from !== undefined || missing.to !== undefined) {
        setErrors(missing);
        return;
      }
    }

    const request: PlotRequest = { symbol, mode, interval, from: range.from, to: range.to };

    try {
      const answer = await ask(request);
      setErrors({});
      setSeries(answer);
      setPlotted(request);
      // A query that landed is the chart being current again, whatever the refreshes before it did.
      setRefreshFailed(false);
    } catch (error) {
      // The same invariant as the four above: a refusal draws its notice and touches nothing else
      // -- `plotted` is untouched, so whatever chart is on screen stays exactly as it was.
      if (wasCancelled(error)) return;

      const refused = error instanceof ApiError ? refusalText(error.detail) : null;
      // Everything that is not one of the two range refusals is the same fact from the person's
      // side: the chart could not be got. Leaving it silent was worse than any wording -- pressing
      // `Graficar` appeared to do nothing at all (ERR-06, TS-06).
      setErrors(refused !== null ? { range: refused } : { plot: NO_SE_PUDO_CONECTAR });
    }
  }

  // The list did not answer, so whose this action is was never established: the screen says so
  // instead of sending the person to `Mis Acciones`, which would assert the action is not theirs
  // (RF-35) on the strength of a question the server never answered.
  if (listUnreachable) {
    return (
      <p role="status" className="mx-auto max-w-5xl px-6 py-6 text-error">
        {NO_SE_PUDO_CONECTAR}
      </p>
    );
  }

  if (favorite === undefined) return null;
  if (favorite === null) return <Navigate to="/" replace />;

  return (
    <div className="mx-auto max-w-5xl px-6">
      <Header
        title={`${favorite.symbol} - ${favorite.name} - ${favorite.currency}`}
        back={{ to: '/', label: MIS_ACCIONES }}
        note={HORARIOS}
      />

      {/*
        Three rows and a fourth with the button, which is how wireframe 03 draws them: the note to
        the right of the radio, the two date fields to the right of `Histórico`, and the selector
        with its note to the right of `Intervalo`. The first cell of every row is the same width,
        which is what lines the column of controls up.

        Each notice hangs off the control that caused it and so does not live in the row: the one
        of a date field goes under that field (RF-40), the one of the range under both of them
        (RF-41, RF-45) and the one of the interval under the selector (RF-39).
      */}
      <section className="my-6 flex flex-col gap-4">
        <div className="flex flex-wrap items-center gap-4">
          <label className="flex w-40 items-center gap-2">
            <input
              type="radio"
              name="mode"
              checked={mode === 'realtime'}
              onChange={() => {
                setMode('realtime');
              }}
            />
            {TIEMPO_REAL}
          </label>
          <span className="text-text-muted">{ACLARACION_TIEMPO_REAL}</span>
        </div>

        <div className="flex flex-wrap items-start gap-4">
          <label className="flex w-40 items-center gap-2 pt-1">
            <input
              type="radio"
              name="mode"
              checked={mode === 'historic'}
              onChange={() => {
                setMode('historic');
              }}
            />
            {HISTORICO}
          </label>

          <div className="flex flex-col gap-1">
            <input
              type="datetime-local"
              aria-label={FECHA_DESDE}
              placeholder={FECHA_DESDE}
              value={range.from}
              onChange={(event) => {
                setRange({ ...range, from: event.target.value });
              }}
              className="border border-border bg-surface p-1"
            />
            {errors.from && <p className="m-0 text-error">{errors.from}</p>}
          </div>

          <div className="flex flex-col gap-1">
            <input
              type="datetime-local"
              aria-label={FECHA_HASTA}
              placeholder={FECHA_HASTA}
              value={range.to}
              onChange={(event) => {
                setRange({ ...range, to: event.target.value });
              }}
              className="border border-border bg-surface p-1"
            />
            {errors.to && <p className="m-0 text-error">{errors.to}</p>}
          </div>
        </div>

        {errors.range && <p className="m-0 pl-40 text-error">{errors.range}</p>}

        <div className="flex flex-wrap items-center gap-4">
          <label className="w-40" htmlFor="interval">
            {INTERVALO}
          </label>
          <select
            id="interval"
            value={interval}
            onChange={(event) => {
              setInterval(event.target.value as QuoteInterval | '');
            }}
            className="border border-border bg-surface p-1"
          >
            <option value="" />
            {INTERVALS.map((one) => (
              <option key={one} value={one}>
                {one}
              </option>
            ))}
          </select>
          <span className="text-text-muted">{ACLARACION_INTERVALO}</span>
        </div>

        {errors.interval && <p className="m-0 pl-40 text-error">{errors.interval}</p>}

        <div className="pl-40">
          <button
            type="button"
            onClick={() => {
              void plot();
            }}
            className="border border-border bg-surface px-3 py-1"
          >
            {GRAFICAR}
          </button>
        </div>
      </section>

      {/* UI-05: the notice qualifies the data that is about to be read, so it goes before it. */}
      {errors.plot && (
        <p role="status" className="my-3 text-error">
          {errors.plot}
        </p>
      )}
      {series && <Notice series={series} refreshFailed={refreshFailed} />}

      {plotted && series && (
        <QuoteChart
          key={`${plotted.symbol}|${plotted.mode}|${plotted.interval}|${plotted.from}|${plotted.to}`}
          symbol={plotted.symbol}
          points={series.points}
        />
      )}
    </div>
  );
}
