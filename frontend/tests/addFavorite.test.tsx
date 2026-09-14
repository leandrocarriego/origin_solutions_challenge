/**
 * H2 of `002`: finding an action in the `Símbolo` field and putting it in the grid.
 *
 * It covers the autocomplete (RF-13, RF-14 and the race the plan writes down), the button that
 * stays disabled while nothing is chosen (RF-31), the row that shows up without a reload (RF-15,
 * RF-16), the two notices that never appear together (RF-19, RF-20, RF-21) and the action that
 * survives an F5 with its name and its currency and not only with its symbol (RF-17).
 *
 * Everything is looked at **through the screen**, the way `MyActions.test.tsx` already does it:
 * the person logs in, types in the field and reads what is drawn. `plan.md` puts the field in
 * `components/Autocomplete.tsx` and the state in `pages/MyActions.tsx`, but which component
 * renders a given node is an internal arrangement nobody signed -- a test that fixed a prop would
 * go red the day somebody moves a line without the screen changing for anybody.
 *
 * **The dropdown is read by role.** A suggestion is looked up with `getByRole('option')` and
 * chosen by clicking it, which is what a person does and what a screen reader announces. The plan
 * fixes that the field is an `input` with a dropdown of its own and not a `<select>` (UI-01), and
 * leaves the markup open; the accessible reading of "a list of suggestions you pick one from" is
 * a listbox with options, and asserting it here is what keeps the dropdown usable rather than a
 * pile of unlabelled `<div>`s. It is also the only way to tell a suggestion apart from the grid
 * row of the same symbol, which carries the same text.
 *
 * **Time is real, not faked.** The debounce is 250 ms (`plan.md`), so the test that says "with one
 * character it does not ask" waits past it on the clock and then reads what went out. Faking
 * timers would make the same assertion depend on the implementation using `setTimeout` and not,
 * say, an `AbortSignal.timeout`.
 *
 * **The double answers every route the screen calls** -- `/api/auth/login`, `/api/auth/me`,
 * `GET /api/favorites`, `POST /api/favorites` and `GET /api/stocks` -- and anything else with a
 * 500. A double that answered 401 to a route it did not know would send the session interceptor
 * to the login and turn an unrelated mistake into a screen that is simply not there.
 *
 * It also **respects the `AbortController`**: a search whose signal fires rejects with an
 * `AbortError`, which is what `fetch` does. That is what makes the race test fair -- an
 * implementation that cancels the stale search passes, and one that lets it land and paint over
 * the newer answer fails.
 *
 * Today every test here is red because nothing of this is built yet: `MyActions` draws the header
 * and the grid, and there is no `Símbolo` field to type in. That is the intended red -- absence of
 * implementation (task 13), not a broken import.
 */

