/**
 * The login screen (RF-01 to RF-05, RF-12, RF-13, RF-23).
 *
 * The screen is reached through its own route, by rendering the application at `/login`, and not
 * by rendering `Login` on its own. It needs the router (it navigates on success) and the session
 * (it stores what the login answered), and both are wired by the application: a test that
 * assembled them by hand would be fixing a shape the plan does not fix, and would break the day
 * the wiring changes without the screen changing for anybody.
 *
 * That does fix one thing, and it is deliberate: **the `Router` lives in `main.tsx`, around
 * `<App />`, and not inside `App`.** Otherwise this file cannot open the screen at a chosen URL,
 * and RF-09 -- "paste the address of Mis Acciones in a browser" -- is not verifiable at all.
 *
 * Three of these tests are about what the user is *not* told:
 *
 * - An empty field never reaches the API (RF-13), so the credential is not what is wrong.
 * - The three notices are exclusive and ordered: empty field, then the attempt limit, then the
 *   credential (`COPY.md` says so explicitly). Two at once is a bug, not a detail.
 * - Neither the 401 nor the 429 of the login is a session that expired, so neither may trigger
 *   the interceptor. If it did, the screen would reload itself instead of saying what happened,
 *   and RF-04 would look like a server fault.
 */

import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { App } from '../src/App';

// Verbatim from docs/design/COPY.md, misspellings included (UI-02).
const USUARIO = 'Usuario';
const PLACEHOLDER_USUARIO = 'Ingresar nombre de usuario';
const CLAVE = 'Clave';
const INGRESAR = 'Ingresar';
const CREDENCIAL_INVALIDA = 'usuario o clave invalida';
const CAMPO_VACIO = 'Completá este campo.';
const DEMASIADOS_INTENTOS = 'Demasiados intentos. Probá de nuevo en unos minutos.';
const SESION_EXPIRADA = 'Tu sesión expiró. Volvé a ingresar.';
const NO_HAY_CONEXION = 'No pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.';
const MIS_ACCIONES = 'Mis Acciones';

const FAVORITES_URL = '/api/favorites';
const LOGIN_URL = '/api/auth/login';
const A_PASSWORD = 'una-clave-de-demo';

/** What the API answers when the credential is good. */
const A_SESSION = {
  access_token: 'a.signed.token',
  token_type: 'bearer',
  expires_in: 3600,
  full_name: 'Juan Perez',
};

/** The URL of a fetch call, whichever of the three shapes it was made with. */
function urlOf(input: RequestInfo | URL): string {
  if (typeof input === 'string') return input;
  if (input instanceof URL) return input.href;

  return input.url;
}

/**
 * Replace fetch: the login answers with this status and body, anything else answers 401.
 *
 * The 401 by default is not laziness -- it is the shape of a browser with no session, which is
 * the state the login screen is opened in.
 */
function stubTheApi(status: number, body: unknown = {}): void {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockImplementation((input: RequestInfo | URL) => {
      if (urlOf(input).includes(LOGIN_URL)) {
        return Promise.resolve(new Response(JSON.stringify(body), { status }));
      }
      // The screen a good credential opens asks for the grid the moment it mounts, and this
      // suite is about the login and not about the list. Leaving it to the 401 below would race
      // the assertion against the session interceptor -- `002` made that 401 mean "the session
      // ended", deliberately -- and a race is a suite that passes most of the time.
      if (urlOf(input).includes(FAVORITES_URL)) {
        return Promise.resolve(new Response('[]', { status: 200 }));
      }

      return Promise.resolve(
        new Response(JSON.stringify({ detail: 'not authenticated' }), { status: 401 }),
      );
    }),
  );
}

/**
 * Replace fetch with one that never gets an answer: the request does not fail, it does not happen.
 *
 * `TypeError: Failed to fetch` is what a browser rejects with when it cannot reach the host at all
 * -- the connection is down, the server is not listening, DNS does not resolve. It is not a status
 * code, which is exactly why RF-27 exists: there is no response to read, so a screen that only
 * knows how to react to statuses falls back to its default notice and blames the credential.
 */
function stubAServerThatCannotBeReached(): void {
  vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new TypeError('Failed to fetch')));
}

/** Every call the screen made to the login endpoint. */
function loginCalls(): [RequestInfo | URL, RequestInit | undefined][] {
  return vi.mocked(fetch).mock.calls.filter(([input]) => urlOf(input).includes(LOGIN_URL)) as [
    RequestInfo | URL,
    RequestInit | undefined,
  ][];
}

/** Open the application on the login screen, the way a visitor arrives at it. */
function openTheLoginScreen(): void {
  render(
    <MemoryRouter initialEntries={['/login']}>
      <App />
    </MemoryRouter>,
  );
}

