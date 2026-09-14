/**
 * `quotes/market.ts` -- the two time zones of the product, and the four readings built on them.
 *
 * This is the half of `003-quote-chart` that a screen test cannot reach. Highcharts draws into an
 * SVG and jsdom computes no layout, so `RF-15` (every quote at the moment it belongs to), `RF-36`
 * (everything told in the market's hour) and `RF-38` (the two hours of the tooltip) have no
 * assertion available from the outside. `plan.md` -> *Frontend — estructura y contrato de pantalla*
 * moves the arithmetic out of the component into pure functions with a fixed signature, and fixes
 * what each one answers character by character. This file is the test that block enables.
 *
 * **Everything here is an instant in, a string out.** No DOM, no React, no `fetch`, and no clock of
 * the machine: `defaultHistoricRange` is exercised with its `now` injected, which is the reason the
 * plan gave it a parameter at all.
 *
 * **No test here may depend on the time zone of the machine running it**, and that is the point
 * rather than a nicety: the bug this feature exists to kill is a reading taken from the local
 * clock. Every expectation is either a literal the plan fixed or a value derived with an explicit
 * IANA zone, so `TZ=UTC`, `TZ=Asia/Tokyo` and a laptop in Buenos Aires have to agree.
 *
 * **The winter instant is not decoration.** New York changes to daylight saving time and Argentina
 * does not, so a September case alone is passed by a `+ 4 hours` written by hand. January is what
 * tells a real conversion apart from an offset, and it is why `RF-36` gets two instants and not
 * one.
 *
 * **Why the module is loaded and not imported.** `src/quotes/market.ts` does not exist yet -- this
 * is the red the Article VI gate signs -- and a static import of a missing module is a compile
 * error, which would stop the whole suite from running (`npx tsc --noEmit` included) instead of
 * turning these tests red. The load is deliberate and it fails loudly, by name, saying which module
 * is missing: that is the red of "no implementation yet", told apart from a typo by the message.
 * When the module lands, this becomes a plain import.
 */

import { beforeAll, describe, expect, it } from 'vitest';

/** The three intervals of the statement (RF-06). The empty option of the selector is not one. */
type QuoteInterval = '1min' | '5min' | '15min';

/** What `plan.md` -> *Frontend — estructura y contrato de pantalla* declares this module exports. */
interface MarketModule {
  readonly MARKET_TIME_ZONE: string;
  readonly LOCAL_TIME_ZONE: string;
  readonly INTERVAL_MS: Readonly<Record<QuoteInterval, number>>;
  formatMarket(instant: Date): string;
  formatLocal(instant: Date): string;
  marketFieldValue(instant: Date): string;
  marketClockValue(instant: Date): string;
  defaultHistoricRange(now?: Date): { from: string; to: string };
  tooltipTimeLines(instant: Date): readonly [string, string];
}

const MODULE_PATH = '../src/quotes/market';

let market: MarketModule;

beforeAll(async () => {
  market = (await import(/* @vite-ignore */ MODULE_PATH)) as MarketModule;
});

/**
 * The candle the tests of the feature share: 15:55 on the market clock of 11 September 2026, which
 * is 19:55 UTC and 16:55 in Argentina.
 */
const A_SEPTEMBER_INSTANT = new Date('2026-09-11T19:55:00Z');

/**
 * The same wall clock in UTC, six months earlier: the market is on standard time and Argentina is
 * not, so the two hours stop being four apart.
 */
const A_JANUARY_INSTANT = new Date('2026-01-15T19:55:00Z');

const ONE_MINUTE = 60_000;
const TWENTY_FOUR_HOURS = 24 * 60 * ONE_MINUTE;

/*
 * The literals of `plan.md`, written out once so that every assertion below points at the same
 * source. `DD/MM/YYYY HH:MM` for what a person reads, `YYYY-MM-DDTHH:mm` for what an
 * `<input type="datetime-local">` eats and what travels in `from`/`to`.
 */
const SEPTEMBER_IN_MARKET_TIME = '11/09/2026 15:55';
const SEPTEMBER_IN_LOCAL_TIME = '11/09/2026 16:55';
const SEPTEMBER_AS_A_FIELD_VALUE = '2026-09-11T15:55';
const JANUARY_IN_MARKET_TIME = '15/01/2026 14:55';
const JANUARY_IN_LOCAL_TIME = '15/01/2026 16:55';

/* The same two readings with the date dropped, which is how the wireframe rotula the axis. */
const SEPTEMBER_AS_A_CLOCK = '15:55';
const JANUARY_AS_A_CLOCK = '14:55';

