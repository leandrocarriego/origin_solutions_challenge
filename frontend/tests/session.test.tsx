/**
 * The session as a capacity: the guard (RF-09), and that it survives a reload (RF-07, RF-17).
 *
 * RF-09 is written as an address pasted into a browser, so it is tested as one: the application is
 * rendered at `/` with nothing stored, and what has to be on screen is the login. Like
 * `Login.test.tsx`, this fixes that the `Router` wraps `<App />` from `main.tsx` rather than living
 * inside `App` -- without that, there is no way to open a URL in a test.
 *
 * The trap the guard exists for is one that renders the inner screen first and redirects
 * afterwards: the grid of somebody's favourites flashes on screen for a frame, which is the leak
 * the guard was put there to prevent.
 *
 * **H2 adds the reload, and it is simulated by logging in and mounting the application again.**
 * Not by writing into `sessionStorage` by hand: the shape of what is stored is the implementation's
 * business (`plan.md` names the file, not its keys), and a test that wrote those keys would be
 * asserting a private detail and would go red the day it changes without anything changing for
 * anybody. Signing in first and then remounting is what a person does with F5, and it holds
 * whatever the storage ends up looking like.
 *
 * Three things have to be true after that remount, and each is a different way of getting it wrong:
 *
 * - The visitor is still inside, and the name is still painted (RF-07). The credential is never
 *   asked for again.
 * - A session the API no longer accepts lands on the login **with its notice** (RF-17). Dropping
 *   the visitor there in silence looks like a bug in the application.
 * - While `/api/auth/me` is still unanswered, the login is not on screen (the `loading` state of
 *   the plan). Without it the reload flashes the login for a frame and then leaves it, which reads
 *   as having been logged out and back in.
 *
 * **H3 adds the way out, and it is the same simulation read backwards** (RF-19, RF-20): log in,
 * activate `Cerrar sesión`, and then mount the application again at the address of the inner
 * screen. The second mount is the half that matters -- ending a session in the React tree is easy
 * and is not the requirement; what has to be true is that nothing was left behind for the next page
 * to restore, because a session still kept in the browser is the one that comes back with F5.
 *
 * Two ways of getting it right that would still be wrong, and each has its test: arriving at the
 * login with `Tu sesión expiró. Volvé a ingresar.` on it -- the session did not expire, it was
 * closed on purpose, and the four notices of the login are exclusive (`COPY.md`) -- and getting
 * there through the 401 interceptor, which is the correction for a session the API refused and not
 * for one the visitor ended.
 */

import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { App } from '../src/App';

const INGRESAR = 'Ingresar';
const USUARIO = 'Usuario';
const CLAVE = 'Clave';
const MIS_ACCIONES = 'Mis Acciones';
// Verbatim from the session table of docs/design/COPY.md (UI-02).
const SESION_EXPIRADA = 'Tu sesión expiró. Volvé a ingresar.';

const LOGIN_URL = '/api/auth/login';
const FAVORITES_URL = '/api/favorites';
const ME_URL = '/api/auth/me';
const A_PASSWORD = 'una-clave-de-demo';

/** What the API answers a good credential with, and the name the header then shows. */
const A_SESSION = {
  access_token: 'a.signed.token',
  token_type: 'bearer',
  expires_in: 3600,
  full_name: 'Juan Perez',
};

/** What `GET /api/auth/me` answers while the token is still good. */
const WHO_IT_IS = { id: 1, full_name: 'Juan Perez' };

/** The URL of a fetch call, whichever of the three shapes it was made with. */
function urlOf(input: RequestInfo | URL): string {
  if (typeof input === 'string') return input;
  if (input instanceof URL) return input.href;

  return input.url;
}

/** The headers of a fetch call, as a plain lookup, whichever shape they were given in. */
function headersOf(init: RequestInit | undefined): Headers {
  return new Headers(init?.headers);
}

/** Every call made to one of our endpoints, in order. */
function callsTo(path: string): [RequestInfo | URL, RequestInit | undefined][] {
  return vi.mocked(fetch).mock.calls.filter(([input]) => urlOf(input).includes(path)) as [
    RequestInfo | URL,
    RequestInit | undefined,
  ][];
}

/**
 * Replace fetch: the login always succeeds, and `/me` answers whatever the test says.
 *
 * `/me` is the interesting half. It is the question the application asks on every start-up --
 * "is this stored token still any good?" -- and its three answers are the three states of the
 * reload: yes, no, and not yet.
 */