import { act, render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { App } from '../src/App';

const INGRESAR = 'Ingresar';
const USUARIO = 'Usuario';
const CLAVE = 'Clave';
const MIS_ACCIONES = 'Mis Acciones';

// Verbatim from the `Mis Acciones` table of docs/design/COPY.md (UI-02).
const SIMBOLO = 'Símbolo';
const AUTOCOMPLETE = '(Autocomplete)';
const AGREGAR_SIMBOLO = 'Agregar Símbolo';
// Verbatim from the *Lista de favoritas* table of docs/design/COPY.md (UI-02), accents included.
const SIN_RESULTADOS = 'No se encontró ninguna acción con ese texto.';
const YA_ESTA = 'Esa acción ya está en tu lista.';
const SIN_SELECCION = 'Elegí una acción de las sugerencias.';

const LOGIN_URL = '/api/auth/login';
const ME_URL = '/api/auth/me';
const FAVORITES_URL = '/api/favorites';
const STOCKS_URL = '/api/stocks';
const A_PASSWORD = 'una-clave-de-demo';

/** The debounce the plan fixes for the autocomplete, in milliseconds. */
const DEBOUNCE_MS = 250;

/** What the API answers a good credential with. */
const A_SESSION = {
  access_token: 'a.signed.token',
  token_type: 'bearer',
  expires_in: 3600,
  full_name: 'Juan Perez',
};

/** What `GET /api/auth/me` answers while the token is still good. */
const WHO_IT_IS = { id: 1, full_name: 'Juan Perez' };

/** One row of the grid, and also one suggestion: the same three fields (`plan.md` → *Contratos*). */
interface Stock {
  symbol: string;
  name: string;
  currency: string;
}

/** What the catalogue of the double offers, small enough to reason about. */
const CATALOGUE: Stock[] = [
  { symbol: 'MSFT', name: 'Microsoft Corp', currency: 'USD' },
  { symbol: 'MU', name: 'Micron Technology', currency: 'USD' },
  { symbol: 'AAPL', name: 'Apple Inc', currency: 'USD' },
];

const MICROSOFT = CATALOGUE[0] as Stock;
const MICRON = CATALOGUE[1] as Stock;
const APPLE = CATALOGUE[2] as Stock;

/** What the API has stored for the session under test. The POST of the double writes here. */
let storedFavorites: Stock[] = [];

/** What `GET /api/stocks` answers, so one test can hold two searches in flight. */
let answerSearch: (q: string, init: RequestInit | undefined) => Promise<Response>;

/** A JSON answer, built fresh each time: a body can only be read once. */
function jsonResponse(payload: unknown, status: number): Response {
  return new Response(JSON.stringify(payload), { status });
}

/** The URL of a fetch call, whichever of the three shapes it was made with. */
function urlOf(input: RequestInfo | URL): string {
  if (typeof input === 'string') return input;
  if (input instanceof URL) return input.href;

  return input.url;
}

/** The `q` a search went out with, read from the address the way the backend reads it. */
function queryOf(url: string): string {
  return new URL(url, 'http://localhost').searchParams.get('q') ?? '';
}

/** Every text this screen searched the catalogue for, in order. */
function searchesMade(): string[] {
  return vi
    .mocked(fetch)
    .mock.calls.filter(([input]) => urlOf(input).includes(STOCKS_URL))
    .map(([input]) => queryOf(urlOf(input)));
}

/** Every call to `/api/favorites` made with a method, which is every attempt to add one. */
function additionsAttempted(): RequestInit[] {
  return vi
    .mocked(fetch)
    .mock.calls.filter(
      ([input, init]) => urlOf(input).includes(FAVORITES_URL) && (init?.method ?? 'GET') === 'POST',
    )
    .map(([, init]) => init as RequestInit);
}

/** How many times the screen asked our API for the list. */
function listingsAsked(): number {
  return vi
    .mocked(fetch)
    .mock.calls.filter(
      ([input, init]) => urlOf(input).includes(FAVORITES_URL) && (init?.method ?? 'GET') === 'GET',
    ).length;
}

/** The catalogue filtered the way the backend filters it: symbol or name, either case (RF-08..10). */
function catalogueMatching(q: string): Stock[] {
  const needle = q.trim().toLowerCase();

  return CATALOGUE.filter(
    (stock) =>
      stock.symbol.toLowerCase().includes(needle) || stock.name.toLowerCase().includes(needle),
  );
}

/** The default search of the double: it answers from the catalogue, right away. */
function searchTheCatalogue(q: string): Promise<Response> {
  return Promise.resolve(jsonResponse(catalogueMatching(q), 200));
}

/** The addition, as `POST /api/favorites` answers it: 201 when it creates, 200 when it was there. */
function addToTheList(init: RequestInit | undefined): Promise<Response> {
  const body = typeof init?.body === 'string' ? init.body : '{}';
  const asked = (JSON.parse(body) as { symbol?: string }).symbol ?? '';
  const inCatalogue = CATALOGUE.find((stock) => stock.symbol === asked.toUpperCase());

  if (!inCatalogue) return Promise.resolve(jsonResponse({ detail: 'unknown symbol' }, 404));

  const alreadyThere = storedFavorites.some((stock) => stock.symbol === inCatalogue.symbol);
  // The most recently added one comes first, which is the order the backend decides (RF-06).
  if (!alreadyThere) storedFavorites = [inCatalogue, ...storedFavorites];

  return Promise.resolve(jsonResponse(inCatalogue, alreadyThere ? 200 : 201));
}

/**
 * Replace fetch with a double that knows every route this screen calls.
 *
 * Anything else answers 500 and not 401: an unknown route that answered 401 would look to the
 * session interceptor exactly like an expired session, and the screen under test would be replaced
 * by the login for a reason that has nothing to do with the test.
 */
function stubTheApi(): void {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockImplementation((input: RequestInfo | URL, init?: RequestInit) => {
      const url = urlOf(input);

      if (url.includes(LOGIN_URL)) return Promise.resolve(jsonResponse(A_SESSION, 200));
      if (url.includes(ME_URL)) return Promise.resolve(jsonResponse(WHO_IT_IS, 200));
      if (url.includes(STOCKS_URL)) return answerSearch(queryOf(url), init);
      if (url.includes(FAVORITES_URL)) {
        if ((init?.method ?? 'GET') === 'POST') return addToTheList(init);

        return Promise.resolve(jsonResponse(storedFavorites, 200));
      }

      return Promise.resolve(jsonResponse({ detail: 'this route was never agreed on' }, 500));
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

/** Log in the way a person does, and stop on `Mis Acciones` with its grid already painted. */
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
  await screen.findByRole('table');

  return mounted;
}

/** The `Símbolo` field, looked up by its label like any person with a screen reader finds it. */
function theSymbolField(): HTMLElement {
  return screen.getByLabelText(SIMBOLO);
}

/** The button of the wireframe, whatever state it is in. */
function theAddButton(): HTMLElement {
  return screen.getByRole('button', { name: AGREGAR_SIMBOLO });
}

/** The suggestion that names a stock, waited for: it arrives from our API. */
async function theSuggestionOf(stock: Stock): Promise<HTMLElement> {
  return await screen.findByRole('option', { name: new RegExp(stock.name) });
}

/** The row of a symbol in the grid, or `null` when the grid does not show it. */
function rowOf(grid: HTMLElement, symbol: string): HTMLElement | null {
  return (
    within(grid)
      .getAllByRole('row')
      .find((candidate) => within(candidate).queryByText(symbol) !== null) ?? null
  );
}

/** Wait past the debounce on the clock: what has not been asked by then was not going to be. */
async function pastTheDebounce(): Promise<void> {
  await act(async () => {
    await new Promise((resolve) => setTimeout(resolve, DEBOUNCE_MS * 3));
  });
}

beforeEach(() => {
  sessionStorage.clear();
  storedFavorites = [];
  answerSearch = (q) => searchTheCatalogue(q);
  stubTheApi();
});

afterEach(() => {
  vi.unstubAllGlobals();
  sessionStorage.clear();
});

describe('the Símbolo field of the wireframe', () => {
  it('is a field with the placeholder of the copy, and not a select', async () => {
    // UI-01 and UI-02 together: the wireframe draws a text field with `(Autocomplete)` in it, and
    // a `<select>` cannot be typed into, which is the whole point of an autocomplete.
    await logInThroughTheScreen();

    expect(theSymbolField()).toBe(screen.getByPlaceholderText(AUTOCOMPLETE));
  });
});

describe('the autocomplete with a single character typed', () => {
  it('asks our API nothing at all', async () => {
    // RF-13. One letter matches almost any action, and the twenty suggestions that would come
    // back do not help anybody choose -- so the question is not asked.
    await logInThroughTheScreen();

    await userEvent.setup().type(theSymbolField(), 'm');
    await pastTheDebounce();

    expect(searchesMade()).toEqual([]);
  });

  it('shows no dropdown either', async () => {
    // The other half: nothing asked *and* nothing drawn. A dropdown showing a stale list would be
    // as wrong as one showing a fresh one.
    await logInThroughTheScreen();

    await userEvent.setup().type(theSymbolField(), 'm');
    await pastTheDebounce();

    expect(screen.queryAllByRole('option')).toHaveLength(0);
    expect(screen.queryByText(SIN_RESULTADOS)).toBeNull();
  });
});

describe('the autocomplete with two characters typed', () => {
  it('suggests the actions that match what was typed', async () => {
    // RF-13 read the other way round: the second character is where the suggestions start.
    await logInThroughTheScreen();

    await userEvent.setup().type(theSymbolField(), 'mi');

    expect(await theSuggestionOf(MICRON)).toBeInTheDocument();
    expect(await theSuggestionOf(MICROSOFT)).toBeInTheDocument();
  });

  it('says so, word for word, when nothing matches', async () => {
    // RF-14, verbatim from COPY.md: the notice goes where the suggestions would be, and it is what
    // tells "there is nothing" apart from "it is still looking".
    await logInThroughTheScreen();

    await userEvent.setup().type(theSymbolField(), 'zz');

    expect(await screen.findByText(SIN_RESULTADOS)).toBeInTheDocument();
    expect(screen.queryAllByRole('option')).toHaveLength(0);
  });
});

describe('two searches in flight, the older one answering last', () => {
  it('leaves the newer answer on screen', async () => {
    // The race of `plan.md` → *Riesgos*: without a controller per search, typing fast leaves the
    // dropdown showing the answer to a text that is no longer in the field. It happens always and
    // reproduces only sometimes, so the test forces it: the first search is answered *after* the
    // second one, and the screen has to keep the second.
    await logInThroughTheScreen();

    const answers = new Map<string, (rows: Stock[]) => void>();
    answerSearch = (q, init) =>
      new Promise<Response>((resolve, reject) => {
        answers.set(q, (rows) => {
          resolve(jsonResponse(rows, 200));
        });
        // A real `fetch` rejects when its signal fires; a double that resolved anyway would fail
        // an implementation that cancels correctly.
        init?.signal?.addEventListener('abort', () => {
          reject(new DOMException('the search was replaced by a newer one', 'AbortError'));
        });
      });

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'mi');
    await waitFor(() => {
      expect(answers.has('mi')).toBe(true);
    });
    await person.type(theSymbolField(), 'c');
    await waitFor(() => {
      expect(answers.has('mic')).toBe(true);
    });

    // The newer search answers first, the older one afterwards: the order that paints the wrong
    // list when nothing cancels.
    answers.get('mic')?.([MICROSOFT]);
    await theSuggestionOf(MICROSOFT);
    answers.get('mi')?.([APPLE]);
    await pastTheDebounce();

    expect(screen.queryByRole('option', { name: new RegExp(APPLE.name) })).toBeNull();
    expect(screen.getByRole('option', { name: new RegExp(MICROSOFT.name) })).toBeInTheDocument();
  });
});

describe('Agregar Símbolo while nothing is chosen', () => {
  it('is disabled with the field empty', async () => {
    // RF-31, and it is the first defence: the button does not offer an addition that cannot work.
    await logInThroughTheScreen();

    expect(theAddButton()).toBeDisabled();
  });

  it('is still disabled with text typed and no suggestion chosen', async () => {
    // The half that matters: what is written in the field is not a choice. Only a suggestion is,
    // because only the catalogue can say the symbol exists.
    await logInThroughTheScreen();

    await userEvent.setup().type(theSymbolField(), 'mi');
    await theSuggestionOf(MICROSOFT);

    expect(theAddButton()).toBeDisabled();
  });

  it('goes back to disabled when the person types again after choosing', async () => {
    // What is in the field stopped being what was chosen, so the choice is gone. Without this, a
    // person who edits the text after choosing adds whatever they had picked before.
    await logInThroughTheScreen();

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'mi');
    await person.click(await theSuggestionOf(MICROSOFT));
    await waitFor(() => {
      expect(theAddButton()).toBeEnabled();
    });

    await person.type(theSymbolField(), 'x');

    expect(theAddButton()).toBeDisabled();
  });
});

describe('choosing a suggestion and adding it', () => {
  it('leaves that action in the grid without a reload', async () => {
    // RF-15 and RF-16, which is the acceptance criterion of the story: `micro` finds Microsoft,
    // and the row is there afterwards without anybody pressing F5.
    await logInThroughTheScreen();

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'mi');
    await person.click(await theSuggestionOf(MICROSOFT));
    await person.click(theAddButton());

    const grid = await screen.findByRole('table');
    await waitFor(() => {
      expect(rowOf(grid, MICROSOFT.symbol)).not.toBeNull();
    });
  });

  it('shows its name and its currency in that row, and not only the symbol', async () => {
    // RF-17 on screen: what the grid promises is three data, and a row that shows the symbol alone
    // is a row of the list of symbols that this feature explicitly did not build.
    await logInThroughTheScreen();

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'mi');
    await person.click(await theSuggestionOf(MICROSOFT));
    await person.click(theAddButton());

    const grid = await screen.findByRole('table');
    await waitFor(() => {
      expect(rowOf(grid, MICROSOFT.symbol)).not.toBeNull();
    });
    const row = rowOf(grid, MICROSOFT.symbol) as HTMLElement;
    expect(within(row).getByText(MICROSOFT.name)).toBeInTheDocument();
    expect(within(row).getByText(MICROSOFT.currency)).toBeInTheDocument();
  });

  it('asks our API for the list again instead of patching the one it had', async () => {
    // `plan.md`: after adding, the grid is asked for again. The order of the rows is a decision of
    // the backend (RF-06), and two places that order are one place that gets it wrong.
    await logInThroughTheScreen();
    const before = listingsAsked();

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'mi');
    await person.click(await theSuggestionOf(MICROSOFT));
    await person.click(theAddButton());

    await waitFor(() => {
      expect(listingsAsked()).toBeGreaterThan(before);
    });
  });
});