/*
 * The two labels of the tooltip (RF-38), as the human fixed them on 2026-09-14: they echo the
 * vocabulary of the spec and the `Horarios en hora del mercado.` that already sits in the header.
 * Their two rows of `docs/design/COPY.md` are written by the `Solution-Designer` (UI-02).
 */
const MERCADO = 'Hora del mercado: ';
const ARGENTINA = 'Hora de Argentina: ';

/**
 * What a clock in `zone` reads at `instant`, computed here and independently of the module.
 *
 * It is the check that no expectation of this file is an offset written by hand: the platform
 * resolves the zone -- which is exactly what `Intl` is for -- and the zone is always named, never
 * left out so that "it takes the system's".
 */
function clockReadingIn(zone: string, instant: Date): string {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: zone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(instant);

  const part = (type: string): string => parts.find((one) => one.type === type)?.value ?? '';

  return `${part('day')}/${part('month')}/${part('year')} ${part('hour')}:${part('minute')}`;
}

describe('the two time zones of the product', () => {
  it('name the market where the catalogue quotes, as an IANA zone', () => {
    // RF-36: NYSE and NASDAQ, both in the same zone (A4), so it is a constant of the product and
    // not a column of the database.
    expect(market.MARKET_TIME_ZONE).toBe('America/New_York');
  });

  it('name Argentina, which is the second hour of the tooltip', () => {
    // RF-38. It is written as an IANA zone too, and not as a number of hours: an offset written by
    // hand is the bug, and Buenos Aires is not `-3` in a way anybody should have to remember.
    expect(market.LOCAL_TIME_ZONE).toBe('America/Argentina/Buenos_Aires');
  });
});

describe('how often Tiempo Real refreshes', () => {
  it('is the duration of each of the three intervals, in milliseconds', () => {
    // RF-18: the chart of `1min` gets a new point after a minute, and the same rule holds for the
    // other two. The numbers are the interval itself, which is why nobody has to choose them.
    expect(market.INTERVAL_MS['1min']).toBe(60_000);
    expect(market.INTERVAL_MS['5min']).toBe(300_000);
    expect(market.INTERVAL_MS['15min']).toBe(900_000);
  });

  it('is declared for the three intervals of the statement and for nothing else', () => {
    // RF-06: the empty option of the selector is not an interval, so it has no duration either.
    expect(Object.keys(market.INTERVAL_MS).sort()).toEqual(['15min', '1min', '5min']);
  });
});

describe('an instant written in the market hour', () => {
  it('is the market clock reading, in DD/MM/YYYY HH:MM', () => {
    // RF-36, on the candle the screen tests share: 19:55 UTC is 15:55 in New York.
    expect(market.formatMarket(A_SEPTEMBER_INSTANT)).toBe(SEPTEMBER_IN_MARKET_TIME);
  });

  it('follows the market through its change of season', () => {
    // The same UTC wall clock in January reads 14:55 and not 15:55, because New York is on
    // standard time. A `+ 4 hours` written by hand passes the test above and fails this one, which
    // is the whole reason there are two instants and not one.
    expect(market.formatMarket(A_JANUARY_INSTANT)).toBe(JANUARY_IN_MARKET_TIME);
  });

  it('says what a clock in the market zone says, and never what the machine says', () => {
    // The expectation is computed here, naming the zone: if this test ever disagrees with the two
    // above, it is the literals that moved -- never the time zone of whoever ran the suite.
    expect(market.formatMarket(A_SEPTEMBER_INSTANT)).toBe(
      clockReadingIn('America/New_York', A_SEPTEMBER_INSTANT),
    );
    expect(market.formatMarket(A_JANUARY_INSTANT)).toBe(
      clockReadingIn('America/New_York', A_JANUARY_INSTANT),
    );
  });
});

describe('the same instant written in the Argentine hour', () => {
  it('is the Argentine clock reading, in the same format', () => {
    // RF-38: 19:55 UTC is 16:55 in Buenos Aires.
    expect(market.formatLocal(A_SEPTEMBER_INSTANT)).toBe(SEPTEMBER_IN_LOCAL_TIME);
  });

  it('stays put when the market changes season, because Argentina does not', () => {
    // 16:55 in both instants, against 15:55 and 14:55 on the market side: the distance between the
    // two hours of the tooltip is not a constant, and this is where that shows.
    expect(market.formatLocal(A_JANUARY_INSTANT)).toBe(JANUARY_IN_LOCAL_TIME);
  });

  it('says what a clock in Buenos Aires says, and never what the machine says', () => {
    expect(market.formatLocal(A_SEPTEMBER_INSTANT)).toBe(
      clockReadingIn('America/Argentina/Buenos_Aires', A_SEPTEMBER_INSTANT),
    );
    expect(market.formatLocal(A_JANUARY_INSTANT)).toBe(
      clockReadingIn('America/Argentina/Buenos_Aires', A_JANUARY_INSTANT),
    );
  });
});

