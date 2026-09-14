/**
 * The `Símbolo` field of wireframe 02 and its dropdown (RF-08 to RF-14, RF-31).
 *
 * It is an `input` with a list of its own and not a `<select>`: the wireframe draws a text field
 * with an arrow and the placeholder `(Autocomplete)`, and a `select` cannot be typed into, which
 * is the whole point (UI-01).
 *
 * The dropdown is a `listbox` of `option`s, which is what a screen reader announces and what makes
 * a suggestion something a person can reach. It matters here more than usual: the same symbol is
 * also a row of the grid below, and the role is what tells the two apart.
 *
 * **Two searches never paint over each other.** Each one carries its own `AbortController` and
 * cancels the one before it, because answers that come back out of order would otherwise leave the
 * suggestions of a text that is no longer in the field -- a race that happens every time somebody
 * types fast and reproduces only sometimes.
 *
 * The debounce of 250 ms is a courtesy to our own server, not a defence of the provider's quota:
 * this search never leaves our API (Article II).
 */

import { useEffect, useRef, useState, type JSX } from 'react';

import { searchStocks, type StockSuggestion } from '../api/stocks';

/** Verbatim from the `Mis Acciones` table of docs/design/COPY.md (UI-02). */
const LABEL = 'Símbolo';
const PLACEHOLDER = '(Autocomplete)';

/** Verbatim from the *Lista de favoritas* table of docs/design/COPY.md (UI-02). */
const NO_MATCHES = 'No se encontró ninguna acción con ese texto.';

/** RF-13: below this, nothing is asked and nothing is offered. */
const MIN_QUERY_LENGTH = 2;

/** How long the field waits after the last keystroke before asking. */
const DEBOUNCE_MS = 250;

interface AutocompleteProps {
  /** Told what was chosen, or `null` the moment the text stops being what was chosen. */
  onChoose: (suggestion: StockSuggestion | null) => void;
  /** Fired when the addition is triggered from the field itself, with the Enter key. */
  onSubmit: () => void;
}

export function Autocomplete({ onChoose, onSubmit }: AutocompleteProps): JSX.Element {
  const [text, setText] = useState('');
  const [suggestions, setSuggestions] = useState<StockSuggestion[] | null>(null);

  // The search in flight, so the next one can cancel it. A ref and not state: changing it must
  // not paint anything, and the cleanup below has to see the latest one.
  const inFlight = useRef<AbortController | null>(null);

  // The text `choose` put in the field, so the effect can tell it apart from a keystroke. Without
  // it, choosing a suggestion changes `text` like any other edit and the search fires again: the
  // dropdown `choose` just closed reopens 250 ms later, showing the symbol that was already
  // picked. A ref and not state because it must not paint anything on its own.
  const chosen = useRef<string | null>(null);

  useEffect(() => {
    // The field holds what was chosen, not what somebody is typing: there is nothing to suggest
    // for an answer that was already given.
    if (text === chosen.current) return;

    // Nothing to ask: what is in the field is too short, and `typed` already put the dropdown
    // away. Clearing it here instead would be painting from an effect.
    if (text.trim().length < MIN_QUERY_LENGTH) return;

    const waiting = setTimeout(() => {
      inFlight.current?.abort();
      const controller = new AbortController();
      inFlight.current = controller;

      void (async (): Promise<void> => {
        try {
          const found = await searchStocks(text.trim(), controller.signal);
          // The guard is what makes the race harmless: an answer that arrives after its search
          // was replaced is not the answer to what is in the field.
          if (!controller.signal.aborted) setSuggestions(found);
        } catch {
          // An abort lands here and means nothing; anything else leaves the dropdown as it was
          // rather than announcing "nothing matched", which would not be true.
        }
      })();
    }, DEBOUNCE_MS);

    return () => {
      clearTimeout(waiting);
    };
  }, [text]);

  function typed(value: string): void {
    // Typing is what makes the field stop being the choice, and the search has to happen again
    // even if the keystrokes land back on the very symbol that was picked.
    chosen.current = null;
    setText(value);
    // RF-13 from the other side: below the minimum there is nothing to show, and a dropdown left
    // over from a longer text would be answering a question nobody is asking any more.
    if (value.trim().length < MIN_QUERY_LENGTH) setSuggestions(null);
    // What is in the field stopped being what was chosen, so the choice is gone: otherwise
    // somebody who edits the text after choosing adds whatever they had picked before.
    onChoose(null);
  }

  function choose(suggestion: StockSuggestion): void {
    chosen.current = suggestion.symbol;
    setText(suggestion.symbol);
    setSuggestions(null);
    onChoose(suggestion);
  }

  return (
    <div className="relative flex items-center gap-2">
      <label htmlFor="symbol">{LABEL}</label>

      <input
        id="symbol"
        name="symbol"
        type="text"
        role="combobox"
        aria-expanded={suggestions !== null}
        aria-controls="symbol-suggestions"
        autoComplete="off"
        placeholder={PLACEHOLDER}
        value={text}
        onChange={(event) => {
          typed(event.target.value);
        }}
        onKeyDown={(event) => {
          if (event.key !== 'Enter') return;
          // The field is not inside a form, so Enter does nothing on its own. It is the second
          // way of firing the addition, and the screen decides what that means (RF-20, RF-21).
          event.preventDefault();
          onSubmit();
        }}
        className="rounded-sm border border-border bg-surface px-2 py-1"
      />

      {suggestions !== null && (
        <ul
          id="symbol-suggestions"
          role="listbox"
          className="absolute top-full left-20 z-10 m-0 max-h-64 w-80 list-none overflow-y-auto border border-border bg-surface p-0"
        >
          {suggestions.length === 0 ? (
            <li className="px-2 py-1 text-text-muted">{NO_MATCHES}</li>
          ) : (
            suggestions.map((suggestion) => (
              <li key={suggestion.symbol}>
                <button
                  type="button"
                  role="option"
                  aria-selected={false}
                  onClick={() => {
                    choose(suggestion);
                  }}
                  className="w-full bg-transparent px-2 py-1 text-left"
                >
                  <span className="font-mono">{suggestion.symbol}</span> — {suggestion.name}
                </button>
              </li>
            ))
          )}
        </ul>
      )}
    </div>
  );
}