describe('the dropdown once a suggestion was chosen', () => {
  it('stays closed, instead of reopening on the symbol it just put in the field', async () => {
    // Choosing writes the symbol into the field, and the field is what the search watches. Told
    // apart from a keystroke it means the question was answered; taken as one, the debounce fires
    // again and the dropdown the choice had closed comes back 250 ms later, offering the very
    // symbol that was already picked -- over the grid, and after the person moved on.
    await logInThroughTheScreen();

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'micro');
    await person.click(await theSuggestionOf(MICROSOFT));

    expect(screen.queryAllByRole('option')).toHaveLength(0);

    await pastTheDebounce();

    expect(screen.queryAllByRole('option')).toHaveLength(0);
  });

  it('asks our API nothing more, because there is nothing left to suggest', async () => {
    // The other half, and the one a screenshot cannot show: the reopening is also a request our
    // own API answers for no reason, on every single choice somebody makes.
    await logInThroughTheScreen();

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'micro');
    await person.click(await theSuggestionOf(MICROSOFT));
    const asked = searchesMade().length;

    await pastTheDebounce();

    expect(searchesMade()).toHaveLength(asked);
  });

  it('comes back the moment somebody types again, even back onto the same symbol', async () => {
    // The guard on the guard: "the field holds a choice" must not become "this text is never
    // searched again". Editing is what makes it a search once more, and a person who deletes a
    // letter and types it back is editing.
    await logInThroughTheScreen();

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'micro');
    await person.click(await theSuggestionOf(MICROSOFT));
    await person.type(theSymbolField(), '{backspace}');
    await person.type(theSymbolField(), MICROSOFT.symbol.slice(-1));

    expect(await theSuggestionOf(MICROSOFT)).toBeInTheDocument();
  });
});