describe('an instant written for a date field', () => {
  it('is the market hour in the shape the field eats, and without a zone', () => {
    // `YYYY-MM-DDTHH:mm`, which is what an `<input type="datetime-local">` reads back and what
    // travels in `from`/`to` (`plan.md` -> *Contratos*: the backend is the one that localises it).
    expect(market.marketFieldValue(A_SEPTEMBER_INSTANT)).toBe(SEPTEMBER_AS_A_FIELD_VALUE);
  });

  it('carries no offset and no trailing Z', () => {
    // A `toISOString().slice(0, 16)` would answer `2026-09-11T19:55` here: same shape, wrong hour,
    // and nothing on screen to tell the difference. What it must not carry is the zone, because
    // the value means market time by contract.
    const value = market.marketFieldValue(A_SEPTEMBER_INSTANT);

    expect(value).not.toContain('Z');
    expect(value).not.toContain('+');
  });

  it('reads the same clock the market hour reads, in the other season too', () => {
    // Derived from the two functions being the same reading in two shapes: in January the field
    // says 14:55 because the market does, and not because anybody subtracted an hour.
    expect(market.marketFieldValue(A_JANUARY_INSTANT)).toBe('2026-01-15T14:55');
    expect(market.marketFieldValue(A_JANUARY_INSTANT)).toContain(
      market.formatMarket(A_JANUARY_INSTANT).slice(-5),
    );
  });
});

describe('the hour the horizontal axis is labelled with', () => {
  it('is the market clock, with no date on it', () => {
    // The wireframe rotula the axis `13:10  13:11  13:12`: a session fits inside one day, so the
    // date repeated on every tick adds nothing and covers the axis. Which day it is, is said by
    // the header -- `Horarios en hora del mercado.` -- and by the tooltip, which carries it whole.
    expect(market.marketClockValue(A_SEPTEMBER_INSTANT)).toBe(SEPTEMBER_AS_A_CLOCK);
  });

  it('follows the market through its change of season', () => {
    // RF-36 again, on the reading the axis actually shows: in January the market is on standard
    // time and the same UTC wall clock reads 14:55. An offset written by hand fails here.
    expect(market.marketClockValue(A_JANUARY_INSTANT)).toBe(JANUARY_AS_A_CLOCK);
  });

  it('says what a clock in the market zone says, and never what the machine says', () => {
    // Computed here naming the zone, so this stays true on any machine the suite runs on.
    expect(market.marketClockValue(A_SEPTEMBER_INSTANT)).toBe(
      clockReadingIn('America/New_York', A_SEPTEMBER_INSTANT).slice(-5),
    );
    expect(market.marketClockValue(A_JANUARY_INSTANT)).toBe(
      clockReadingIn('America/New_York', A_JANUARY_INSTANT).slice(-5),
    );
  });

  it('is the very hour the full reading ends with', () => {
    // The relation, so the two cannot drift apart: whatever mask `formatMarket` writes, the axis
    // and the tooltip are telling the same clock about the same instant (RF-15, RF-36).
    expect(
      market
        .formatMarket(A_SEPTEMBER_INSTANT)
        .endsWith(market.marketClockValue(A_SEPTEMBER_INSTANT)),
    ).toBe(true);
    expect(
      market.formatMarket(A_JANUARY_INSTANT).endsWith(market.marketClockValue(A_JANUARY_INSTANT)),
    ).toBe(true);
  });

  it('carries no date, in any shape', () => {
    // What the hallazgo was about: `11/09/2026 15:55` on every tick is the reading this replaces.
    const written = market.marketClockValue(A_SEPTEMBER_INSTANT);

    expect(written).toHaveLength(5);
    expect(written).not.toContain('/');
    expect(written).not.toContain('2026');
  });
});

