/**
 * H3 of `002`: taking an action out of the grid, with a confirmation in between.
 *
 * It covers the `Eliminar` control of every row, the confirmation that names the symbol
 * of the row it was fired from and leaves that row where it is until somebody answers,
 * the confirmation that removes it without a reload, `Cancelar` that changes nothing
 *, and the F5 that finds the list exactly as the API left it.
 *
 * Everything is looked at **through the screen**, the way `addFavorite.test.tsx` already does it:
 * the person logs in, reads the grid, activates a control and answers a question. `plan.md` puts
 * the dialog in `components/ConfirmDialog.tsx` and the state in `pages/MyActions.tsx`, but which
 * component renders a given node is an internal arrangement nobody signed.
 *
 * **The confirmation is read by role, and its text by what it reads out.** `getByRole('dialog')`
 * is what a person using a screen reader gets when a modal opens, and `<dialog>` -- which the plan
 * fixes, against `window.confirm()` (the browser labels its button `Aceptar` and will not
 * be told otherwise) -- carries that role natively. The question itself is asserted against the
 * dialog's text and not against a single node, because the symbol is interpolated into it and how
 * many elements that ends up being is markup, not copy.
 *
 * **The row control is `Eliminar` by accessible name, of a role that can be activated.** The copy
 * calls it a link and the plan does not fix a role; a link that navigates nowhere is a button, so
 * either is accepted here and a bare `<span>` with a click handler is not -- that is a control
 * nobody using a keyboard or a screen reader can reach. See the report of this task: the choice is
 * a requirement the plan did not settle.
 *
 * **The double answers every route this screen calls** -- `/api/auth/login`, `/api/auth/me`,
 * `GET`/`POST`/`DELETE` on `/api/favorites` and `GET /api/stocks` -- and anything else with a
 * **500**. A double that answered 401 to a route it did not know would look to the session
 * interceptor exactly like an expired session, and the screen under test would be replaced by the
 * login for a reason that has nothing to do with the test.
 *
 * The `DELETE` answers **204 with no body at all**, which is what the API answers (`plan.md` ->
 * *Contratos*): a client that tried to parse it would throw in the happy path, and that is the
 * failure `client.test.ts` guards from the other side.
 *
 * Today every test here is red because nothing of this is built yet: the grid draws three columns
 * of data and a fourth that is empty. That is the intended red -- absence of implementation
 * (task 18), not a broken import.
 */

import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { App } from '../src/App';

const INGRESAR = 'Ingresar';
const USUARIO = 'Usuario';
const CLAVE = 'Clave';
const MIS_ACCIONES = 'Mis Acciones';

// Verbatim from `docs/design/COPY.md`: the link of the row, and the two options of the
// confirmation the client wrote for this feature.
const ELIMINAR = 'Eliminar';
const CANCELAR = 'Cancelar';

/** The confirmation of `COPY.md`, with the symbol of the row put in it (`¿Quitar {símbolo} …`). */
function confirmationFor(symbol: string): string {
  return `¿Quitar ${symbol} de tus acciones?`;
}

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

/** One row of the grid: the three fields `GET /api/favorites` answers (`plan.md` → *Contratos*). */
interface Stock {
  symbol: string;
  name: string;
  currency: string;
}

const NETFLIX: Stock = { symbol: 'NFLX', name: 'Netflix Inc', currency: 'USD' };
const APPLE: Stock = { symbol: 'AAPL', name: 'Apple Inc', currency: 'USD' };

/** What the API has stored for the session under test. The `DELETE` of the double writes here. */
let storedFavorites: Stock[] = [];

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

/** The symbol a `DELETE /api/favorites/{symbol}` was aimed at, read from the address. */
function symbolDeletedIn(url: string): string {
  return decodeURIComponent(url.split('?')[0]?.split('/').pop() ?? '');
}

/** Every symbol the screen asked the API to remove, in order. */
function removalsAsked(): string[] {
  return vi
    .mocked(fetch)
    .mock.calls.filter(
      ([input, init]) => urlOf(input).includes(FAVORITES_URL) && init?.method === 'DELETE',
    )
    .map(([input]) => symbolDeletedIn(urlOf(input)));
}

