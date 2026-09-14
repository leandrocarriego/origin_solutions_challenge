/**
 * UI-03 and UI-07: no colour is written by hand, and no style is written inline.
 *
 * The palette lives in the `@theme` block of `src/styles/tokens.css` and reaches a component as a
 * utility (`bg-surface`, `text-error`, `border-border`). A hex in a component is a second place
 * where the palette is decided, and the day somebody changes the tone of an alert it changes in
 * one of the two.
 *
 * The same goes for `style={{ }}`: it is the cascade this project took out of the way, coming back
 * one attribute at a time, and it is the one style a Tailwind utility cannot override.
 *
 * This one passes on an empty `src/`, and that is fine: it is a guard, not a demonstration. It
 * starts doing work the first time somebody writes a screen -- which is this feature.
 */

import { describe, expect, it } from 'vitest';

/** Every TypeScript source of the application, as text. */
const SOURCES = import.meta.glob<string>('../src/**/*.{ts,tsx}', {
  query: '?raw',
  import: 'default',
  eager: true,
});

/** `#rrggbb`, `rgb(...)` and `hsl(...)`: the three ways a colour gets written by hand. */
const A_COLOUR = /#[0-9a-fA-F]{3,8}\b|rgb\(|hsl\(/;

/** An inline style attribute, whatever it carries. */
const AN_INLINE_STYLE = /style=\{\{/;

/**
 * Where a pattern shows up, as `path:line: the line`.
 *
 * `src/styles/` is excluded because that is where the palette is defined: it is the one file that
 * is *supposed* to name colours.
 */
function occurrencesOf(pattern: RegExp): string[] {
  const found: string[] = [];

  for (const [path, contents] of Object.entries(SOURCES)) {
    if (path.includes('/styles/')) continue;

    contents.split('\n').forEach((line, index) => {
      if (pattern.test(line)) {
        found.push(`${path}:${index + 1}: ${line.trim()}`);
      }
    });
  }

  return found;
}

describe('the palette of the application', () => {
  it('is not written by hand in any component', () => {
    const offenders = occurrencesOf(A_COLOUR);

    expect(
      offenders,
      `a colour belongs in the @theme block of src/styles/tokens.css:\n${offenders.join('\n')}`,
    ).toHaveLength(0);
  });
});

describe('the styles of the application', () => {
  it('are utilities and never an inline style attribute', () => {
    const offenders = occurrencesOf(AN_INLINE_STYLE);

    expect(
      offenders,
      `an inline style is a second cascade, and it wins by accident:\n${offenders.join('\n')}`,
    ).toHaveLength(0);
  });
});
