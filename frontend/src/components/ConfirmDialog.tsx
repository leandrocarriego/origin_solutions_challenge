/**
 * The confirmation of a removal -- `¿Quitar {símbolo} de tus acciones?` (RF-25, RF-32).
 *
 * It is ours and not `window.confirm()`: the browser labels its buttons `Aceptar` and `Cancelar`
 * and does not let anybody change them, and `COPY.md` asks for `Eliminar` and `Cancelar` (UI-02).
 *
 * It is a native `<dialog>` opened with `showModal()`, which is what puts it in the top layer,
 * traps the focus inside it and makes `Escape` close it -- three things a `<div>` with a backdrop
 * only imitates. None of the three can be exercised in jsdom, which implements none of them:
 * `tests/setup.ts` shims `showModal()` so the component can be tested at all, and says there that
 * those three are verified by hand against a browser instead.
 *
 * The symbol is named in the question on purpose: it is what lets somebody notice they activated
 * the wrong row (`COPY.md` → *Lista de favoritas*).
 */

import { useEffect, useRef, type JSX } from 'react';

/** Verbatim from the *Lista de favoritas* table of docs/design/COPY.md (UI-02). */
const CONFIRM = 'Eliminar';
const CANCEL = 'Cancelar';

/** The question, with the symbol of the row that is about to go (`COPY.md`). */
function questionFor(symbol: string): string {
  return `¿Quitar ${symbol} de tus acciones?`;
}

interface ConfirmDialogProps {
  /** The symbol being removed, which the question names. */
  symbol: string;
  onConfirm: () => void;
  onCancel: () => void;
}

export function ConfirmDialog({ symbol, onConfirm, onCancel }: ConfirmDialogProps): JSX.Element {
  const dialog = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    // Opened from an effect because `showModal()` is a call and not an attribute: rendering
    // `<dialog open>` instead would draw the same markup and leave it non-modal -- no top layer,
    // no trapped focus, no `Escape`.
    dialog.current?.showModal();
  }, []);

  return (
    <dialog
      ref={dialog}
      // `Escape` closes a modal dialog on its own, and the screen has to hear about it: without
      // this, the dialog would be gone and the state behind it would still think it is open.
      onCancel={onCancel}
      className="rounded-sm border border-border bg-surface p-6 text-text"
    >
      <p className="m-0">{questionFor(symbol)}</p>

      <div className="mt-4 flex justify-end gap-3">
        <button
          type="button"
          onClick={onCancel}
          className="rounded-sm border border-border bg-surface px-4 py-1"
        >
          {CANCEL}
        </button>

        <button
          type="button"
          onClick={onConfirm}
          className="rounded-sm border border-border bg-surface-muted px-4 py-1"
        >
          {CONFIRM}
        </button>
      </div>
    </dialog>
  );
}