function stubTheApi(me: () => Promise<Response>): void {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockImplementation((input: RequestInfo | URL) => {
      if (urlOf(input).includes(LOGIN_URL)) {
        return Promise.resolve(new Response(JSON.stringify(A_SESSION), { status: 200 }));
      }
      if (urlOf(input).includes(ME_URL)) return me();
      // The inner screen asks for the grid the moment it mounts, and this suite is about the
      // session and not about the list. Answering it is what keeps a 401 the double invented
      // from ending the session these tests are looking at: `002` made that 401 mean exactly
      // that, deliberately, so the double has to know the route rather than the interceptor
      // having to stop caring.
      if (urlOf(input).includes(FAVORITES_URL)) {
        return Promise.resolve(new Response('[]', { status: 200 }));
      }

      return Promise.resolve(
        new Response(JSON.stringify({ detail: 'not authenticated' }), { status: 401 }),
      );
    }),
  );
}

/** `/me` recognises the session. */
function meAnswers(): Promise<Response> {
  return Promise.resolve(new Response(JSON.stringify(WHO_IT_IS), { status: 200 }));
}

/** `/me` no longer accepts the token: it expired, or it was signed with another secret. */
function meRefuses(): Promise<Response> {
  return Promise.resolve(
    new Response(JSON.stringify({ detail: 'not authenticated' }), { status: 401 }),
  );
}

/** `/me` has not answered yet, which is the state a slow connection leaves the start-up in. */
function meIsStillThinking(): Promise<Response> {
  return new Promise<Response>(() => {
    // Never settles on purpose: what is under test is what the screen shows meanwhile.
  });
}

/** Open the application at an address, the way pasting one in the browser does. */
function openAt(address: string): void {
  render(
    <MemoryRouter initialEntries={[address]}>
      <App />
    </MemoryRouter>,
  );
}

/** Log in the way a person does, and stop on the inner screen the credential opened. */
async function logInThroughTheScreen(): Promise<{ unmount: () => void }> {
  const mounted = render(
    <MemoryRouter initialEntries={['/login']}>
      <App />
    </MemoryRouter>,
  );

  const person = userEvent.setup();
  await person.type(screen.getByLabelText(USUARIO), 'juan');
  await person.type(screen.getByLabelText(CLAVE), A_PASSWORD);
  await person.click(screen.getByRole('button', { name: INGRESAR }));
  await screen.findByText(MIS_ACCIONES);

  return mounted;
}

/**
 * Log in through the screen and then throw that page away, which is what F5 does.
 *
 * The storage is the browser's and survives; the React tree does not. Whatever the login decided
 * to keep is all the next mount gets, and that is exactly the thing under test.
 */
async function logInAndReload(): Promise<void> {
  const first = await logInThroughTheScreen();

  first.unmount();
  openAt('/');
}

beforeEach(() => {
  sessionStorage.clear();
  // Nothing is stored, so nothing should be asked of the API. Stubbed anyway: a test that goes
  // to the network is not a test of the frontend, and the failure would be a timeout.
  vi.stubGlobal(
    'fetch',
    vi
      .fn()
      .mockResolvedValue(
        new Response(JSON.stringify({ detail: 'not authenticated' }), { status: 401 }),
      ),
  );
});

afterEach(() => {
  vi.unstubAllGlobals();
  sessionStorage.clear();
});

describe('an inner screen opened with no session', () => {
  it('leaves the visitor looking at the login', async () => {
    openAt('/');

    expect(await screen.findByRole('button', { name: INGRESAR })).toBeInTheDocument();
    expect(screen.getByLabelText(USUARIO)).toBeInTheDocument();
  });

  it('does not show the inner screen at all', async () => {
    openAt('/');

    await screen.findByRole('button', { name: INGRESAR });
    expect(screen.queryByText(MIS_ACCIONES)).toBeNull();
  });
});

describe('a session that is still good, after a reload', () => {
  it('leaves the visitor where they were, without asking for the credential again', async () => {
    // RF-07: navigating -- and reloading is navigating -- does not ask for a user or a password.
    stubTheApi(meAnswers);

    await logInAndReload();

    expect(await screen.findByText(MIS_ACCIONES)).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: INGRESAR })).toBeNull();
  });

  it('asks our own API whether the stored token is still good', async () => {
    // The client cannot decide this on its own: the token is signed, and only the API can say.
    stubTheApi(meAnswers);

    await logInAndReload();

    await screen.findByText(MIS_ACCIONES);
    expect(callsTo(ME_URL).length).toBeGreaterThan(0);
  });

  it('asks it with the token it was given, and not anonymously', async () => {
    // Article III on this side: the identity travels in the credential, never as a parameter.
    stubTheApi(meAnswers);

    await logInAndReload();

    await screen.findByText(MIS_ACCIONES);
    const [input, init] = callsTo(ME_URL)[0] ?? [];
    expect(headersOf(init).get('Authorization')).toBe(`Bearer ${A_SESSION.access_token}`);
    expect(urlOf(input ?? '')).not.toContain(A_SESSION.access_token);
  });
});

