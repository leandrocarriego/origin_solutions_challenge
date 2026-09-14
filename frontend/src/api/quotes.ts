/**
 * The quotes endpoint of our API: the series a chart is drawn from.
 *
 * It asks **our** API and never the provider (Article I, Article II). The two modes of the screen
 * are one address: without `from`/`to` it is today's session, with them the window the person
 * asked for. Which hours those are is the backend's decision -- it is the only side that knows
 * where the market trades -- so the two values travel exactly as they were written.
 *
 * The types are the generated ones (`schema.d.ts`, TS-03): writing the body by hand here would be
 * a second copy of the backend's schema, and the day a field changes only one of the two notices.
 */

import type { components } from './schema';
import { request } from './client';

/** The series and the state it is served in, 200 in all four of them (ERR-05). */
export type QuoteSeries = components['schemas']['QuoteSeriesResponse'];

/** One point of the chart: the instant in UTC, and the price as a string (`plan.md`). */
export type QuotePoint = components['schemas']['QuotePointOut'];

/** The three intervals of the statement (RF-06). */
export type QuoteInterval = components['schemas']['QuoteInterval'];

/** The window of `Histórico`, written in market hours and with no zone (RF-09, RF-16). */
export interface QuoteRange {
  from: string;
  to: string;
}

/**
 * The series of that symbol at that interval, for today or for the window asked for (RF-13, RF-16).
 *
 * It takes no identifier of a person, and that is Article III on this side: the chart is served
 * for the acciones of whoever is logged in, so there is no id to pass and none to substitute.
 *
 * The `signal` is what lets a newer request cancel the one before it: at `5min` the answer to a
 * `1min` question is a series of another shape, and an answer that lands late would draw a chart
 * nobody asked for any more.
 */
export async function getQuotes(
  symbol: string,
  interval: QuoteInterval,
  range?: QuoteRange,
  signal?: AbortSignal,
): Promise<QuoteSeries> {
  const parameters = new URLSearchParams({ interval });
  if (range) {
    parameters.set('from', range.from);
    parameters.set('to', range.to);
  }

  const address = `/quotes/${encodeURIComponent(symbol)}?${parameters.toString()}`;

  return signal === undefined
    ? await request<QuoteSeries>(address)
    : await request<QuoteSeries>(address, { signal });
}
