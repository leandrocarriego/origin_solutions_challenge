/**
 * `api/client.ts`: which `Authorization` header goes out, and it is a rule of **precedence**.
 *
 * There are two ways of naming the credential of a call and they coexist on purpose (`plan.md` →
 * *Contratos* → *Frontend*): the explicit `token` of `RequestOptions`, which `001` already shipped
 * and which `fetchMe` uses during the restoration, and the provider the session registers so that
 * an inner screen does not have to thread the token through every call.
 *
 * "It sends the Bearer when there is a token registered" is not a specification while both are in
 * play, so the plan writes three rows and this file writes one test per row:
 *
 * | What the call declares | What goes out |
 * |---|---|
 * | `token: '<something>'` | `Bearer <something>` -- the explicit one wins, provider or not |
 * | `token: null` | nothing, provider or not: the call declares it is made without a session |
 * | `token` absent | the provider's, if one is registered and returns a token; nothing otherwise |
 *
 * The second row is `login()`, which happens before there is any session, and the third is the
 * five new routes of `002`. The first is `fetchMe(token)`, which is the call of the *restoration*:
 * if the provider were the only path, whether that call carried a header would depend on the order
 * in which `SessionProvider` runs its effects -- an invisible coupling that works until somebody
 * reorders two `useEffect`. So the last test here is the one that fixes that nothing of `001`
 * changed behaviour.
 *
 * **Why `registerTokenProvider` goes through a cast.** `setAuthTokenProvider` does not exist yet --
 * task 6 writes it -- and an import of a name a module does not export is a compile error, which
 * would stop the whole suite from running instead of turning these tests red. The lookup is
 * deliberate and it fails loudly, by name, saying what is missing: that is the red of "no
 * implementation yet", and it is told apart from a typo by the message. When task 6 lands, the
 * cast can become a plain import.
 */

import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { fetchMe, login } from '../src/api/auth';
import * as client from '../src/api/client';

const AN_INNER_PATH = '/favorites';
const LOGIN_URL = '/api/auth/login';
const ME_URL = '/api/auth/me';

const SESSION_TOKEN = 'el.token.de.la.sesion';
const EXPLICIT_TOKEN = 'el.token.explicito';

/** Where the token of a call comes from when the call does not name one. */
type TokenProvider = () => string | null;

/** The shape task 6 adds to `api/client.ts`, as this suite needs to see it (`plan.md`). */
interface ClientWithTokenProvider {
  setAuthTokenProvider?: (provider: TokenProvider | null) => void;
}

/** Register where the token comes from, failing by name while that door does not exist yet. */
function registerTokenProvider(provider: TokenProvider | null): void {
  const { setAuthTokenProvider } = client as unknown as ClientWithTokenProvider;

  if (!setAuthTokenProvider) {
    throw new Error(
      'src/api/client.ts does not export setAuthTokenProvider yet: the session has no way to say ' +
        'where the token comes from (plan.md -> Contratos -> Frontend, tasks.md task 6)',
    );
  }

  setAuthTokenProvider(provider);
}

/** Forget it again, without failing when it was never there: this runs after every test. */
function forgetTokenProvider(): void {
  const { setAuthTokenProvider } = client as unknown as ClientWithTokenProvider;

  setAuthTokenProvider?.(null);
}

/** The headers of a fetch call, as a lookup, whichever shape they were given in. */
function headersOf(init: RequestInit | undefined): Headers {
  return new Headers(init?.headers);
}

/** The URL of a fetch call, whichever of the three shapes it was made with. */
function urlOf(input: RequestInfo | URL): string {
  if (typeof input === 'string') return input;
  if (input instanceof URL) return input.href;

  return input.url;
}

/** What the one call of a test went out with. */
function theCallTo(path: string): RequestInit | undefined {
  const call = vi.mocked(fetch).mock.calls.find(([input]) => urlOf(input).includes(path));

  if (!call) throw new Error(`nothing was requested from "${path}"`);

  return call[1];
}

/** The `Authorization` header of the call to a path, or `null` when none went out. */
function authorizationOf(path: string): string | null {
  return headersOf(theCallTo(path)).get('Authorization');
}

beforeEach(() => {
  vi.stubGlobal(
    'fetch',
    // A new `Response` per call: a body can only be read once, and sharing one would make the
    // second call of a test fail for a reason that has nothing to do with headers.
    vi.fn().mockImplementation(() => Promise.resolve(new Response('{}', { status: 200 }))),
  );
});

afterEach(() => {
  forgetTokenProvider();
  vi.unstubAllGlobals();
});

describe('a call that names no token, with a session registered', () => {
  it('goes out with the token the session provides', async () => {
    // The five routes of `002` are made from an inner screen, and who is calling is known by the
    // session and not by the screen. This is what spares every one of them from threading it.
    registerTokenProvider(() => SESSION_TOKEN);

    await client.request(AN_INNER_PATH);

    expect(authorizationOf(AN_INNER_PATH)).toBe(`Bearer ${SESSION_TOKEN}`);
  });
});