describe('adding an action that is already on the list', () => {
  it('says so, word for word', async () => {
    // RF-19, verbatim from COPY.md. Without the notice, adding something already there produces no
    // visible change at all and reads as a button that does not work.
    storedFavorites = [APPLE];

    await logInThroughTheScreen();

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'ap');
    await person.click(await theSuggestionOf(APPLE));
    await person.click(theAddButton());

    expect(await screen.findByText(YA_ESTA)).toBeInTheDocument();
  });

  it('leaves one row and not two', async () => {
    // RF-18 seen from the screen: the same action never appears twice in one list.
    storedFavorites = [APPLE];

    await logInThroughTheScreen();

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'ap');
    await person.click(await theSuggestionOf(APPLE));
    await person.click(theAddButton());
    await screen.findByText(YA_ESTA);

    const grid = await screen.findByRole('table');
    const showing = within(grid)
      .getAllByRole('row')
      .filter((row) => within(row).queryByText(APPLE.symbol) !== null);
    expect(showing).toHaveLength(1);
  });
});

describe('firing the addition with no suggestion chosen', () => {
  it('says what is missing, word for word', async () => {
    // RF-21, verbatim from COPY.md. The disabled button is the first defence and this is the
    // second, for when the addition is fired some other way -- the Enter key in the field.
    await logInThroughTheScreen();

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'zz');
    await screen.findByText(SIN_RESULTADOS);
    await person.type(theSymbolField(), '{Enter}');

    expect(await screen.findByText(SIN_SELECCION)).toBeInTheDocument();
  });

  it('adds nothing at all', async () => {
    // RF-20. The notice explains; what matters is that the list is exactly as it was, with no new
    // row and no empty one.
    storedFavorites = [APPLE];

    await logInThroughTheScreen();

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'zz');
    await screen.findByText(SIN_RESULTADOS);
    await person.type(theSymbolField(), '{Enter}');
    await screen.findByText(SIN_SELECCION);

    expect(additionsAttempted()).toEqual([]);
    const grid = await screen.findByRole('table');
    expect(within(grid).getAllByRole('row')).toHaveLength(storedFavorites.length + 1);
  });
});