/** How many times the screen asked our API for the list. */
function listingsAsked(): number {
  return vi
    .mocked(fetch)
    .mock.calls.filter(
      ([input, init]) => urlOf(input).includes(FAVORITES_URL) && (init?.method ?? 'GET') === 'GET',
    ).length;
}

/**
 * The removal, as `DELETE /api/favorites/{symbol}` answers it: 204, with no body, always.
 *
 * Removing something that is not in the list is a 204 too, so the double does what the
 * API does and simply filters: no branch, because there is no failure to model.
 */
function removeFromTheList(url: string): Promise<Response> {
  const symbol = symbolDeletedIn(url).toUpperCase();
  storedFavorites = storedFavorites.filter((stock) => stock.symbol !== symbol);

  return Promise.resolve(new Response(null, { status: 204 }));
}

/** Replace fetch with a double that knows every route this screen calls, and 500s the rest. */
function stubTheApi(): void {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockImplementation((input: RequestInfo | URL, init?: RequestInit) => {
      const url = urlOf(input);

      if (url.includes(LOGIN_URL)) return Promise.resolve(jsonResponse(A_SESSION, 200));
      if (url.includes(ME_URL)) return Promise.resolve(jsonResponse(WHO_IT_IS, 200));
      if (url.includes(STOCKS_URL)) return Promise.resolve(jsonResponse([], 200));
      if (url.includes(FAVORITES_URL)) {
        if (init?.method === 'DELETE') return removeFromTheList(url);
        if (init?.method === 'POST') return Promise.resolve(jsonResponse(storedFavorites[0], 200));

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

/** The row of a symbol in the grid, or `null` when the grid does not show it. */
function rowOf(symbol: string): HTMLElement | null {
  const grid = screen.getByRole('table');

  return (
    within(grid)
      .getAllByRole('row')
      .find((candidate) => within(candidate).queryByText(symbol) !== null) ?? null
  );
}

/** The row of a symbol, waited for and required to be there. */
async function theRowOf(symbol: string): Promise<HTMLElement> {
  await waitFor(() => {
    expect(rowOf(symbol)).not.toBeNull();
  });

  return rowOf(symbol) as HTMLElement;
}

/**
 * The `Eliminar` control of one row, whichever activatable role it was given.
 *
 * The copy calls it a link and the plan does not fix the role, so both are accepted: what is not
 * accepted is a node with no role at all, which is a control that cannot be reached by keyboard
 * and is announced by nothing.
 */
function theRemoveControlOf(row: HTMLElement): HTMLElement {
  const found =
    within(row).queryByRole('button', { name: ELIMINAR }) ??
    within(row).queryByRole('link', { name: ELIMINAR });

  if (!found) {
    throw new Error(
      `the row offers no control named "${ELIMINAR}" that a person can activate (RF-23): it has ` +
        'to be a button or a link, not a node with a click handler and no role',
    );
  }

  return found;
}

/** The confirmation, once it is open: a modal, which is the role `<dialog>` carries. */
async function theConfirmation(): Promise<HTMLElement> {
  return await screen.findByRole('dialog');
}

/** Activate `Eliminar` on the row of a symbol and hand back the confirmation it opened. */
async function askToRemove(symbol: string): Promise<HTMLElement> {
  const person = userEvent.setup();
  await person.click(theRemoveControlOf(await theRowOf(symbol)));

  return await theConfirmation();
}

/** Answer the confirmation with one of its two options. */
async function answerTheConfirmation(dialog: HTMLElement, option: string): Promise<void> {
  await userEvent.setup().click(within(dialog).getByRole('button', { name: option }));
}

beforeEach(() => {
  sessionStorage.clear();
  storedFavorites = [NETFLIX, APPLE];
  stubTheApi();
});

afterEach(() => {
  vi.unstubAllGlobals();
  sessionStorage.clear();
});

describe('every row of the grid', () => {
  it('offers the Eliminar of the copy', async () => {
    // It is the fourth column of the wireframe: the one without a heading. The text is
    // verbatim from COPY.md, and what it has to be is something a person can activate.
    await logInThroughTheScreen();

    expect(theRemoveControlOf(await theRowOf(NETFLIX.symbol))).toBeInTheDocument();
    expect(theRemoveControlOf(await theRowOf(APPLE.symbol))).toBeInTheDocument();
  });

  it('does not remove anything just by being drawn', async () => {
    // The guard on everything below: a control that removed on render would empty somebody's list
    // on the way in, and every assertion about the confirmation would then be about nothing.
    await logInThroughTheScreen();

    expect(theRemoveControlOf(await theRowOf(NETFLIX.symbol))).toBeInTheDocument();
    expect(removalsAsked()).toEqual([]);
  });
});

describe('activating Eliminar on a row', () => {
  it('asks about the action of that row, by name', async () => {
    // Verbatim from COPY.md with the symbol interpolated. Naming it is the whole point:
    // it is what lets somebody notice they activated the wrong row (`docs/design/COPY.md`).
    await logInThroughTheScreen();

    const dialog = await askToRemove(NETFLIX.symbol);

    expect(dialog).toHaveTextContent(confirmationFor(NETFLIX.symbol));
  });

  it('does not name the other action of the list', async () => {
    // The half that makes the test above mean something: a confirmation that always named the
    // first row would read perfectly and remove the wrong action.
    await logInThroughTheScreen();

    const dialog = await askToRemove(APPLE.symbol);

    expect(dialog).toHaveTextContent(confirmationFor(APPLE.symbol));
    expect(dialog).not.toHaveTextContent(confirmationFor(NETFLIX.symbol));
  });

  it('offers Eliminar and Cancelar, and nothing has happened yet', async () => {
    // the two options of the copy, and the row still in the grid. A screen that removed
    // first and asked afterwards would answer the question after it stopped mattering.
    await logInThroughTheScreen();

    const dialog = await askToRemove(NETFLIX.symbol);

    expect(within(dialog).getByRole('button', { name: ELIMINAR })).toBeInTheDocument();
    expect(within(dialog).getByRole('button', { name: CANCELAR })).toBeInTheDocument();
    expect(rowOf(NETFLIX.symbol)).not.toBeNull();
    expect(removalsAsked()).toEqual([]);
  });
});

describe('confirming the removal', () => {
  it('asks our API to remove that symbol, and only that one', async () => {
    // On the wire: the symbol of the row that was activated travels in the address, which
    // is the one thing the screen decides about this request.
    await logInThroughTheScreen();

    await answerTheConfirmation(await askToRemove(NETFLIX.symbol), ELIMINAR);

    await waitFor(() => {
      expect(removalsAsked()).toEqual([NETFLIX.symbol]);
    });
  });

  it('takes the row out of the grid without a reload', async () => {
    // Which is the acceptance criterion of the story: the action is gone from the screen
    // as soon as it is gone from the list, with nobody pressing F5.
    await logInThroughTheScreen();

    await answerTheConfirmation(await askToRemove(NETFLIX.symbol), ELIMINAR);

    await waitFor(() => {
      expect(rowOf(NETFLIX.symbol)).toBeNull();
    });
  });

  it('leaves the rest of the list where it was', async () => {
    // One row leaves, the other stays. A screen that emptied the grid would pass the test above.
    await logInThroughTheScreen();

    await answerTheConfirmation(await askToRemove(NETFLIX.symbol), ELIMINAR);

    await waitFor(() => {
      expect(rowOf(NETFLIX.symbol)).toBeNull();
    });
    expect(rowOf(APPLE.symbol)).not.toBeNull();
  });

  it('closes the confirmation once it is answered', async () => {
    // A question that stays on screen after being answered reads as one that was not heard.
    await logInThroughTheScreen();

    await answerTheConfirmation(await askToRemove(NETFLIX.symbol), ELIMINAR);

    await waitFor(() => {
      expect(screen.queryByRole('dialog')).toBeNull();
    });
  });

  it('asks our API for the list again instead of patching the one it had', async () => {
    // `plan.md`: after removing, the grid is asked for again. The order of the rows is a decision
    // of the backend, and two places that order are one place that gets it wrong.
    await logInThroughTheScreen();
    const before = listingsAsked();

    await answerTheConfirmation(await askToRemove(NETFLIX.symbol), ELIMINAR);

    await waitFor(() => {
      expect(listingsAsked()).toBeGreaterThan(before);
    });
  });
});

describe('answering the confirmation with Cancelar', () => {
  it('leaves the action exactly where it was', async () => {
    // the escape hatch the confirmation is for. If cancelling removed anything, it would be
    // a step that changes nothing about the outcome.
    await logInThroughTheScreen();

    await answerTheConfirmation(await askToRemove(NETFLIX.symbol), CANCELAR);

    await waitFor(() => {
      expect(screen.queryByRole('dialog')).toBeNull();
    });
    expect(rowOf(NETFLIX.symbol)).not.toBeNull();
  });

  it('asks our API to remove nothing at all', async () => {
    // The other half, and the one the screen cannot fake: a request that went out and a grid that
    // was repainted from a stale list would look identical to this passing.
    await logInThroughTheScreen();

    await answerTheConfirmation(await askToRemove(NETFLIX.symbol), CANCELAR);

    await waitFor(() => {
      expect(screen.queryByRole('dialog')).toBeNull();
    });
    expect(removalsAsked()).toEqual([]);
  });

  it('still allows removing that action afterwards', async () => {
    // Cancelling is not a state the screen gets stuck in: the same row can be activated again.
    await logInThroughTheScreen();

    await answerTheConfirmation(await askToRemove(NETFLIX.symbol), CANCELAR);
    await waitFor(() => {
      expect(screen.queryByRole('dialog')).toBeNull();
    });
    await answerTheConfirmation(await askToRemove(NETFLIX.symbol), ELIMINAR);

    await waitFor(() => {
      expect(rowOf(NETFLIX.symbol)).toBeNull();
    });
  });
});

describe('an action removed and then the page reloaded', () => {
  it('is still gone after the F5', async () => {
    // It is a real F5: the page is thrown away with `unmount()` and the application is
    // opened again at the same address, with nothing left but what the browser kept in
    // `sessionStorage`. Mounting a second copy while the first is alive would prove the remount
    // and not the persistence -- `plan.md` → *Riesgos*, first row, forbids it.
    const first = await logInThroughTheScreen();

    await answerTheConfirmation(await askToRemove(NETFLIX.symbol), ELIMINAR);
    await waitFor(() => {
      expect(rowOf(NETFLIX.symbol)).toBeNull();
    });

    first.unmount();
    openAt('/');

    await screen.findByRole('table');
    await waitFor(() => {
      expect(rowOf(APPLE.symbol)).not.toBeNull();
    });
    expect(rowOf(NETFLIX.symbol)).toBeNull();
    expect(screen.queryByRole('button', { name: INGRESAR })).toBeNull();
  });
});

describe('an action whose removal was cancelled and then the page reloaded', () => {
  it('is still there after the F5', async () => {
    // The same F5, and it is the test that tells "cancelled" apart from "removed and
    // repainted from a list the screen kept in memory": what comes back after a reload is
    // whatever the API stored, and cancelling stored nothing.
    const first = await logInThroughTheScreen();

    await answerTheConfirmation(await askToRemove(NETFLIX.symbol), CANCELAR);
    await waitFor(() => {
      expect(screen.queryByRole('dialog')).toBeNull();
    });

    first.unmount();
    openAt('/');

    await screen.findByRole('table');
    await waitFor(() => {
      expect(rowOf(NETFLIX.symbol)).not.toBeNull();
    });
    expect(rowOf(APPLE.symbol)).not.toBeNull();
    expect(screen.queryByRole('button', { name: INGRESAR })).toBeNull();
  });
});
