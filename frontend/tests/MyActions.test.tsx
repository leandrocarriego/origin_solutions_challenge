/**
 * `Mis Acciones` -- the grid of wireframe 02 (RF-01, RF-02, RF-03), its empty state (RF-07) and
 * the reload that has to keep showing the same list (RF-05).
 *
 * The grid is looked at **through the screen**, not by importing the component that draws it. Two
 * reasons, and both are the point of this file:
 *
 * - What the spec signed is what a person sees on `Mis Acciones` after logging in -- four columns,
 *   one row per favourite -- and not that a particular component exists. `plan.md` puts the
 *   drawing in `components/StockGrid.tsx` and the state in `pages/MyActions.tsx`; which of the two
 *   renders a given cell is an internal arrangement, and a test that fixed it would go red the day
 *   somebody moves a `<td>` without the screen changing for anybody.
 * - The list is not a prop anybody passes in this application: it is what our API answers to
 *   `GET /api/favorites` for the session that is logged in. Rendering the grid with a hand-made
 *   array would skip exactly the half `RF-01` is about -- that the grid shows *the favourites of
 *   the identified user*.
 *
 * So every test here logs in the way a person does and then reads the screen. Today they are red
 * because `MyActions` draws only the header: there is no table, and nothing asks the API for a
 * list. That is the intended red -- absence of implementation, not a broken import.
 *
 * **The reload is a real F5** (RF-05): the page is thrown away with `unmount()` and the application
 * is opened again at the same address, which is the only thing a browser leaves behind -- whatever
 * is in `sessionStorage`. Mounting a second copy of the application without dropping the first
 * would prove that React can render twice, which is not the requirement. It is the same shape
 * `session.test.tsx` already uses for the session itself, and `plan.md` makes it a rule
 * (→ *Riesgos*, first row).
 *
 * `fetch` is replaced in every test: a frontend test that goes to the network is not a frontend
 * test, and it would fail in CI for something that is not the test (`add_tests`, `TEST-03`).
 */

import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { App } from '../src/App';

const INGRESAR = 'Ingresar';
const USUARIO = 'Usuario';
const CLAVE = 'Clave';
const MIS_ACCIONES = 'Mis Acciones';

// Verbatim from the `Mis Acciones` table of docs/design/COPY.md (UI-02). The fourth column has no
// heading in the wireframe, and that absence is asserted rather than a fourth name.
const SIMBOLO = 'Símbolo';
const NOMBRE = 'Nombre';
const MONEDA = 'Moneda';
// Verbatim from the *Lista de favoritas* table of docs/design/COPY.md (UI-02).
const LISTA_VACIA = 'Todavía no agregaste ninguna acción.';

const LOGIN_URL = '/api/auth/login';
const ME_URL = '/api/auth/me';
const FAVORITES_URL = '/api/favorites';
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

/** The three favourites of the demo user, in the order the backend decides (RF-06). */
const THE_LIST: Favorite[] = [
  { symbol: 'TSLA', name: 'Tesla Inc', currency: 'USD' },
  { symbol: 'AAPL', name: 'Apple Inc', currency: 'USD' },
  { symbol: 'NFLX', name: 'Netflix Inc', currency: 'USD' },
];

/** The URL of a fetch call, whichever of the three shapes it was made with. */
function urlOf(input: RequestInfo | URL): string {
  if (typeof input === 'string') return input;
  if (input instanceof URL) return input.href;

  return input.url;
}

/**
 * Replace fetch: the login succeeds, `/me` recognises the session, and `/favorites` answers a list.
 *
 * Everything else is refused, so a call this feature never agreed to make shows up as a failure
 * and not as a silent success.
 */
function stubTheApi(favorites: Favorite[]): void {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockImplementation((input: RequestInfo | URL) => {
      const url = urlOf(input);

      if (url.includes(LOGIN_URL)) {
        return Promise.resolve(new Response(JSON.stringify(A_SESSION), { status: 200 }));
      }
      if (url.includes(ME_URL)) {
        return Promise.resolve(new Response(JSON.stringify(WHO_IT_IS), { status: 200 }));
      }
      if (url.includes(FAVORITES_URL)) {
        return Promise.resolve(new Response(JSON.stringify(favorites), { status: 200 }));
      }

      return Promise.resolve(
        new Response(JSON.stringify({ detail: 'not authenticated' }), { status: 401 }),
      );
    }),
  );
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

/** The grid, once it is on screen. Waits for it: the list arrives from our API. */
async function theGrid(): Promise<HTMLElement> {
  return await screen.findByRole('table');
}

/** The row of a symbol, looked up by what the person reads in it and not by its position. */
function rowOf(grid: HTMLElement, symbol: string): HTMLElement {
  const row = within(grid)
    .getAllByRole('row')
    .find((candidate) => within(candidate).queryByText(symbol) !== null);

  if (!row) throw new Error(`the grid has no row showing "${symbol}"`);

  return row;
}

beforeEach(() => {
  sessionStorage.clear();
  stubTheApi(THE_LIST);
});

afterEach(() => {
  vi.unstubAllGlobals();
  sessionStorage.clear();
});

