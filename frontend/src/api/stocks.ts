/**
 * The catalogue endpoint of our API: the suggestions of the `Símbolo` field.
 *
 * It asks **our** API and never the provider (Article I, Article II): the suggestions come out of
 * the `stocks` table our own ingestion keeps current, so typing fast costs no quota at all.
 */

import type { components } from './schema';
import { request } from './client';

/** One line of the dropdown: symbol, name and currency (RF-08, RF-09). */
export type StockSuggestion = components['schemas']['StockSuggestion'];

/**
 * The actions whose symbol or name contains that text, at most twenty (RF-11).
 *
 * The `signal` is what lets a newer search cancel this one: answers that arrive out of order
 * would otherwise leave the dropdown showing the suggestions of a text that is no longer in the
 * field -- a race that happens every time somebody types fast and reproduces only sometimes.
 */
export async function searchStocks(q: string, signal?: AbortSignal): Promise<StockSuggestion[]> {
  const address = `/stocks?q=${encodeURIComponent(q)}`;

  return signal === undefined
    ? await request<StockSuggestion[]>(address)
    : await request<StockSuggestion[]>(address, { signal });
}
