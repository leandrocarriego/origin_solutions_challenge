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
 * `Cerrar sesión`, H1 of `002` adds the grid and its empty state, and `003` adds the chart.
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

/**
 * One row of the copy: which table it came from, which row, and every literal it declares.
 *
 * `texts` is a list and not a string because one row of the copy can fix more than one text at a
 * time: `Columnas de la grilla` is written `` `Símbolo` · `Nombre` · `Moneda` `` in a single cell,
 * and a reader that kept only the first would leave two of the three column headings of `002`
 * unverified -- which is exactly the kind of silence `UI-02` exists to prevent.
 */
interface CopyRow {
  section: string;
  element: string;
  texts: string[];
}

/**
 * The rows whose text has to be on screen already.
 *
 * H1 built the login and the title of `Mis Acciones`; H2 adds the three texts of the session --
 * the user in the header (RF-08), the expiry notice (RF-17) and the one for when the server could
 * not be reached (RF-27); H3 adds `Cerrar sesión` (RF-18), which is the last text this feature
 * owes. A row added here before its screen exists turns this suite red for a screen nobody promised
 * yet, so what is left out is what has not been asked for yet: the chart of `003`. H1 of `002` adds
 * the two rows of the grid it draws -- the three column headings and the notice that stands in for
 * the rows when there are none -- H2 adds the six of the `Símbolo` field -- its label, its
 * placeholder, its button, and the three notices the client wrote for a search with no matches and
 * for the two ways an addition fails -- and H3 adds the two of the removal: the link of the fourth
 * column and the question it opens.
 *
 * `Cerrar sesión` is required once and appears twice in the copy -- under `Mis Acciones` and under
 * the Detail, both pointing at *Sesión y validación*, which is where the client wrote it down. The
 * row asked for here is that one: the other two are cross-references to it, and requiring the same
 * literal three times would fail three tests for one missing word.
 *
 * `003` then adds the chart screen, in the three blocks its stories sign for: the controls and the
 * axes of wireframe 03 (H1), the two date fields and the two range failures of the `Histórico`
 * (H3), and the three notices that say what the chart is showing (H4). Each block carries the
 * reason for the rows it leaves out -- there are four of those, and every one of them would ask a
 * source file for a literal that cannot exist there.
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
  // `002`, H1: the grid of wireframe 02 and what it says when there is nothing in it. The row of
  // the columns carries its three literals in one cell, and all three are required here.
  { section: 'Mis Acciones', element: 'Columnas de la grilla' },
  { section: 'Lista de favoritas', element: 'Lista vacía' },
  // `002`, H2: the `Símbolo` field of the wireframe with its placeholder and its button, the
  // notice that stands in for the suggestions when nothing matches, and the two notices of the
  // field -- which are excluyentes, so the copy declares them separately and so does the screen.
  { section: 'Mis Acciones', element: 'Etiqueta del autocomplete' },
  { section: 'Mis Acciones', element: 'Placeholder del autocomplete' },
  { section: 'Mis Acciones', element: 'Botón' },
  { section: 'Lista de favoritas', element: 'Búsqueda sin resultados' },
  { section: 'Lista de favoritas', element: 'Acción repetida' },
  { section: 'Lista de favoritas', element: 'Alta sin selección' },
  // `002`, H3: the link of the fourth column and the confirmation it opens. The confirmation is a
  // template -- `¿Quitar {símbolo} de tus acciones?` -- so what is required of `src/` is its fixed
  // parts and its two options, never the template whole: the symbol is interpolated and that
  // literal cannot exist in a source file. `fragmentsOf` is what splits it, and the test right
  // below `a text with a placeholder in the middle of it` is the guard on that splitting.
  { section: 'Mis Acciones', element: 'Link de baja' },
  { section: 'Lista de favoritas', element: 'Confirmación de baja' },
  // `003`, H1: the controls of wireframe 03 and the chart they draw. The two parenthesised notes
  // carry the misspellings of the brief -- `opcion` and `segun`, with no accent -- and these two
  // rows are what stops somebody from "correcting" them on the way to the screen.
  //
  // `Cabecera (izquierda)` is deliberately **not** here, and it is the one row of the table this
  // list cannot ask for: its cell carries two literals, the pattern `{símbolo} - {nombre} -
  // {moneda}` and the example `TSLA - Tesla Inc - USD`, and the second is an example of what the
  // screen shows for one action -- never a string a source file contains. Requiring it would ask
  // for a literal that cannot exist. What it stands for is checked where it can be: the header of
  // the detail is read off the screen in `ActionDetail.test.tsx` (RF-01).
  //
  // `Usuario (cabecera, derecha)` and `Cierre de sesión (cabecera, derecha)` are not here either:
  // they belong to `001`, `003` leaves them out of scope, and this list already asks for both from
  // their own sections -- requiring the same literal twice fails two tests for one missing word.
  { section: 'Detalle de Acción', element: 'Radio 1' },
  { section: 'Detalle de Acción', element: 'Aclaración del radio 1' },
  { section: 'Detalle de Acción', element: 'Radio 2' },
  { section: 'Detalle de Acción', element: 'Etiqueta intervalo' },
  { section: 'Detalle de Acción', element: 'Aclaración del intervalo' },
  { section: 'Detalle de Acción', element: 'Botón' },
  { section: 'Detalle de Acción', element: 'Eje Y' },
  { section: 'Detalle de Acción', element: 'Eje X' },
  { section: 'Detalle: navegación, horarios y validación', element: 'Volver a la lista' },
  { section: 'Detalle: navegación, horarios y validación', element: 'Aclaración de horarios' },
  { section: 'Detalle: navegación, horarios y validación', element: 'Intervalo sin elegir' },
  // `003`, H3: the two date fields the `Histórico` row draws, and the two range failures the
  // client wrote for it. Both of those are templates, and `fragmentsOf` is what splits them at the
  // edges of `{intervalo}` and `{N}`: what is required of a source file is the fixed parts, never
  // the placeholder. `Completá este campo.` is not added here -- the detail shows the same text
  // the login already shows, and `REQUIRED` has asked for it from *Sesión y validación* since
  // `001`.
  { section: 'Detalle de Acción', element: 'Placeholder desde' },
  { section: 'Detalle de Acción', element: 'Placeholder hasta' },
  { section: 'Detalle: navegación, horarios y validación', element: 'Fechas al revés' },
  { section: 'Detalle: navegación, horarios y validación', element: 'Rango excedido' },
  // `003`, H4: the three notices that explain what the chart is showing. The names carry their
  // backticks because that is how the copy writes the first cell of that table -- the state, as an
  // identifier -- and this list asks for a row exactly as it is written.
  //
  // Three and not four: the fourth row of the table is `ok`, whose text is *(sin aviso)* and
  // carries no literal at all. The reader above drops rows with no literal, so asking for that one
  // would raise for a row that, to this suite, does not exist. That `ok` draws no notice is
  // checked on the screen, in `ActionDetail.test.tsx` (RF-32), which is where it can be checked.
  { section: 'Avisos de estado', element: '`stale`' },
  { section: 'Avisos de estado', element: '`market_closed`' },
  { section: 'Avisos de estado', element: '`no_data`' },
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

    const literals = [...(cells[1] ?? '').matchAll(/`([^`]+)`/g)].map((match) => match[1] ?? '');
    if (literals.length === 0) continue;

    rows.push({ section, element: (cells[0] ?? '').trim(), texts: literals });
  }

  return rows;
}

const ROWS = rowsOfTheCopy();

/** Every text of one row, failing loudly if the copy no longer declares that row. */
function textsOf(wanted: Pick<CopyRow, 'section' | 'element'>): string[] {
  const found = ROWS.find(
    (row) => row.section === wanted.section && row.element === wanted.element,
  );
  if (!found) {
    throw new Error(
      `${COPY} no longer has a row "${wanted.element}" under "${wanted.section}". ` +
        'If the text moved, move this expectation with it; the copy is the source.',
    );
  }

  return found.texts;
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

describe('a row of the copy that fixes more than one text', () => {
  it('is read whole, and not down to its first literal', () => {
    // The guard on the guard. `Columnas de la grilla` is three headings in one cell, and a reader
    // that stopped at the first would leave `Nombre` and `Moneda` unchecked while this suite went
    // green -- a guard that passes by looking at less than it was asked to look at.
    expect(textsOf({ section: 'Mis Acciones', element: 'Columnas de la grilla' })).toEqual([
      'Símbolo',
      'Nombre',
      'Moneda',
    ]);
  });
});

describe('a text with a placeholder in the middle of it', () => {
  it('is required by its fixed parts, and never by the placeholder', () => {
    // Without this, a bug in the splitting would leave the header's text demanding nothing and
    // the assertion below would pass for a screen that shows no user at all.
    expect(fragmentsOf('Usuario: {nombre completo}')).toEqual(['Usuario:']);
    expect(fragmentsOf('usuario o clave invalida')).toEqual(['usuario o clave invalida']);

    // The confirmation of the removal is the other one, and it has a placeholder in the middle
    // rather than at the end: both halves are text the screen writes, and both are required.
    // Asking for the template whole would ask for a string that is never going to be in `src/`;
    // dropping the row would leave the only question this application asks unverified.
    expect(fragmentsOf('¿Quitar {símbolo} de tus acciones?')).toEqual([
      '¿Quitar',
      'de tus acciones?',
    ]);
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
    for (const text of textsOf(required)) {
      for (const fragment of fragmentsOf(text)) {
        const found = sourcesContaining(fragment);

        expect(
          found,
          `no file under src/ contains ${JSON.stringify(fragment)}, which ${COPY} requires`,
        ).not.toHaveLength(0);
      }
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