/** Fill the form with whatever was given and press the button. */
async function tryToLogIn(username: string, password: string): Promise<void> {
  const person = userEvent.setup();

  if (username) await person.type(screen.getByLabelText(USUARIO), username);
  if (password) await person.type(screen.getByLabelText(CLAVE), password);
  await person.click(screen.getByRole('button', { name: INGRESAR }));
}

beforeEach(() => {
  sessionStorage.clear();
  stubTheApi(200, A_SESSION);
});

afterEach(() => {
  vi.unstubAllGlobals();
  sessionStorage.clear();
});

describe('the login screen as the wireframe draws it', () => {
  it('asks for a user and a password, and nothing else', () => {
    openTheLoginScreen();

    expect(screen.getByLabelText(USUARIO)).toBeInTheDocument();
    expect(screen.getByLabelText(CLAVE)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: INGRESAR })).toBeInTheDocument();
  });

  it('shows the hint the brief wrote in the user field', () => {
    openTheLoginScreen();

    expect(screen.getByPlaceholderText(PLACEHOLDER_USUARIO)).toBeInTheDocument();
  });

  it('adds no page title and no logo', () => {
    // UI-01: wireframe 01 has neither, so neither is added.
    openTheLoginScreen();

    expect(screen.queryByRole('heading')).toBeNull();
  });

  it('masks the password while it is typed', () => {
    openTheLoginScreen();

    expect(screen.getByLabelText(CLAVE)).toHaveAttribute('type', 'password');
  });

  it('says nothing about a credential before anything was tried', () => {
    openTheLoginScreen();

    expect(screen.queryByText(CREDENCIAL_INVALIDA)).toBeNull();
    expect(screen.queryByText(CAMPO_VACIO)).toBeNull();
    expect(screen.queryByText(DEMASIADOS_INTENTOS)).toBeNull();
  });
});

describe('the login screen with a credential that works', () => {
  it('leaves the visitor looking at Mis Acciones', async () => {
    openTheLoginScreen();

    await tryToLogIn('juan', A_PASSWORD);

    expect(await screen.findByText(MIS_ACCIONES)).toBeInTheDocument();
  });

  it('asks our own API, and asks it once', async () => {
    // Article I: the browser never learns the provider's domain, and never spends quota.
    openTheLoginScreen();

    await tryToLogIn('juan', A_PASSWORD);

    await waitFor(() => expect(loginCalls()).toHaveLength(1));
    const [input, init] = loginCalls()[0] ?? [];
    expect(urlOf(input ?? '')).toBe(LOGIN_URL);
    expect(init?.method).toBe('POST');
  });

  it('sends what was typed in the body and never in the address', async () => {
    // A password in a query string ends up in every access log on the way (RF-11).
    openTheLoginScreen();

    await tryToLogIn('juan', A_PASSWORD);

    await waitFor(() => expect(loginCalls()).toHaveLength(1));
    const [input, init] = loginCalls()[0] ?? [];
    const body = typeof init?.body === 'string' ? init.body : '';
    expect(urlOf(input ?? '')).not.toContain(A_PASSWORD);
    expect(body).toContain(A_PASSWORD);
    expect(body).toContain('juan');
  });
});

describe('the login screen with a credential that does not work', () => {
  it('shows the message of the brief, word for word', async () => {
    stubTheApi(401, { detail: 'invalid credentials' });
    openTheLoginScreen();

    await tryToLogIn('juan', 'otra-clave');

    expect(await screen.findByText(CREDENCIAL_INVALIDA)).toBeInTheDocument();
  });

  it('leaves the visitor on the login screen', async () => {
    stubTheApi(401, { detail: 'invalid credentials' });
    openTheLoginScreen();

    await tryToLogIn('juan', 'otra-clave');

    await screen.findByText(CREDENCIAL_INVALIDA);
    expect(screen.getByRole('button', { name: INGRESAR })).toBeInTheDocument();
    expect(screen.queryByText(MIS_ACCIONES)).toBeNull();
  });

  it('does not read the refusal as a session that expired', async () => {
    // The 401 of the login means "that credential is wrong". If the session interceptor caught
    // it, the screen would announce an expiry that never happened.
    stubTheApi(401, { detail: 'invalid credentials' });
    openTheLoginScreen();

    await tryToLogIn('juan', 'otra-clave');

    await screen.findByText(CREDENCIAL_INVALIDA);
    expect(screen.queryByText(SESION_EXPIRADA)).toBeNull();
  });

  it('does not say the server could not be reached, because it answered', async () => {
    // The other direction of RF-27's exclusivity: the API said no, and saying "we could not ask"
    // would send the visitor to check a connection that is working.
    stubTheApi(401, { detail: 'invalid credentials' });
    openTheLoginScreen();

    await tryToLogIn('juan', 'otra-clave');

    await screen.findByText(CREDENCIAL_INVALIDA);
    expect(screen.queryByText(NO_HAY_CONEXION)).toBeNull();
  });
});