describe('a session the API no longer accepts, after a reload', () => {
  it('leaves the visitor on the login screen', async () => {
    stubTheApi(meRefuses);

    await logInAndReload();

    expect(await screen.findByRole('button', { name: INGRESAR })).toBeInTheDocument();
    expect(screen.queryByText(MIS_ACCIONES)).toBeNull();
    // And it got there by asking: a login screen shown because nothing was ever stored is the
    // same picture for a different reason, and would pass this test without the feature existing.
    expect(callsTo(ME_URL).length).toBeGreaterThan(0);
  });

  it('says why they are there, word for word', async () => {
    // RF-17. Landing on the login in silence reads as the application having lost the session by
    // mistake; the notice is what turns it into something that was supposed to happen.
    stubTheApi(meRefuses);

    await logInAndReload();

    expect(await screen.findByText(SESION_EXPIRADA)).toBeInTheDocument();
  });

  it('does not blame the credential that was typed', async () => {
    // The four notices of the login are exclusive (COPY.md): nothing was typed this time.
    stubTheApi(meRefuses);

    await logInAndReload();

    await screen.findByText(SESION_EXPIRADA);
    expect(screen.queryByText('usuario o clave invalida')).toBeNull();
  });
});

describe('a reload whose answer has not arrived yet', () => {
  it('does not flash the login screen while it waits', async () => {
    // The `loading` state of the plan, and the only reason it exists. Asserted on the first
    // render and not after an await: a frame of the login is exactly the bug.
    stubTheApi(meIsStillThinking);

    await logInAndReload();

    expect(screen.queryByRole('button', { name: INGRESAR })).toBeNull();
    expect(screen.queryByText(SESION_EXPIRADA)).toBeNull();
  });

  it('has asked, which is what makes the wait a wait and not a blank screen', async () => {
    stubTheApi(meIsStillThinking);

    await logInAndReload();

    expect(callsTo(ME_URL).length).toBeGreaterThan(0);
  });
});

/*
 * H3 -- closing the session (RF-19, RF-20).
 *
 * The control is looked up as a button or as a link, and not by its text alone: `Cerrar sesión` is
 * an action, and an action a person can activate has to be reachable as one. A `<span onClick>`
 * fails these tests on purpose, and it fails them for a real reason -- nothing that is not a button
 * or a link is reachable by keyboard or announced as activatable. `COPY.md` fixes the text and
 * `plan.md` fixes the file and `logOut()`; neither fixes which of the two elements it is, so either
 * passes.
 */

// Verbatim from the session table of docs/design/COPY.md (UI-02).
const CERRAR_SESION = 'Cerrar sesión';

/** The control that ends the session, however the header chose to draw it. */
function theWayOut(): HTMLElement {
  const [control] = [
    ...screen.queryAllByRole('button', { name: CERRAR_SESION }),
    ...screen.queryAllByRole('link', { name: CERRAR_SESION }),
  ];

  if (!control) {
    throw new Error(`the header offers no button or link named "${CERRAR_SESION}"`);
  }

  return control;
}

/** Activate it, the way a person leaving a shared computer does. */
async function closeTheSession(): Promise<void> {
  await userEvent.setup().click(theWayOut());
}

describe('a session closed on purpose', () => {
  it('leaves the visitor looking at the login screen', async () => {
    // RF-20. The screen that comes up is the one they would need to come back in through.
    stubTheApi(meAnswers);

    await logInThroughTheScreen();
    await closeTheSession();

    expect(await screen.findByRole('button', { name: INGRESAR })).toBeInTheDocument();
    expect(screen.queryByText(MIS_ACCIONES)).toBeNull();
  });

  it('does not say the session expired, because it did not', async () => {
    // It was closed on purpose, an hour was not what ended it, and the notice would send the
    // visitor looking for a problem that does not exist. The four notices are exclusive.
    stubTheApi(meAnswers);

    await logInThroughTheScreen();
    await closeTheSession();

    await screen.findByRole('button', { name: INGRESAR });
    expect(screen.queryByText(SESION_EXPIRADA)).toBeNull();
  });

  it('asks the server nothing, because there is nothing there to close', async () => {
    // ADR-004: the token is signed and short-lived, and there is no revocation on the server.
    // Leaving is the client forgetting it, so a round trip here would be a call to an endpoint
    // this feature never agreed to build -- and one whose failure could strand the visitor inside.
    stubTheApi(meAnswers);

    await logInThroughTheScreen();
    const asked = vi.mocked(fetch).mock.calls.length;
    await closeTheSession();

    await screen.findByRole('button', { name: INGRESAR });
    expect(vi.mocked(fetch).mock.calls.length).toBe(asked);
  });
});