describe('the period the two date fields come filled with', () => {
  it('is the last twenty-four hours, told in market time', () => {
    // RF-10, with the clock injected: `to` is `now` and `from` is `now` minus twenty-four hours of
    // clock -- not "the last session", which is a different thing and not what the statement asks.
    expect(market.defaultHistoricRange(A_SEPTEMBER_INSTANT)).toEqual({
      from: '2026-09-10T15:55',
      to: '2026-09-11T15:55',
    });
  });

  it('writes both ends the way the fields and the query expect them', () => {
    // The two values are `marketFieldValue` of the two instants: one shape for the field, the
    // query and the tests, so nobody writes the mask twice.
    const range = market.defaultHistoricRange(A_SEPTEMBER_INSTANT);
    const twentyFourHoursEarlier = new Date(A_SEPTEMBER_INSTANT.getTime() - TWENTY_FOUR_HOURS);

    expect(range.to).toBe(market.marketFieldValue(A_SEPTEMBER_INSTANT));
    expect(range.from).toBe(market.marketFieldValue(twentyFourHoursEarlier));
  });

  it('takes its twenty-four hours from the instant it is given, in any season', () => {
    // The same rule in January, where the market hour is a different one: what is fixed is the
    // distance between the two ends, and that each end is told in the market's hour.
    const range = market.defaultHistoricRange(A_JANUARY_INSTANT);
    const twentyFourHoursEarlier = new Date(A_JANUARY_INSTANT.getTime() - TWENTY_FOUR_HOURS);

    expect(range.to).toBe(market.marketFieldValue(A_JANUARY_INSTANT));
    expect(range.from).toBe(market.marketFieldValue(twentyFourHoursEarlier));
  });
});

describe('the two lines of the tooltip', () => {
  it('are the market hour first and the Argentine hour second, each saying which it is', () => {
    // RF-38 in full: two hours for the same quote, and a label on each -- two hours in a row with
    // nothing to tell them apart do not answer the requirement.
    expect(market.tooltipTimeLines(A_SEPTEMBER_INSTANT)).toEqual([
      `${MERCADO}${SEPTEMBER_IN_MARKET_TIME}`,
      `${ARGENTINA}${SEPTEMBER_IN_LOCAL_TIME}`,
    ]);
  });

  it('carry the two readings of the very instant they were given', () => {
    // The relation, so that the pair keeps meaning what it means the day the labels or the mask
    // change: line one is `formatMarket` of that instant, line two is `formatLocal` of the same.
    const [firstLine, secondLine] = market.tooltipTimeLines(A_JANUARY_INSTANT);

    expect(firstLine).toBe(`${MERCADO}${market.formatMarket(A_JANUARY_INSTANT)}`);
    expect(secondLine).toBe(`${ARGENTINA}${market.formatLocal(A_JANUARY_INSTANT)}`);
    expect(firstLine).toContain(JANUARY_IN_MARKET_TIME);
    expect(secondLine).toContain(JANUARY_IN_LOCAL_TIME);
  });

  it('are exactly two, in that order, for the component to join and draw', () => {
    // What the chart does with them is one line without decisions:
    // `tooltipTimeLines(new Date(this.x)).join('<br/>')`. So the order is part of the contract.
    const lines = market.tooltipTimeLines(A_SEPTEMBER_INSTANT);

    expect(lines).toHaveLength(2);
    expect(lines[0].startsWith(MERCADO)).toBe(true);
    expect(lines[1].startsWith(ARGENTINA)).toBe(true);
  });
});

describe('a series of candles as the chart receives it', () => {
  /** Five candles five minutes apart, ending at the shared instant: what `5min` answers. */
  const FIVE_CANDLES = [4, 3, 2, 1, 0].map(
    (howManyBack) => new Date(A_SEPTEMBER_INSTANT.getTime() - howManyBack * 5 * ONE_MINUTE),
  );

  it('puts every quote at the moment it belongs to, with no shift', () => {
    // RF-15: the instant that goes in is the instant that comes out. The expectation is computed
    // from each instant naming the market zone, so a module that stamps UTC, that reads the
    // machine's clock, or that adds a fixed number of hours fails here on at least one instant.
    const written = FIVE_CANDLES.map((candle) => market.formatMarket(candle));

    expect(written).toEqual(
      FIVE_CANDLES.map((candle) => clockReadingIn('America/New_York', candle)),
    );
    expect(written).toEqual([
      '11/09/2026 15:35',
      '11/09/2026 15:40',
      '11/09/2026 15:45',
      '11/09/2026 15:50',
      '11/09/2026 15:55',
    ]);
  });

  it('keeps the hours moving forward, five minutes at a time', () => {
    // The second half of RF-15: the hours advance from left to right. Written as the readings
    // being strictly increasing, which is what "forward" means once the axis is a time axis.
    const written = FIVE_CANDLES.map((candle) => market.formatMarket(candle));

    expect([...written].sort()).not.toEqual(written.slice().reverse());
    written.forEach((reading, index) => {
      if (index > 0) {
        expect(reading > (written[index - 1] as string)).toBe(true);
      }
    });
  });
});
