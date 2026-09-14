/**
 * The sliver of Node's API that the two convention suites use to read files.
 *
 * `copy.test.ts` has to read `docs/design/COPY.md`, which lives outside the frontend project, so
 * Vite refuses to serve it as a module and the only way in is the filesystem. The project has no
 * `@types/node` --- nothing in `src/` runs in Node --- and adding a dependency is not the
 * Tester's call, so what those tests use is declared here and nothing else is.
 *
 * If `@types/node` ever arrives, this file goes: the real declarations replace it.
 */

declare module 'node:fs' {
  export function readFileSync(path: string, encoding: 'utf8'): string;
}