describe('the address of the inner screen, after closing the session', () => {
  it('shows the login and not the screen that was there before', async () => {
    // RF-19, written as it reads in the spec: going back to the address of `Mis Acciones` has to
    // leave the login on screen. The remount is what makes it that address and not this page.
    stubTheApi(meAnswers);

    const inside = await logInThroughTheScreen();
    await closeTheSession();
    await screen.findByRole('button', { name: INGRESAR });

    inside.unmount();
    openAt('/');

    expect(await screen.findByRole('button', { name: INGRESAR })).toBeInTheDocument();
    expect(screen.queryByText(MIS_ACCIONES)).toBeNull();
  });

  it('finds nothing kept for that page to restore', async () => {
    // The session that survives a reload is the one in the browser's storage, and the application
    // proves it kept one by asking `/api/auth/me` about it at start-up. A start-up that asks
    // nothing is a storage with nothing in it -- which is the same thing the test above shows,
    // checked where it is actually decided instead of where it shows.
    stubTheApi(meAnswers);

    const inside = await logInThroughTheScreen();
    await closeTheSession();
    await screen.findByRole('button', { name: INGRESAR });
    const askedBefore = callsTo(ME_URL).length;

    inside.unmount();
    openAt('/');

    await screen.findByRole('button', { name: INGRESAR });
    expect(callsTo(ME_URL).length).toBe(askedBefore);
  });
});

/**
 * `003` adds the third address the guard has to hold: the Detail of an action (RF-02).
 *
 * It is the same guard read at another door, and that is why it is here and not in
 * `ActionDetail.test.tsx` -- `tasks.md` puts RF-02 in this file on purpose: what is being fixed is
 * the capacity, and a screen-by-screen copy of it would go stale the day a fourth address appears.
 *
 * It is green today -- with no route behind `/stocks/:symbol` the address already falls through to
 * the guard -- so what it buys is that it stays true the day the Detail becomes a screen of its
 * own. A guard that stopped covering an address is exactly the kind of regression nobody notices.
 */
describe('the address of the detail of an action, opened with no session', () => {
  /** The button of the Detail (`COPY.md` → *Detalle de Acción*), which must not be reachable. */
  const GRAFICAR = 'Graficar';

  it('leaves the visitor looking at the login', async () => {
    openAt('/stocks/TSLA');

    expect(await screen.findByRole('button', { name: INGRESAR })).toBeInTheDocument();
    expect(screen.getByLabelText(USUARIO)).toBeInTheDocument();
  });

  it('does not show the detail at all', async () => {
    openAt('/stocks/TSLA');

    await screen.findByRole('button', { name: INGRESAR });
    expect(screen.queryByRole('button', { name: GRAFICAR })).toBeNull();
  });
});

/**
 * The regression of the session that ended one frame after it began.
 *
 * In production, logging in showed `Mis Acciones` for an instant and came straight back to the
 * login with `Tu sesión expiró. Volvé a ingresar.` on it. Nothing had expired: the first call the
 * inner screen makes -- `GET /api/favorites`, the moment it mounts -- went out with **no**
 * `Authorization` header, our API answered 401, and the interceptor did what a 401 means and ended
 * the session.
 *
 * What made it possible is that the provider registers the token of every call from an effect. An
 * effect that depended on `navigate` -- whose identity changes on every navigation -- was torn down
 * and set up again on the very commit that navigates, and React runs the cleanups of the whole tree
 * before the effects, children first: the screen asked for its grid in the gap, with nothing
 * registered to hand it a credential.
 *
 * The test is written on the header and not on the screen on purpose. Asserting "the visitor stays
 * inside" would go green again the day the interceptor stops reacting to a 401, which would be a
 * different bug wearing this one's clothes. The header is the thing that was missing.
 */
describe('the first call an inner screen makes after logging in', () => {
  it('carries the session that was just handed out', async () => {
    stubTheApi(meAnswers);

    await logInThroughTheScreen();

    const [, init] = callsTo(FAVORITES_URL)[0] ?? [];
    expect(headersOf(init).get('Authorization')).toBe(`Bearer ${A_SESSION.access_token}`);
  });
});
