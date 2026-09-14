/**
 * The header of an inner screen: who is logged in (RF-08).
 *
 * One row of `COPY.md` and one trap. The text is `Usuario: {nombre completo}`, and
 * `{nombre completo}` is *the name of the person*, not the name they typed to get in: `Usuario:
 * Juan Perez`, never `Usuario: juan`. The demo data keeps the two apart on purpose -- `juan` /
 * `Juan Perez` and `ana` / `Ana Gomez` -- so a screen that paints the username looks right until
 * somebody reads it, and these tests fail on it.
 *
 * Both users are exercised, and that is the second half of the same trap: with only one of them,
 * a header with `Usuario: Juan Perez` written into it would pass.
 *
 * The header is reached through the application, by logging in, and not by rendering `Header` with
 * props of this test's invention. `plan.md` fixes the file and the text it shows; it does not fix
 * its signature, and a test that chose one would be fixing a shape nobody signed. What a person
 * sees is the same either way.
 *
 * **H3 adds the second thing the header carries: `Cerrar sesión` (RF-18).** It goes in the header,
 * on the right, next to the name -- so it is asserted inside the header and not merely somewhere on
 * the page, which a text dropped at the bottom of the screen would also satisfy. And it is looked
 * up as a button or a link, because an action a person activates has to be reachable as one; a
 * `<span onClick>` fails that on purpose.
 *
 * RF-18 also asks for it on the Detail screen, and that cannot be tested here: the Detail is `003`
 * and does not exist. What makes it true when it does is that both screens draw this same `Header`,
 * which is why the title is a prop.
 */

import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { App } from '../src/App';

const USUARIO = 'Usuario';
const CLAVE = 'Clave';
const INGRESAR = 'Ingresar';
const MIS_ACCIONES = 'Mis Acciones';
// Verbatim from the session table of docs/design/COPY.md (UI-02).
const CERRAR_SESION = 'Cerrar sesión';

const LOGIN_URL = '/api/auth/login';
const ME_URL = '/api/auth/me';
const A_PASSWORD = 'una-clave-de-demo';

/** The two demo users of the brief: what they type, and the name the header has to show. */
const DEMO_USERS = [
  { username: 'juan', fullName: 'Juan Perez' },
  { username: 'ana', fullName: 'Ana Gomez' },
];

/** The URL of a fetch call, whichever of the three shapes it was made with. */
function urlOf(input: RequestInfo | URL): string {
  if (typeof input === 'string') return input;
  if (input instanceof URL) return input.href;

  return input.url;
}

/**
 * Replace fetch: the login hands out a session for that person, and `/me` recognises it.
 *
 * The full name is answered by both, because both are places it can come from -- the login's
 * response and the restored session -- and the header has to read the same either way.
 */
function stubTheApiFor(fullName: string): void {
  const session = {
    access_token: 'a.signed.token',
    token_type: 'bearer',
    expires_in: 3600,
    full_name: fullName,
  };

  vi.stubGlobal(
    'fetch',
    vi.fn().mockImplementation((input: RequestInfo | URL) => {
      if (urlOf(input).includes(LOGIN_URL)) {
        return Promise.resolve(new Response(JSON.stringify(session), { status: 200 }));
      }
      if (urlOf(input).includes(ME_URL)) {
        return Promise.resolve(
          new Response(JSON.stringify({ id: 1, full_name: fullName }), { status: 200 }),
        );
      }

      return Promise.resolve(
        new Response(JSON.stringify({ detail: 'not authenticated' }), { status: 401 }),
      );
    }),
  );
}

/** Log in as that person and stop on the inner screen, which is where the header lives. */
async function logInAs(username: string): Promise<{ unmount: () => void }> {
  const mounted = render(
    <MemoryRouter initialEntries={['/login']}>
      <App />
    </MemoryRouter>,
  );

  const person = userEvent.setup();
  await person.type(screen.getByLabelText(USUARIO), username);
  await person.type(screen.getByLabelText(CLAVE), A_PASSWORD);
  await person.click(screen.getByRole('button', { name: INGRESAR }));
  await screen.findByText(MIS_ACCIONES);

  return mounted;
}