describe('a call that names its own token, with a session registered', () => {
  it('goes out with the one it named, and not with the session one', async () => {
    // The explicit one wins. This is `fetchMe` during the restoration: the call that asks whether
    // the kept token is still any good, made *before* there is a session to ask.
    registerTokenProvider(() => SESSION_TOKEN);

    await fetchMe(EXPLICIT_TOKEN);

    expect(authorizationOf(ME_URL)).toBe(`Bearer ${EXPLICIT_TOKEN}`);
  });
});

describe('a call that declares it carries no credential', () => {
  it('goes out with no header even while a session is registered', async () => {
    // `login()` is the call that exists precisely for when there is no session yet. Declaring it
    // is what keeps that from depending on there happening to be no provider at that moment.
    registerTokenProvider(() => SESSION_TOKEN);

    await login('juan', 'una-clave-de-demo');

    expect(authorizationOf(LOGIN_URL)).toBeNull();
  });

  it('goes out with no header when no session was ever registered', async () => {
    await client.request(AN_INNER_PATH);

    expect(authorizationOf(AN_INNER_PATH)).toBeNull();
  });

  it('goes out with no header when the session has no token to give', async () => {
    // A registered provider that answers `null` is the application between logging out and
    // logging back in: registered, and with nothing to present.
    registerTokenProvider(() => null);

    await client.request(AN_INNER_PATH);

    expect(authorizationOf(AN_INNER_PATH)).toBeNull();
  });
});

describe('the calls 001 already shipped', () => {
  it('still send their own token, with nothing registered', async () => {
    // The regression guard of this task: the restoration works today, and adding the provider is
    // not allowed to change what it sends.
    await fetchMe(EXPLICIT_TOKEN);

    expect(authorizationOf(ME_URL)).toBe(`Bearer ${EXPLICIT_TOKEN}`);
  });

  it('still keep the credential out of the address', async () => {
    // Article III on this side: the identity travels in the header, never as a parameter, because
    // a token in a query string ends up in every access log on the way.
    await fetchMe(EXPLICIT_TOKEN);

    const call = vi.mocked(fetch).mock.calls.find(([input]) => urlOf(input).includes(ME_URL));

    expect(urlOf(call?.[0] ?? '')).not.toContain(EXPLICIT_TOKEN);
  });
});

/**
 * The other half of what `002` asks of the client: the status has to be readable.
 *
 * The addition distinguishes **201** (the row was created) from **200** (the action was already
 * there), with the same body in both cases, and `Esa acción ya está en tu lista.` comes out of the
 * 200 (`plan.md` → *Contratos* → `POST /api/favorites`). `request()` parses the JSON and throws the
 * status away, so a second function is added and the existing one is not changed:
 *
 * ```ts
 * export async function send<T>(path, options): Promise<{ status: number; data: T }>
 * export async function request<T>(path, options): Promise<T>   // = (await send<T>(...)).data
 * ```
 *
 * Making `request()` return the pair instead would touch every call site of `001` for one case, so
 * the last two tests below are the guard on that: the bare JSON and the `ApiError` are exactly
 * what they were.
 *
 * `send` goes through the same cast as `registerTokenProvider` above, and for the same reason: it
 * does not exist yet -- task 13 writes it -- and importing a name a module does not export is a
 * compile error, which would stop the suite from running instead of turning these red.
 */

/** One favourite, as `POST /api/favorites` answers it with either status. */
const A_FAVORITE = { symbol: 'MSFT', name: 'Microsoft Corp', currency: 'USD' };

/** What a call can declare, as much of it as these tests need to name. */
interface SendOptions {
  method?: 'GET' | 'POST' | 'DELETE';
  body?: unknown;
  token?: string | null;
}

/** What the caller gets back once the status is no longer thrown away. */
interface Answer<T> {
  status: number;
  data: T;
}

/** The shape task 13 adds to `api/client.ts`, as this suite needs to see it (`plan.md`). */
interface ClientWithSend {
  send?: <T>(path: string, options?: SendOptions) => Promise<Answer<T>>;
}

/** Call `send()`, failing by name while that function does not exist yet. */
async function send<T>(path: string, options?: SendOptions): Promise<Answer<T>> {
  const { send: sendOfTheClient } = client as unknown as ClientWithSend;

  if (!sendOfTheClient) {
    throw new Error(
      'src/api/client.ts does not export send yet: the addition cannot tell a 201 from a 200, ' +
        'which is what RF-19 hangs on (plan.md -> Contratos -> Frontend, tasks.md task 13)',
    );
  }

  return await sendOfTheClient<T>(path, options);
}

/** Answer every call of a test with one payload and one status. */
function answerWith(payload: unknown, status: number): void {
  vi.stubGlobal(
    'fetch',
    vi
      .fn()
      .mockImplementation(() => Promise.resolve(new Response(JSON.stringify(payload), { status }))),
  );
}