describe('the two notices of the Símbolo field', () => {
  it('never show at the same time, whichever comes first', async () => {
    // COPY.md says it and `plan.md` makes it true by construction: one field that cannot hold two
    // values at once. Two notices side by side would contradict each other -- one says an action
    // was chosen and is already there, the other that none was chosen.
    storedFavorites = [APPLE];

    await logInThroughTheScreen();

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'zz');
    await screen.findByText(SIN_RESULTADOS);
    await person.type(theSymbolField(), '{Enter}');
    await screen.findByText(SIN_SELECCION);

    await person.clear(theSymbolField());
    await person.type(theSymbolField(), 'ap');
    await person.click(await theSuggestionOf(APPLE));
    await person.click(theAddButton());

    expect(await screen.findByText(YA_ESTA)).toBeInTheDocument();
    expect(screen.queryByText(SIN_SELECCION)).toBeNull();
  });

  it('gives way to the other one as soon as it applies', async () => {
    // The same rule read backwards: the notice of the duplicate is gone the moment the addition is
    // fired without a choice, and not left on screen next to the new one.
    storedFavorites = [APPLE];

    await logInThroughTheScreen();

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'ap');
    await person.click(await theSuggestionOf(APPLE));
    await person.click(theAddButton());
    await screen.findByText(YA_ESTA);

    await person.clear(theSymbolField());
    await person.type(theSymbolField(), 'zz');
    await screen.findByText(SIN_RESULTADOS);
    await person.type(theSymbolField(), '{Enter}');

    expect(await screen.findByText(SIN_SELECCION)).toBeInTheDocument();
    expect(screen.queryByText(YA_ESTA)).toBeNull();
  });
});