beforeEach(() => {
  sessionStorage.clear();
});

afterEach(() => {
  vi.unstubAllGlobals();
  sessionStorage.clear();
});

describe.each(DEMO_USERS)('the header after logging in as $username', ({ username, fullName }) => {
  it('reads the full name of the person, and not the user they typed', async () => {
    stubTheApiFor(fullName);

    await logInAs(username);

    expect(await screen.findByText(`Usuario: ${fullName}`)).toBeInTheDocument();
    expect(screen.queryByText(`Usuario: ${username}`)).toBeNull();
  });
});

describe('the header after a reload', () => {
  it('still reads the name, which then comes from the API and not from the form', async () => {
    // RF-07 and RF-08 together: after F5 nothing was typed, so a header painted from what the
    // form held would come out empty. The restored session is where the name has to come from.
    stubTheApiFor('Juan Perez');

    const first = await logInAs('juan');
    first.unmount();

    render(
      <MemoryRouter initialEntries={['/']}>
        <App />
      </MemoryRouter>,
    );

    expect(await screen.findByText('Usuario: Juan Perez')).toBeInTheDocument();
  });
});

describe('the header of an inner screen, with somebody logged in', () => {
  it('offers `Cerrar sesión`, spelled as the copy spells it', async () => {
    // RF-18. Without it, the only way out of a session on a shared computer is closing the tab,
    // and whoever sits down next reopens it into somebody else's account.
    stubTheApiFor('Juan Perez');

    await logInAs('juan');

    await screen.findByText('Usuario: Juan Perez');
    expect(screen.getByText(CERRAR_SESION)).toBeInTheDocument();
  });

  it('puts it in the header, next to the name of the person', async () => {
    // `COPY.md` says where it goes, and where it goes is half of what it is: a way out found at
    // the bottom of a long screen is a way out nobody finds.
    stubTheApiFor('Juan Perez');

    await logInAs('juan');

    await screen.findByText('Usuario: Juan Perez');
    const header = screen.getByRole('banner');
    expect(within(header).getByText(CERRAR_SESION)).toBeInTheDocument();
    expect(within(header).getByText('Usuario: Juan Perez')).toBeInTheDocument();
  });

  it('offers it as something that can be activated, and not as a label', async () => {
    // A button or a link -- either passes. Anything else is unreachable by keyboard and announced
    // as plain text, so a person using a screen reader is told the words and not that they can go.
    stubTheApiFor('Juan Perez');

    await logInAs('juan');

    await screen.findByText('Usuario: Juan Perez');
    const activatable = [
      ...screen.queryAllByRole('button', { name: CERRAR_SESION }),
      ...screen.queryAllByRole('link', { name: CERRAR_SESION }),
    ];
    expect(
      activatable,
      `"${CERRAR_SESION}" is on screen but is neither a button nor a link`,
    ).not.toHaveLength(0);
  });
});

describe('the login screen, with nobody logged in', () => {
  it('does not offer a way out of a session that was never opened', async () => {
    // RF-18 is conditional: it asks for the way out only while a user is identified, and the
    // header is where that condition lives. A way out shown to a visitor who is already out is
    // an invitation to press something that does nothing.
    vi.stubGlobal(
      'fetch',
      vi
        .fn()
        .mockResolvedValue(
          new Response(JSON.stringify({ detail: 'not authenticated' }), { status: 401 }),
        ),
    );

    render(
      <MemoryRouter initialEntries={['/login']}>
        <App />
      </MemoryRouter>,
    );

    await screen.findByRole('button', { name: INGRESAR });
    expect(screen.queryByText(CERRAR_SESION)).toBeNull();
    expect(screen.queryByText(MIS_ACCIONES)).toBeNull();
  });
});
