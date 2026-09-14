/**
 * The favourites endpoints of our API.
 *
 * The types are the generated ones (`schema.d.ts`, TS-03): writing the row of the grid by hand
 * here would be a second copy of the backend's schema, and the day a field changes only one of
 * the two would notice.
 *
 * No call here names a token. They are made from an inner screen, and who is calling is known by
 * the session and not by the screen: `client.ts` resolves it from the provider `SessionProvider`
 * registers.
 */

import type { components } from './schema';
import { request, send } from './client';

/** One row of `Mis Acciones`: the symbol, the name and the currency (RF-03). */
export type FavoriteItem = components['schemas']['FavoriteItem'];

/**
 * The favourites of whoever is logged in, in the order the backend decides (RF-01, RF-06).
 *
 * It takes no identifier, and that is Article III on this side: the list is the token's, so
 * there is no id to pass and none to substitute.
 */
export async function listFavorites(): Promise<FavoriteItem[]> {
  return await request<FavoriteItem[]>('/favorites');
}

/** What an addition did: whether it created the favourite, and the row of the grid either way. */
export interface FavoriteAddition {
  created: boolean;
  favorite: FavoriteItem;
}

/**
 * Add that symbol to the favourites of whoever is logged in (RF-15, RF-18).
 *
 * It goes through `send()` because the two answers differ only in the status: **201** means the
 * favourite was created and **200** that it was already on the list, with the same body. That is
 * what `Esa acción ya está en tu lista.` hangs on (RF-19), and it is the only call of the whole
 * application that needs the status.
 */
export async function addFavorite(symbol: string): Promise<FavoriteAddition> {
  const answer = await send<FavoriteItem>('/favorites', { method: 'POST', body: { symbol } });

  return { created: answer.status === 201, favorite: answer.data };
}

/**
 * Stop following that symbol (RF-24, RF-26).
 *
 * It answers 204 and carries no body, whether or not the action was on the list: removing twice
 * is the same wish twice, so there is no failure here to react to.
 */
export async function removeFavorite(symbol: string): Promise<void> {
  await send<void>(`/favorites/${encodeURIComponent(symbol)}`, { method: 'DELETE' });
}
