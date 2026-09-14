/**
 * UI-02: the texts on screen are the literals of `docs/design/COPY.md`, verbatim.
 *
 * It reads the copy and looks for each literal in the *code* of `frontend/src` -- comments do not
 * count, and `withoutComments` below explains why at length. The literal never lives in this file:
 * what lives here is the *row* of the table it has to come from, so the day the client changes a
 * text, this suite starts asking for the new one on its own.
 *
 * Verbatim includes the misspellings of the brief. `usuario o clave invalida` has no accent, and
 * a screen that "fixes" it has walked away from an explicit requirement to gain a tilde. The last
 * test here is what notices.
 *
 * It grows with the screens. Only the texts of the screens that exist are required, and every
 * feature that builds one adds its rows: H2 adds the header and the expired session, H3 adds
 * `Cerrar sesión`, `002` and `003` add the grid and the chart.
 */

import { readFileSync } from 'node:fs';

import { describe, expect, it } from 'vitest';

/** Every TypeScript source of the application, as text. */
const SOURCES = import.meta.glob<string>('../src/**/*.{ts,tsx}', {
  query: '?raw',
  import: 'default',
  eager: true,
});

/** `docs/design/COPY.md`, relative to the frontend project, which is what vitest runs in. */
const COPY = '../docs/design/COPY.md';

/** One literal of the copy: which table it came from, which row, and what it says. */
interface CopyRow {
  section: string;
  element: string;
  text: string;
}

/**
 * The rows whose text has to be on screen already.
 *
 * H1 built the login and the title of `Mis Acciones`; H2 adds the three texts of the session --
 * the user in the header (RF-08), the expiry notice (RF-17) and the one for when the server could
 * not be reached (RF-27); H3 adds `Cerrar sesión` (RF-18), which is the last text this feature
 * owes. A row added here before its screen exists turns this suite red for a screen nobody promised
 * yet, so what is left out is what `002` and `003` were asked for: the grid, the autocomplete and
 * the chart.
 *
 * `Cerrar sesión` is required once and appears twice in the copy -- under `Mis Acciones` and under
 * the Detail, both pointing at *Sesión y validación*, which is where the client wrote it down. The
 * row asked for here is that one: the other two are cross-references to it, and requiring the same
 * literal three times would fail three tests for one missing word.
 */
const REQUIRED: Pick<CopyRow, 'section' | 'element'>[] = [
  { section: 'Login', element: 'Etiqueta usuario' },
  { section: 'Login', element: 'Placeholder usuario' },
  { section: 'Login', element: 'Etiqueta clave' },
  { section: 'Login', element: 'Botón' },
  { section: 'Login', element: 'Error de credenciales' },
  { section: 'Mis Acciones', element: 'Título (cabecera, izquierda)' },
  { section: 'Mis Acciones', element: 'Usuario (cabecera, derecha)' },
  { section: 'Sesión y validación', element: 'Campo vacío' },
  { section: 'Sesión y validación', element: 'Demasiados intentos' },
  { section: 'Sesión y validación', element: 'Sesión vencida' },
  { section: 'Sesión y validación', element: 'No se pudo conectar' },
  { section: 'Sesión y validación', element: 'Cierre de sesión' },
];

/** Read the copy and pull every `| Element | `text` |` row out of its tables. */
function rowsOfTheCopy(): CopyRow[] {
  const cwd = (globalThis as unknown as { process: { cwd: () => string } }).process.cwd();
  const markdown = readFileSync(`${cwd}/${COPY}`, 'utf8');

  const rows: CopyRow[] = [];
  let section = '';

  for (const line of markdown.split('\n')) {
    const heading = /^##\s+(.+)$/.exec(line);
    if (heading) {
      // `## Login — docs/design/wireframes/01-login.png` is the section "Login".
      section = (heading[1] ?? '').split('—')[0]?.trim() ?? '';
      continue;
    }

    const cells = line.trim().startsWith('|') ? line.split('|').slice(1, -1) : [];
    if (cells.length < 2) continue;

    const literal = /`([^`]+)`/.exec(cells[1] ?? '');
    if (!literal) continue;

    rows.push({ section, element: (cells[0] ?? '').trim(), text: literal[1] ?? '' });
  }

  return rows;
}

const ROWS = rowsOfTheCopy();

/** The text of one row, failing loudly if the copy no longer declares it. */
function textOf(wanted: Pick<CopyRow, 'section' | 'element'>): string {
  const found = ROWS.find(
    (row) => row.section === wanted.section && row.element === wanted.element,
  );
  if (!found) {
    throw new Error(
      `${COPY} no longer has a row "${wanted.element}" under "${wanted.section}". ` +
        'If the text moved, move this expectation with it; the copy is the source.',
    );
  }

  return found.text;
}

/**
 * The parts of a text that a source file can actually contain, with its placeholders removed.
 *
 * `Usuario: {nombre completo}` is one row of the copy and two different things: `Usuario: `, which
 * the screen writes, and `{nombre completo}`, which is the name of whoever is logged in and is
 * never going to appear in a source file. Demanding the row whole would ask for a literal that
 * cannot exist; ignoring the row would leave the one text of the header unchecked.
 *
 * So a text with a placeholder is required by its fixed parts, trimmed at the placeholder's edge
 * -- the space before `{nombre completo}` belongs to the interpolation, and how a formatter
 * decides to write it is not a text anybody agreed on. A text without placeholders is returned
 * untouched, which is every row this suite already had: for those, nothing changed.
 */
function fragmentsOf(text: string): string[] {
  if (!text.includes('{')) return [text];

  return text
    .split(/\{[^}]*\}/)
    .map((fragment) => fragment.trim())
    .filter((fragment) => fragment !== '');
}

/**
 * The string literal that starts at `from`, its quotes included, up to the closing one.
 *
 * Escapes are skipped whole, so `'it\\'s'` is one literal and not two. A literal that is never
 * closed runs to the end of the file, which is a source that does not compile: the shape of what is
 * returned then does not matter, only that this does not loop.
 */
