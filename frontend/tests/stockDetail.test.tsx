/**
 * H4 of `002`: getting from the grid to the detail of the right action.
 *
 * Three things, and nothing else: the symbol of each row behaves like a link and not like loose
 * text, activating `AAPL` lands on `/stocks/AAPL` and not on the detail of another row of
 * the list, and `/stocks/:symbol` opened with no session ends on the login, like `/`.
 *
 * **What the detail screen shows is not tested here, on purpose.** `plan.md` makes it a shell that
 * exists so the link has somewhere to arrive (`003` writes the real one), and it adds no text at all
 * to `COPY.md`. So what this file fixes is the arrival, which is what H4 promises.
 *
 * **The arrival is read as an address**, with a probe rendered next to the application inside the
 * same router. The address is what a person sees in the bar and what they can bookmark, and
 * `plan.md` → *`GET /stocks/:symbol`* fixes it as a contract: `/stocks/:symbol`, uppercase. Reading
 * the shell's content instead would tie this file to a screen that `003` replaces whole.
 *
 * **The link is activated, not inspected.** A test that read the `href` would pass on a link that
 * never navigates because something swallowed the click; and it is by clicking that a `<span
 * onClick>` fails the reading by role, which is the half that says "and not loose text".
 *
 * **The list has three rows and the one under test is the second.** What is asked is "that same action",
 * and the bug it guards against is a link that always leads to the first row, or to the symbol of
 * the row next to it. With one row in the grid neither of the two can be told from a pass.
 *
 * **The double answers every route this screen calls** -- `/api/auth/login`, `/api/auth/me`,
 * `GET /api/favorites` and `GET /api/stocks` -- and anything else with a 500 and never a 401. A
 * 401 invented by the double looks to the session interceptor exactly like an expired session, and
 * the test that says "this address ends on the login" would pass for the wrong reason, which is
 * the worst way to pass.
 *
 * Today all of it is red except the guard: the symbols are plain cells, so there is no link to
 * find or to activate. That is the intended red -- absence of implementation (task 21), not a
 * broken import. The guard is green already because the catch-all route sends `/stocks/AAPL` to
 * `/`, which is protected; it stays here as what keeps the route protected once it exists.
 */

import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { useEffect } from 'react';
import { MemoryRouter, useLocation } from 'react-router';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { App } from '../src/App';

const INGRESAR = 'Ingresar';
const USUARIO = 'Usuario';
const CLAVE = 'Clave';
const MIS_ACCIONES = 'Mis Acciones';

const LOGIN_URL = '/api/auth/login';
const ME_URL = '/api/auth/me';
const FAVORITES_URL = '/api/favorites';
const STOCKS_URL = '/api/stocks';
const A_PASSWORD = 'una-clave-de-demo';

/** What the API answers a good credential with. */
const A_SESSION = {
  access_token: 'a.signed.token',
  token_type: 'bearer',
  expires_in: 3600,
  full_name: 'Juan Perez',
};

/** What `GET /api/auth/me` answers while the token is still good. */
const WHO_IT_IS = { id: 1, full_name: 'Juan Perez' };

/** One row of the grid, as `GET /api/favorites` answers it (`plan.md` → *Contratos*). */
interface Favorite {
  symbol: string;
  name: string;
  currency: string;
}

/** Three favourites, so "the right one" can be told from "the first one" and from "the next one". */
const THE_LIST: Favorite[] = [
  { symbol: 'TSLA', name: 'Tesla Inc', currency: 'USD' },
  { symbol: 'AAPL', name: 'Apple Inc', currency: 'USD' },
  { symbol: 'NFLX', name: 'Netflix Inc', currency: 'USD' },
];

const FIRST_ROW = THE_LIST[0] as Favorite;
const THE_ONE_CHOSEN = THE_LIST[1] as Favorite;
const LAST_ROW = THE_LIST[2] as Favorite;

/** The URL of a fetch call, whichever of the three shapes it was made with. */
function urlOf(input: RequestInfo | URL): string {
  if (typeof input === 'string') return input;
  if (input instanceof URL) return input.href;

  return input.url;
}

/** A JSON answer, built fresh each time: a body can only be read once. */
function jsonResponse(payload: unknown, status: number): Response {
  return new Response(JSON.stringify(payload), { status });
}

/**
 * Replace fetch with a double that knows every route these screens call.
 *
 * Anything else answers 500 and not 401: an unknown route answering 401 would send the session
 * interceptor to the login, and a test about an address landing on the login would stop proving
 * anything at all.
 */
function stubTheApi(): void {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockImplementation((input: RequestInfo | URL) => {
      const url = urlOf(input);

      if (url.includes(LOGIN_URL)) return Promise.resolve(jsonResponse(A_SESSION, 200));
      if (url.includes(ME_URL)) return Promise.resolve(jsonResponse(WHO_IT_IS, 200));
      if (url.includes(FAVORITES_URL)) return Promise.resolve(jsonResponse(THE_LIST, 200));
      if (url.includes(STOCKS_URL)) return Promise.resolve(jsonResponse([], 200));

      return Promise.resolve(jsonResponse({ detail: 'this route was never agreed on' }, 500));
    }),
  );
}