describe('an action added and then the page reloaded', () => {
  it('is still there, with its name and its currency', async () => {
    // RF-17, and it is a real F5: the page is thrown away with `unmount()` and the application is
    // opened again at the same address, with nothing left but what the browser kept in
    // `sessionStorage`. Mounting a second copy while the first is alive would prove the remount and
    // not the persistence -- `plan.md` → *Riesgos*, first row, forbids it.
    const first = await logInThroughTheScreen();

    const person = userEvent.setup();
    await person.type(theSymbolField(), 'mi');
    await person.click(await theSuggestionOf(MICROSOFT));
    await person.click(theAddButton());
    const firstGrid = await screen.findByRole('table');
    await waitFor(() => {
      expect(rowOf(firstGrid, MICROSOFT.symbol)).not.toBeNull();
    });

    first.unmount();
    openAt('/');

    const grid = await screen.findByRole('table');
    await waitFor(() => {
      expect(rowOf(grid, MICROSOFT.symbol)).not.toBeNull();
    });
    const row = rowOf(grid, MICROSOFT.symbol) as HTMLElement;
    expect(within(row).getByText(MICROSOFT.name)).toBeInTheDocument();
    expect(within(row).getByText(MICROSOFT.currency)).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: INGRESAR })).toBeNull();
  });
});