describe('the grid of Mis Acciones', () => {
  it('shows the favourites of whoever is logged in', async () => {
    // RF-01. The list is not a prop: it is what our API answers for this session, and the screen
    // has to ask for it on its own.
    await logInThroughTheScreen();

    const grid = await theGrid();
    for (const favourite of THE_LIST) {
      expect(within(grid).getByText(favourite.symbol)).toBeInTheDocument();
    }
  });

  it('has four columns, and only three of them carry a heading', async () => {
    // RF-02, and it is the wireframe read literally: the fourth column is drawn with its heading
    // cell empty. Asserting four headings with the last one blank is what tells that apart from a
    // grid of three columns -- and from one where somebody "fixed" the gap with a word.
    await logInThroughTheScreen();

    const grid = await theGrid();
    const headings = within(grid).getAllByRole('columnheader');

    expect(headings).toHaveLength(4);
    expect(headings.map((heading) => heading.textContent?.trim() ?? '')).toEqual([
      SIMBOLO,
      NOMBRE,
      MONEDA,
      '',
    ]);
  });

  it('shows one row per favourite, and no more', async () => {
    // RF-03. The heading row is one of them, so three favourites make four rows: a fifth would be
    // a row the API never sent.
    await logInThroughTheScreen();

    const grid = await theGrid();

    expect(within(grid).getAllByRole('row')).toHaveLength(THE_LIST.length + 1);
  });

  it('shows the symbol, the name and the currency of each one', async () => {
    // RF-03 again, read where it matters: the three data live in the same row, so a grid that
    // paints the right names against the wrong symbols fails here and not above.
    await logInThroughTheScreen();

    const grid = await theGrid();
    for (const favourite of THE_LIST) {
      const row = rowOf(grid, favourite.symbol);

      expect(within(row).getByText(favourite.name)).toBeInTheDocument();
      expect(within(row).getByText(favourite.currency)).toBeInTheDocument();
    }
  });
});

describe('the grid of somebody with no favourites', () => {
  it('still shows the three headings', async () => {
    // RF-07, and the reason the client asked for it: a grid with nothing at all reads as something
    // having failed. The headings are what say the list is empty and not broken.
    stubTheApi([]);

    await logInThroughTheScreen();

    const grid = await theGrid();
    const headings = within(grid).getAllByRole('columnheader');

    expect(headings.map((heading) => heading.textContent?.trim() ?? '')).toEqual([
      SIMBOLO,
      NOMBRE,
      MONEDA,
      '',
    ]);
  });

  it('says so, word for word, in place of the rows', async () => {
    // Verbatim from COPY.md (UI-02): the notice is the text the client wrote, accents included.
    stubTheApi([]);

    await logInThroughTheScreen();

    expect(await screen.findByText(LISTA_VACIA)).toBeInTheDocument();
  });

  it('puts that notice inside the grid, where the rows would be', async () => {
    // `COPY.md` does not only fix the text, it fixes where it goes: **in place of the rows**, with
    // the headings still on screen. Drawn above the table it would read as a notice about the
    // grid, and the headings underneath would describe nothing at all.
    stubTheApi([]);

    await logInThroughTheScreen();

    await screen.findByText(LISTA_VACIA);
    const grid = await theGrid();

    expect(within(grid).getByText(LISTA_VACIA)).toBeInTheDocument();
  });

  it('draws no data row at all', async () => {
    // The other half of "in place of the rows": an empty row, or a row of dashes, is not an empty
    // state -- it is a grid pretending to have content.
    stubTheApi([]);

    await logInThroughTheScreen();

    await screen.findByText(LISTA_VACIA);
    const grid = await theGrid();
    for (const favourite of THE_LIST) {
      expect(within(grid).queryByText(favourite.symbol)).toBeNull();
    }
  });
});

describe('Mis Acciones after a reload', () => {
  it('shows the same favourites again, and not the login', async () => {
    // RF-05, and it is a real F5: the page is thrown away and the application is opened again at
    // the same address, with nothing left but what the browser kept. Mounting a second copy while
    // the first is still alive would prove the remount and not the persistence (`plan.md`).
    const first = await logInThroughTheScreen();

    first.unmount();
    openAt('/');

    const grid = await theGrid();
    for (const favourite of THE_LIST) {
      expect(within(grid).getByText(favourite.symbol)).toBeInTheDocument();
    }
    expect(screen.queryByRole('button', { name: INGRESAR })).toBeNull();
  });

  it('asks our API for the list again, with the session it restored', async () => {
    // What survives the reload is the session, not the grid: the list is asked for once more, and
    // the answer is what gets painted. A screen that painted a cached array would pass the test
    // above and be showing somebody else's list after a user change.
    const first = await logInThroughTheScreen();
    await theGrid();
    first.unmount();

    vi.mocked(fetch).mockClear();
    openAt('/');

    await theGrid();
    const asked = vi
      .mocked(fetch)
      .mock.calls.filter(([input]) => urlOf(input).includes(FAVORITES_URL));
    expect(asked.length).toBeGreaterThan(0);
  });
});
