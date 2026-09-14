/**
 * The single door to our API (Article I): every call is origin-relative and goes to `/api`.
 *
 * Nothing here knows what a login is. What it knows is the shape of a call -- where it goes, what
 * it carries, what a refusal looks like -- and the one place where the rest of the application can
 * say what to do when the API stops recognising the session.
 */

/** The prefix every endpoint of ours hangs from. The provider's domain is never one of them. */
const BASE_PATH = '/api';

/** What runs when the API answers 401 to a call that was made with a session. */
type UnauthorizedHandler = () => void;

let onUnauthorized: UnauthorizedHandler | null = null;

/** Where the credential of a call comes from when the call does not name one. */
type TokenProvider = () => string | null;

let tokenProvider: TokenProvider | null = null;

/**
 * Register what happens when a session stops being accepted, or pass `null` to forget it.
 *
 * The correction is a single one for the whole application -- drop the session and send the
 * visitor to the login -- so it is registered once from `src/auth/` instead of being repeated by
 * every screen that makes a call.
 */
export function setUnauthorizedHandler(handler: UnauthorizedHandler | null): void {
  onUnauthorized = handler;
}

/**
 * Register where the token of a call comes from, or pass `null` to forget it.
 *
 * Registered once from `src/auth/`, by the same effect that registers the interceptor above and
 * for the same reason: who is calling is known by the session and not by the screen. Threading
 * the token through every function of `api/` would scatter the session across the application so
 * that each screen could forget to pass it.
 *
 * The client imports nothing of `auth/` -- that would be a cycle -- so the session stays the only
 * owner of the token and this is only the door it hands it through.
 */
export function setAuthTokenProvider(provider: TokenProvider | null): void {
  tokenProvider = provider;
}

/**
 * An answer from our API that is not a success, carrying the status so the caller can read it.
 *
 * It also carries the `detail` the answer came with, when it came with one. That is not decoration
 * for a log: a 422 of the chart says *which* rule the range broke and with what numbers
 * (`{"code": "range_too_long", "interval": "1min", "max_days": 7}`), and the screen turns that into
 * the sentence a person reads (RF-41, RF-45). Without it the caller would have to read the body a
 * second time, from a response that has already been consumed.
 *
 * It is `unknown` because it is whatever the API sent: whoever reads it has to narrow it, which is
 * where the shape of a particular endpoint belongs.
 */
export class ApiError extends Error {
  readonly status: number;

  readonly detail: unknown;

  constructor(status: number, detail: unknown = undefined) {
    super(`the API answered ${status}`);
    this.name = 'ApiError';
    this.status = status;
    this.detail = detail;
  }
}

interface RequestOptions {
  method?: 'GET' | 'POST' | 'DELETE';
  /** Aborts the call when it fires, which is how a newer search cancels the one before it. */
  signal?: AbortSignal;
  /** Serialised as JSON into the body, never into the address (RF-11). */
  body?: unknown;
  /**
   * The session this call is made with.
   *
   * It travels in `Authorization`, never in the address: a token in a query string ends up in
   * every access log on the way, and the identity of the caller is the credential and not a
   * parameter (Article III).
   *
   * It coexists with the session's provider, and the rule is one of precedence:
   *
   * | What the call declares | What goes out |
   * |---|---|
   * | `token: '<something>'` | that one -- the explicit wins, provider or not |
   * | `token: null` | nothing, provider or not: the call declares it carries no credential |
   * | absent | the provider's, if one is registered and has a token to give |
   *
   * The middle row is what `login()` declares, and it exists so that a call made before there is
   * a session does not depend on there happening to be no provider at that moment. The first is
   * `fetchMe(token)`, the call of the restoration: it asks whether a kept token is still good,
   * *before* the session is registered, and making it depend on the order of two effects is the
   * kind of coupling that works until somebody reorders them.
   */
  token?: string | null;
  /**
   * Whether a 401 means "this session is over".
   *
   * The login opts out: its 401 means the credential is wrong, and letting the session handler
   * catch it would announce an expiry to somebody who never had a session. Its 429 is not an
   * expiry either, and no status other than 401 reaches the handler anyway.
   */
  announcesLostSession?: boolean;
}

/** What our API answered: the body it carried, and the status it carried it with. */
interface Answer<T> {
  status: number;
  data: T;
}

/**
 * Call one of our endpoints and read the status as well as the body.
 *
 * The status is not a detail for one caller: `POST /api/favorites` answers **201** when it
 * created the favourite and **200** when it was already there, with the same body in both cases,
 * and `Esa acción ya está en tu lista.` is what that 200 means (RF-19). A client that parsed the
 * JSON and threw the status away would leave the screen unable to tell them apart.
 *
 * It is a second function and not a change to `request()`: making the existing one hand back a
 * pair would touch every call site `001` shipped for the sake of one case.
 */
export async function send<T>(path: string, options: RequestOptions = {}): Promise<Answer<T>> {
  const { method = 'GET', body, token, signal, announcesLostSession = true } = options;

  const headers = new Headers();
  if (body !== undefined) headers.set('Content-Type', 'application/json');
  const credential = token === undefined ? (tokenProvider?.() ?? null) : token;
  if (credential !== null) headers.set('Authorization', `Bearer ${credential}`);

  const response = await fetch(`${BASE_PATH}${path}`, {
    method,
    headers,
    // `null` and not `undefined` again: `exactOptionalPropertyTypes` asks for the absence to be
    // spelled, and `RequestInit` spells "no signal" that way.
    signal: signal ?? null,
    // `null` and not `undefined`: with `exactOptionalPropertyTypes` the absent body has to be
    // spelled, and `null` is how `RequestInit` spells "this call carries none".
    body: body === undefined ? null : JSON.stringify(body),
  });

  if (!response.ok) {
    if (response.status === 401 && announcesLostSession) onUnauthorized?.();

    // A refusal does not have to carry a body, and one that carries something that is not JSON is
    // still a refusal: the status is what every caller reads, and the detail is a bonus for the
    // ones that need it.
    throw new ApiError(response.status, await detailOf(response));
  }

  // A 204 carries no body at all, and `response.json()` on one throws -- in the happy path of
  // the removal, which is the worst place for it. There is nothing to parse and nothing to hand
  // back but the status.
  if (response.status === 204) return { status: response.status, data: undefined as T };

  return { status: response.status, data: (await response.json()) as T };
}

/** What a refusal carried in its `detail`, or nothing when it carried nothing readable. */
async function detailOf(response: Response): Promise<unknown> {
  try {
    return ((await response.json()) as { detail?: unknown }).detail;
  } catch {
    return undefined;
  }
}

/** Call one of our endpoints and read its JSON, or throw an `ApiError` with what it answered. */
export async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  return (await send<T>(path, options)).data;
}
