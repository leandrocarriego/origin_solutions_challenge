/**
 * The authentication endpoints of our API.
 *
 * The types are the generated ones (`schema.d.ts`, TS-03): writing `interface LoginResponse` by
 * hand here would be a second copy of the backend's schema, and the day a field changes only one
 * of the two would notice.
 */

import type { components } from './schema';
import { request } from './client';

/** What a good credential buys: the token, how long it lasts, and the name to paint. */
export type Session = components['schemas']['LoginResponse'];

type Credential = components['schemas']['LoginRequest'];

/**
 * Exchange a username and a password for a session.
 *
 * It steps around the session interceptor on purpose: a 401 here means `usuario o clave
 * invalida` and a 429 means the attempt limit is holding, and neither is a session that expired.
 * If the interceptor caught them, the screen would reload itself instead of saying what happened.
 */
export async function login(username: string, password: string): Promise<Session> {
  const credential: Credential = { username, password };

  return await request<Session>('/auth/login', {
    method: 'POST',
    body: credential,
    announcesLostSession: false,
  });
}

/** Who the presented token identifies: two fields, and never the row behind them. */
export type CurrentUser = components['schemas']['CurrentUserResponse'];

/**
 * Ask our API whether a kept token is still good, and who it says is calling.
 *
 * It takes no identifier, and that is the whole of Article III on this side: the identity is the
 * token, so there is nothing to substitute. Its 401 does go through the session interceptor -- here
 * a refusal *is* a session that ended, which is the one case the notice of `RF-17` exists for.
 */
export async function fetchMe(token: string): Promise<CurrentUser> {
  return await request<CurrentUser>('/auth/me', { token });
}
