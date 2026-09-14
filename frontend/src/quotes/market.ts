/**
 * The two time zones of the product, and the little domain the screen, the chart and the two date
 * fields share. All of it is pure: no DOM, no Highcharts, nothing from React.
 *
 * It lives outside `components/` because the date fields need it and a screen importing the chart
 * to fill in two inputs is the dependency the wrong way round. And it lives outside the chart for
 * a second reason: Highcharts draws inside an SVG, jsdom computes no layout, and a `formatter`
 * that never runs cannot be asserted on -- so the arithmetic of RF-15, RF-36 and RF-38 sits here,
 * where a test can read it (`plan.md` -> *Frontend — estructura y contrato de pantalla*).
 *
 * None of these functions ever reads the clock of the machine. The zones are IANA names and they
 * always travel as `timeZone`; a `getHours()`, a `toLocaleString()` without a zone or a
 * `toISOString().slice(0, 16)` is the bug this feature exists to kill, and all three "work" on the
 * machine of whoever writes them.
 */

/** The market where the catalogue quotes: NYSE and NASDAQ, both here (A4, RF-36). */
export const MARKET_TIME_ZONE = 'America/New_York';

/** The Argentine hour, the second one the tooltip shows (RF-38). */
export const LOCAL_TIME_ZONE = 'America/Argentina/Buenos_Aires';

/** The three intervals of the statement (RF-06). The empty option of the selector is not one. */
export type QuoteInterval = '1min' | '5min' | '15min';

/** How often `Tiempo Real` refreshes, in milliseconds (RF-18): the interval itself. */
export const INTERVAL_MS: Readonly<Record<QuoteInterval, number>> = {
  '1min': 60_000,
  '5min': 300_000,
  '15min': 900_000,
};

/** The two labels the tooltip puts in front of each hour (RF-38, COPY.md). */
const MARKET_LABEL = 'Hora del mercado: ';
const LOCAL_LABEL = 'Hora de Argentina: ';

const TWENTY_FOUR_HOURS = 24 * 60 * 60 * 1000;

/**
 * What a clock in that zone reads at that instant, field by field.
 *
 * The parts and not `format()`: the order of the fields, the separator and the hour cycle are
 * data of the locale, they change between versions of ICU and between machines, and a string
 * built from them would make the locale load-bearing. What the platform decides here is the one
 * thing only it can decide -- which hour of which day that instant is, in that zone.
 */
function clockIn(zone: string, instant: Date): Record<string, string> {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: zone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(instant);

  return Object.fromEntries(parts.map((part) => [part.type, part.value]));
}

/** An instant written to be read: `DD/MM/YYYY HH:MM`, in market hours (RF-15, RF-36). */
export function formatMarket(instant: Date): string {
  return readable(clockIn(MARKET_TIME_ZONE, instant));
}

/** The same instant, in the Argentine hour and in the same shape (RF-38). */
export function formatLocal(instant: Date): string {
  return readable(clockIn(LOCAL_TIME_ZONE, instant));
}

/**
 * The market hour on its own, `HH:MM`, which is how the wireframe rotula the horizontal axis
 * (`13:10`, `13:11`, …) and the only reading that fits there without the labels overlapping.
 *
 * The same clock reading as `formatMarket`, without the date: a session fits inside one day, so
 * `11/09/2026` repeated on every tick adds nothing and covers the axis. Which day it is, is said
 * by the header -- `Horarios en hora del mercado.` -- and by the tooltip, which carries it whole.
 */
export function marketClockValue(instant: Date): string {
  const clock = clockIn(MARKET_TIME_ZONE, instant);

  return `${clock.hour}:${clock.minute}`;
}

/**
 * The same instant in the shape an `<input type="datetime-local">` eats, and that travels as it
 * is in `from`/`to`: `YYYY-MM-DDTHH:mm`, in market hours and with no zone -- the backend is the
 * one that localises it (`plan.md` -> *Contratos*).
 */
export function marketFieldValue(instant: Date): string {
  const clock = clockIn(MARKET_TIME_ZONE, instant);

  return `${clock.year}-${clock.month}-${clock.day}T${clock.hour}:${clock.minute}`;
}

/**
 * The last twenty-four hours, written in market hours and ready for the two fields (RF-10).
 *
 * Twenty-four hours of clock and not "the last session", which is a different thing and not what
 * the statement asks for. `now` is a parameter so a test can fix the clock without touching a
 * global; the screen calls it with no arguments.
 */
export function defaultHistoricRange(now: Date = new Date()): { from: string; to: string } {
  return {
    from: marketFieldValue(new Date(now.getTime() - TWENTY_FOUR_HOURS)),
    to: marketFieldValue(now),
  };
}

/**
 * The two lines of the tooltip, in order: the market first, Argentina second (RF-38).
 *
 * Two hours one under the other do not say which is which, so each one carries its label. Whoever
 * draws them joins them with a line break and neither adds nor removes text.
 */
export function tooltipTimeLines(instant: Date): readonly [string, string] {
  return [`${MARKET_LABEL}${formatMarket(instant)}`, `${LOCAL_LABEL}${formatLocal(instant)}`];
}

/** The reading of a clock as a person reads it: `DD/MM/YYYY HH:MM`. */
function readable(clock: Record<string, string>): string {
  return `${clock.day}/${clock.month}/${clock.year} ${clock.hour}:${clock.minute}`;
}
