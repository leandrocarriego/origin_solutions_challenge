import '@testing-library/jest-dom/vitest';

import { cleanup } from '@testing-library/react';
import { afterEach, vi } from 'vitest';

/*
 * `HTMLDialogElement.showModal()` in jsdom, which does not implement it.
 *
 * jsdom 30 exposes the `open` property and the UA `display: none`, and nothing else:
 * `showModal`, `show` and `close` are all `undefined`. Without this, a `ConfirmDialog` that opens
 * the way the platform says to open one -- `dialogRef.current.showModal()`, which is what puts
 * the dialog in the top layer, traps the focus and makes `Escape` close it -- throws in every
 * test that opens it.
 *
 * The shim lives here and not in `src/` on purpose (decision of the human, 2026-09-14). The
 * alternative was to feature-detect inside the component and fall back to the `open` attribute,
 * which would mean a real modal for nobody and a branch in production code whose only reason is
 * the test environment. `plan.md` asks for a modal with trapped focus and `Escape`; the component
 * delivers exactly that in a browser, and the limitation of the runner is declared right here.
 *
 * What it does NOT emulate, and no test may claim: the top layer, the focus trap, `Escape`, and
 * the backdrop. jsdom has none of them, so those are verified by hand against a browser and not
 * by this suite.
 */
const dialog = globalThis.HTMLDialogElement?.prototype as HTMLDialogElement | undefined;

if (dialog && typeof dialog.showModal !== 'function') {
  dialog.show = function show(this: HTMLDialogElement): void {
    this.open = true;
  };

  dialog.showModal = function showModal(this: HTMLDialogElement): void {
    this.open = true;
  };

  dialog.close = function close(this: HTMLDialogElement, returnValue?: string): void {
    this.open = false;
    if (returnValue !== undefined) this.returnValue = returnValue;
    this.dispatchEvent(new Event('close'));
  };
}

afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
});