describe('the login screen when the server cannot be reached at all', () => {
  it('says so with the words of the copy, and does not blame the credential', async () => {
    // RF-27. There is no response to read, so nothing is known about the credential: it was
    // never checked. Blaming it sends the visitor to change a password that was right.
    stubAServerThatCannotBeReached();
    openTheLoginScreen();

    await tryToLogIn('juan', A_PASSWORD);

    expect(await screen.findByText(NO_HAY_CONEXION)).toBeInTheDocument();
    expect(screen.queryByText(CREDENCIAL_INVALIDA)).toBeNull();
  });

  it('shows that notice and no other, because the four are exclusive', async () => {
    // `COPY.md` is explicit: the four notices of the login never appear together, and the order
    // is empty field, then the limit, then this one, then the credential.
    stubAServerThatCannotBeReached();
    openTheLoginScreen();

    await tryToLogIn('juan', A_PASSWORD);

    await screen.findByText(NO_HAY_CONEXION);
    expect(screen.getAllByRole('alert')).toHaveLength(1);
    expect(screen.queryByText(DEMASIADOS_INTENTOS)).toBeNull();
    expect(screen.queryByText(CAMPO_VACIO)).toBeNull();
  });

  it('keeps the visitor on the login screen, with the form still usable', async () => {
    // Nothing was decided about the session, so there is nowhere to go: the visitor retries here.
    stubAServerThatCannotBeReached();
    openTheLoginScreen();

    await tryToLogIn('juan', A_PASSWORD);

    await screen.findByText(NO_HAY_CONEXION);
    expect(screen.getByRole('button', { name: INGRESAR })).toBeEnabled();
    expect(screen.queryByText(MIS_ACCIONES)).toBeNull();
  });

  it('does not read the failure as a session that expired either', async () => {
    // Nobody had a session: the visitor is trying to get one.
    stubAServerThatCannotBeReached();
    openTheLoginScreen();

    await tryToLogIn('juan', A_PASSWORD);

    await screen.findByText(NO_HAY_CONEXION);
    expect(screen.queryByText(SESION_EXPIRADA)).toBeNull();
  });
});

describe('the login screen while the attempt limit holds', () => {
  it('says to wait, and does not say the credential was wrong', async () => {
    stubTheApi(429, { detail: 'too many attempts' });
    openTheLoginScreen();

    await tryToLogIn('juan', A_PASSWORD);

    expect(await screen.findByText(DEMASIADOS_INTENTOS)).toBeInTheDocument();
    expect(screen.queryByText(CREDENCIAL_INVALIDA)).toBeNull();
  });

  it('keeps the visitor on the login screen', async () => {
    stubTheApi(429, { detail: 'too many attempts' });
    openTheLoginScreen();

    await tryToLogIn('juan', A_PASSWORD);

    await screen.findByText(DEMASIADOS_INTENTOS);
    expect(screen.queryByText(MIS_ACCIONES)).toBeNull();
  });

  it('does not read the refusal as a session that expired either', async () => {
    stubTheApi(429, { detail: 'too many attempts' });
    openTheLoginScreen();

    await tryToLogIn('juan', A_PASSWORD);

    await screen.findByText(DEMASIADOS_INTENTOS);
    expect(screen.queryByText(SESION_EXPIRADA)).toBeNull();
  });
});

describe('the login screen with a field left empty', () => {
  it('marks both fields when both are empty', async () => {
    openTheLoginScreen();

    await tryToLogIn('', '');

    expect(await screen.findAllByText(CAMPO_VACIO)).toHaveLength(2);
  });

  it('marks only the field that is empty', async () => {
    openTheLoginScreen();

    await tryToLogIn('juan', '');

    expect(await screen.findAllByText(CAMPO_VACIO)).toHaveLength(1);
  });

  it('does not ask the API anything', async () => {
    // RF-13: a blank field is a slip, not a credential to check.
    openTheLoginScreen();

    await tryToLogIn('juan', '');

    await screen.findByText(CAMPO_VACIO);
    expect(loginCalls()).toHaveLength(0);
  });

  it('does not say the credential is wrong', async () => {
    // The two notices never show together: the copy is explicit about it.
    openTheLoginScreen();

    await tryToLogIn('', '');

    await screen.findAllByText(CAMPO_VACIO);
    expect(screen.queryByText(CREDENCIAL_INVALIDA)).toBeNull();
    expect(screen.queryByText(DEMASIADOS_INTENTOS)).toBeNull();
  });
});