/** Answer every call of a test with a status and no body at all, the way a 204 travels. */
function answerWithNoBody(status: number): void {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockImplementation(() => Promise.resolve(new Response(null, { status }))),
  );
}

describe('a call made with send()', () => {
  it('hands back the status the API answered with, and the body', async () => {
    // 201 is "the row was created", and it is what the screen reads to know the addition was new.
    answerWith(A_FAVORITE, 201);

    const answer = await send<typeof A_FAVORITE>(AN_INNER_PATH, {
      method: 'POST',
      body: { symbol: A_FAVORITE.symbol },
    });

    expect(answer.status).toBe(201);
    expect(answer.data).toEqual(A_FAVORITE);
  });

  it('tells a 200 from a 201 that carries the same body', async () => {
    // The whole point: the two answers of `POST /api/favorites` are identical except for the
    // status, and `Esa acción ya está en tu lista.` is what the 200 means. A client that hid the
    // status would leave the screen unable to tell them apart.
    answerWith(A_FAVORITE, 200);

    const answer = await send<typeof A_FAVORITE>(AN_INNER_PATH, {
      method: 'POST',
      body: { symbol: A_FAVORITE.symbol },
    });

    expect(answer.status).toBe(200);
    expect(answer.data).toEqual(A_FAVORITE);
  });

  it('carries the session token like every other call of an inner screen', async () => {
    // `send()` is not a side door: the rule of precedence above is the client's, not `request()`'s.
    answerWith(A_FAVORITE, 201);
    registerTokenProvider(() => SESSION_TOKEN);

    await send<typeof A_FAVORITE>(AN_INNER_PATH, { method: 'POST', body: {} });

    expect(authorizationOf(AN_INNER_PATH)).toBe(`Bearer ${SESSION_TOKEN}`);
  });
});

/**
 * The answer with no body at all, which is the one `002` adds and the one that throws.
 *
 * `DELETE /api/favorites/{symbol}` answers **204** and nothing else (`plan.md` -> *Contratos*):
 * there is no body to read, and `await response.json()` on it rejects with a syntax error. That
 * happens in the **happy path** -- the removal that worked -- so a client that parses
 * unconditionally turns every successful delete into a failure on screen, which is the worst
 * possible place for this to be discovered.
 *
 * So the status comes back like any other and the data is `undefined`: nothing to read, and
 * nothing pretending there is.
 */
describe('an answer that carries no body', () => {
  it('does not throw while trying to parse one', async () => {
    // A 204 is what the removal answers when it worked. If this throws, `Eliminar` reports an
    // error for the one outcome the person asked for.
    answerWithNoBody(204);

    await expect(send(`${AN_INNER_PATH}/NFLX`, { method: 'DELETE' })).resolves.toBeDefined();
  });

  it('hands back the status, with nothing where the body would be', async () => {
    // 204 means "done, and there is nothing to tell you". `undefined` is that, said in TypeScript;
    // an empty object would be a body the API never sent.
    answerWithNoBody(204);

    const answer = await send(`${AN_INNER_PATH}/NFLX`, { method: 'DELETE' });

    expect(answer.status).toBe(204);
    expect(answer.data).toBeUndefined();
  });

  it('carries the session token like every other call of an inner screen', async () => {
    // The removal is made from `Mis Acciones`, so who is asking is known by the session. Without
    // the header the API would answer 401 and the interceptor would send the person to the login.
    answerWithNoBody(204);
    registerTokenProvider(() => SESSION_TOKEN);

    await send(`${AN_INNER_PATH}/NFLX`, { method: 'DELETE' });

    expect(authorizationOf(AN_INNER_PATH)).toBe(`Bearer ${SESSION_TOKEN}`);
  });

  it('reaches the address of the symbol with the method of a removal', async () => {
    // The other half of the same call: `DELETE`, and the symbol in the path. A client that knew
    // only GET and POST would send this as a GET and remove nothing, silently.
    answerWithNoBody(204);

    await send(`${AN_INNER_PATH}/NFLX`, { method: 'DELETE' });

    const call = vi
      .mocked(fetch)
      .mock.calls.find(([input]) => urlOf(input).includes(`${AN_INNER_PATH}/NFLX`));

    expect(call?.[1]?.method).toBe('DELETE');
  });
});

describe('request(), once it is a wrapper over send()', () => {
  it('still hands back the bare JSON and not a pair', async () => {
    // The guard on the five call sites `001` already shipped: `request()` keeps its shape, so not
    // one of them changes because the addition needed the status.
    answerWith(A_FAVORITE, 200);

    expect(await client.request(AN_INNER_PATH)).toEqual(A_FAVORITE);
  });

  it('still throws an ApiError carrying the status when the API refuses', async () => {
    // The other half of "nothing of `001` changes shape": a refusal is still an exception with the
    // status on it, and not a pair somebody has to remember to look at.
    answerWith({ detail: 'unknown symbol' }, 404);

    await expect(client.request(AN_INNER_PATH)).rejects.toMatchObject({
      name: 'ApiError',
      status: 404,
    });
  });
});