function readStringLiteral(source: string, from: number): string {
  const quote = source[from];
  let i = from + 1;

  while (i < source.length) {
    const char = source[i];
    if (char === '\\') {
      i += 2;
      continue;
    }
    if (char === quote) return source.slice(from, i + 1);
    i += 1;
  }

  return source.slice(from);
}

/**
 * The same source with the contents of its comments removed.
 *
 * A comment that mentions a text does not put that text on screen, and `UI-02` is about what the
 * user reads. Without this, a literal is "found" by a docstring that merely names it -- and that is
 * not hypothetical: `Cerrar sesión` passed this suite while the only place it appeared in `src/`
 * was the docstring of `Header.tsx` saying that it belongs to H3 and is *not drawn yet*. The
 * assertion went green on the sentence explaining why the thing it asks for does not exist, which
 * is as wrong as a guard can be: the day somebody forgets to draw it, this suite says nothing.
 *
 * It is deliberately a plain scanner and not a clever regular expression, because the one case a
 * regular expression gets wrong is the one that matters here: `//` inside a string is not a
 * comment. `'https://example.test'` has to survive whole, and a pattern that cuts at the first
 * `//` would silently delete the rest of the line -- turning a text that *is* in the code into one
 * this suite cannot find, which is the same failure as before with the sign flipped.
 *
 * So strings are read whole and comments are dropped: the two cases the file actually contains.
 * Regular expression literals are not tracked, which is safe for the only thing that could go
 * wrong -- a `//` inside one has to be written `\\/\\/` to be legal, and an escaped slash never
 * opens a comment here.
 */
function withoutComments(source: string): string {
  let out = '';
  let i = 0;

  while (i < source.length) {
    const two = source.slice(i, i + 2);

    if (two === '//') {
      const end = source.indexOf('\n', i);
      // The newline itself is kept: what is dropped is the comment, not the shape of the file.
      i = end === -1 ? source.length : end;
      continue;
    }

    if (two === '/*') {
      const end = source.indexOf('*/', i + 2);
      i = end === -1 ? source.length : end + 2;
      continue;
    }

    const char = source[i] ?? '';

    if (char === "'" || char === '"' || char === '`') {
      const literal = readStringLiteral(source, i);
      out += literal;
      i += literal.length;
      continue;
    }

    out += char;
    i += 1;
  }

  return out;
}

/** Every source again, with its comments gone: this is what "appears in src/" means. */
const CODE = Object.fromEntries(
  Object.entries(SOURCES).map(([path, contents]) => [path, withoutComments(contents)]),
);

/** Which sources contain a literal, spelled exactly like that, outside of their comments. */
function sourcesContaining(text: string): string[] {
  return Object.entries(CODE)
    .filter(([, contents]) => contents.includes(text))
    .map(([path]) => path);
}

describe('the copy this project agreed on', () => {
  it('is read from the file and not from this test', () => {
    // If the parsing breaks, every assertion below passes for the wrong reason.
    expect(ROWS.length).toBeGreaterThan(10);
  });
});

describe('a text with a placeholder in the middle of it', () => {
  it('is required by its fixed parts, and never by the placeholder', () => {
    // Without this, a bug in the splitting would leave the header's text demanding nothing and
    // the assertion below would pass for a screen that shows no user at all.
    expect(fragmentsOf('Usuario: {nombre completo}')).toEqual(['Usuario:']);
    expect(fragmentsOf('usuario o clave invalida')).toEqual(['usuario o clave invalida']);
  });
});

describe('a literal that only lives in a comment', () => {
  it('does not count as being on screen', () => {
    // The guard on the guard. Without it the stripping above is an assertion about itself: it
    // would go quietly back to finding texts in docstrings the day somebody simplifies it, and
    // this suite would keep passing while saying nothing -- which is how it got here.
    expect(withoutComments('// Cerrar sesión')).not.toContain('Cerrar sesión');
    expect(withoutComments('/** `Cerrar sesión` belongs to H3 */')).not.toContain('Cerrar sesión');

    // And the other half: a text that is on screen stays found, comment alongside or not.
    expect(withoutComments("const out = 'Cerrar sesión'; // not yet drawn")).toContain(
      'Cerrar sesión',
    );
  });

  it('is told apart from a `//` that is part of a string', () => {
    // The one thing a regular expression gets wrong, and the reason the stripping is a scanner.
    // Cutting here would delete real code and fail a row for a text that is on screen.
    expect(
      withoutComments("const url = 'https://example.test/a'; const t = 'Ingresar';"),
    ).toContain('Ingresar');
    expect(withoutComments("const url = 'https://example.test/a';")).toContain('https://');
  });
});

describe.each(REQUIRED)('the text of "$element" under "$section"', (required) => {
  it('appears in frontend/src, spelled exactly as the copy spells it', () => {
    const text = textOf(required);

    for (const fragment of fragmentsOf(text)) {
      const found = sourcesContaining(fragment);

      expect(
        found,
        `no file under src/ contains ${JSON.stringify(fragment)}, which ${COPY} requires`,
      ).not.toHaveLength(0);
    }
  });
});

describe('the misspelling of the brief', () => {
  it('is not corrected on the way to the screen', () => {
    // The evaluator searches for the text the brief wrote. A tilde added here is a requirement
    // missed, not a typo fixed (UI-02, Article VII).
    const corrected = sourcesContaining('usuario o clave inválida');

    expect(corrected, 'the brief writes "invalida" with no accent').toHaveLength(0);
  });
});