/** Where the application is standing, kept up to date by the probe below. */
let currentAddress = '';

/**
 * The address, read the way a person reads the bar.
 *
 * It draws nothing: rendered next to the application inside the same router, it only reports the
 * address the router is on, in an effect, once the render that moved there is committed. Reading
 * it out of the DOM instead would mean putting a marker on the screen that nobody using the
 * application ever sees.
 */
function AddressProbe(): null {
  const { pathname } = useLocation();

  useEffect(() => {
    currentAddress = pathname;
  }, [pathname]);

  return null;
}

/** Open the application at an address, the way pasting one in the browser does. */
function openAt(address: string): void {
  render(
    <MemoryRouter initialEntries={[address]}>
      <App />
      <AddressProbe />
    </MemoryRouter>,
  );
}

/** Log in the way a person does, and stop on `Mis Acciones` with its grid already painted. */
async function logInThroughTheScreen(): Promise<void> {
  render(
    <MemoryRouter initialEntries={['/login']}>
      <App />
      <AddressProbe />
    </MemoryRouter>,
  );

  const person = userEvent.setup();
  await person.type(screen.getByLabelText(USUARIO), 'juan');
  await person.type(screen.getByLabelText(CLAVE), A_PASSWORD);
  await person.click(screen.getByRole('button', { name: INGRESAR }));
  await screen.findByText(MIS_ACCIONES);
  await screen.findByRole('table');
}

/** The row of a symbol, looked up by what the person reads in it and not by its position. */
function rowOf(grid: HTMLElement, symbol: string): HTMLElement {
  const row = within(grid)
    .getAllByRole('row')
    .find((candidate) => within(candidate).queryByText(symbol) !== null);

  if (!row) throw new Error(`the grid has no row showing "${symbol}"`);

  return row;
}

/** The symbol of a row, read as the link it has to be. */
async function theSymbolLinkOf(symbol: string): Promise<HTMLElement> {
  const grid = await screen.findByRole('table');

  return within(rowOf(grid, symbol)).getByRole('link', { name: symbol });
}

/** Where the application is standing right now. */
function theAddress(): string {
  return currentAddress;
}

beforeEach(() => {
  sessionStorage.clear();
  currentAddress = '';
  stubTheApi();
});

afterEach(() => {
  vi.unstubAllGlobals();
  sessionStorage.clear();
});

describe('the symbol of a row in the grid', () => {
  it('is a link a person can activate, and not loose text', async () => {
    // Read by role, which is what a screen reader announces and what a keyboard can reach:
    // a `<span onClick>` renders the same three letters and fails here, which is the point.
    await logInThroughTheScreen();

    for (const favourite of THE_LIST) {
      expect(await theSymbolLinkOf(favourite.symbol)).toBeInTheDocument();
    }
  });
});

describe('activating the symbol of a row', () => {
  it('lands on the detail of that same action', async () => {
    // With the second of three rows chosen on purpose: the bug is a link that always goes
    // to the first row, or that carries the symbol of the row beside it, and both of them pass
    // when the grid has one row.
    await logInThroughTheScreen();

    await userEvent.setup().click(await theSymbolLinkOf(THE_ONE_CHOSEN.symbol));

    await waitFor(() => {
      expect(theAddress()).toBe(`/stocks/${THE_ONE_CHOSEN.symbol}`);
    });
  });

  it('does not land on the detail of another action of the list', async () => {
    // The other half, spelled out: arriving somewhere is not arriving at the right place.
    await logInThroughTheScreen();

    await userEvent.setup().click(await theSymbolLinkOf(THE_ONE_CHOSEN.symbol));

    await waitFor(() => {
      expect(theAddress()).not.toBe('/');
    });
    expect(theAddress()).not.toBe(`/stocks/${FIRST_ROW.symbol}`);
    expect(theAddress()).not.toBe(`/stocks/${LAST_ROW.symbol}`);
  });
});

describe('the detail address opened with no session', () => {
  it('leaves the visitor looking at the login, like `/` does', async () => {
    // The route is protected by `RequireSession` (`plan.md`): an inner address is not a way in.
    openAt(`/stocks/${THE_ONE_CHOSEN.symbol}`);

    expect(await screen.findByRole('button', { name: INGRESAR })).toBeInTheDocument();
    expect(screen.getByLabelText(USUARIO)).toBeInTheDocument();
  });

  it('shows nothing of the action that was asked for', async () => {
    // A guard that draws the screen and redirects afterwards leaks a frame of it. Nothing of the
    // detail reaches somebody with no session, not even the symbol.
    openAt(`/stocks/${THE_ONE_CHOSEN.symbol}`);

    await screen.findByRole('button', { name: INGRESAR });
    expect(screen.queryByText(THE_ONE_CHOSEN.symbol)).toBeNull();
  });
});
