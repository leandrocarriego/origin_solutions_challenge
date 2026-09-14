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

/** An answer from our API that is not a success, carrying the status so the caller can read it. */
export class ApiError extends Error {
  readonly status: number;

  constructor(status: number) {
    super(`the API answered ${status}`);
    this.name = 'ApiError';
    this.status = status;
  }
}

interface RequestOptions {
  method?: 'GET' | 'POST';
  /** Serialised as JSON into the body, never into the address (RF-11). */
  body?: unknown;
  /**
   * The session this call is made with.
   *
   * It travels in `Authorization`, never in the address: a token in a query string ends up in
   * every access log on the way, and the identity of the caller is the credential and not a
   * parameter (Article III).
   */
  token?: string;
  /**
   * Whether a 401 means "this session is over".
   *
   * The login opts out: its 401 means the credential is wrong, and letting the session handler
   * catch it would announce an expiry to somebody who never had a session. Its 429 is not an
   * expiry either, and no status other than 401 reaches the handler anyway.
   */
  announcesLostSession?: boolean;
}

/** Call one of our endpoints and read its JSON, or throw an `ApiError` with what it answered. */
export async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const { method = 'GET', body, token, announcesLostSession = true } = options;

  const headers = new Headers();
  if (body !== undefined) headers.set('Content-Type', 'application/json');
  if (token !== undefined) headers.set('Authorization', `Bearer ${token}`);

  const response = await fetch(`${BASE_PATH}${path}`, {
    method,
    headers,
    // `null` and not `undefined`: with `exactOptionalPropertyTypes` the absent body has to be
    // spelled, and `null` is how `RequestInit` spells "this call carries none".
    body: body === undefined ? null : JSON.stringify(body),
  });

  if (!response.ok) {
    if (response.status === 401 && announcesLostSession) onUnauthorized?.();

    throw new ApiError(response.status);
  }

  return (await response.json()) as T;
}
