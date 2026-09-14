/**
 * `Mis Acciones` -- wireframe 02: the `Símbolo` field, `Agregar Símbolo` and the grid.
 *
 * The list is not a prop anybody passes: it is what our API answers to `GET /api/favorites` for
 * the session that is logged in, asked for when the screen mounts. That is the half of RF-01 that
 * matters -- the grid shows the favourites of the identified user -- and it is also why nothing is
 * kept between mounts: a reload asks again, so the screen cannot end up painting the list of
 * whoever was logged in before.
 *
 * **The grid is asked for again after an addition** (RF-16), rather than the new row being pushed
 * onto the array in hand. The order of the grid is a decision of the backend (RF-06), and two
 * places that order it are one place that gets it wrong. It costs a request to our own API, which
 * spends nobody's quota (Article II).
 *
 * **The two notices are exclusive by construction**: one field that cannot hold two values at
 * once, which is what `COPY.md` asks for and what a test can verify. `Esa acción ya está en tu
 * lista.` is what a 200 from the addition means, and `Elegí una acción de las sugerencias.` is
 * for the addition fired with nothing chosen -- with the Enter key, since the button is disabled.
 *
 * **The removal is confirmed before it happens** (RF-25), and the grid is asked for again
 * afterwards for the same reason an addition is (RF-26). `Cancelar` leaves the action exactly
 * where it was (RF-32): the confirmation is a question, so nothing happens until it is answered.
 */

import { useCallback, useEffect, useState, type JSX } from 'react';

import { addFavorite, listFavorites, removeFavorite, type FavoriteItem } from '../api/favorites';
import type { StockSuggestion } from '../api/stocks';
import { Autocomplete } from '../components/Autocomplete';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { StockGrid } from '../components/StockGrid';
import { Header } from '../components/Header';

/** Verbatim from the `Mis Acciones` table of docs/design/COPY.md (UI-02). */
const ADD_BUTTON = 'Agregar Símbolo';

/** Verbatim from the *Lista de favoritas* table of docs/design/COPY.md (UI-02). */
const ALREADY_THERE = 'Esa acción ya está en tu lista.';
const NOTHING_CHOSEN = 'Elegí una acción de las sugerencias.';

/** Which of the two notices the field is showing, and it can only be one (RF-19, RF-21). */
type Notice = 'already-there' | 'no-selection';

const NOTICE_TEXT: Record<Notice, string> = {
  'already-there': ALREADY_THERE,
  'no-selection': NOTHING_CHOSEN,
};

/**
 * The favourites of the session, or `null` when our API did not answer with a list.
 *
 * A 401 already went through the session interceptor, which forgets the session and says why.
 * Anything else leaves the grid unpainted rather than showing something that is not the answer;
 * the notice for that is what `003` was asked for.
 */
async function theListOfTheSession(): Promise<FavoriteItem[] | null> {
  try {
    return await listFavorites();
  } catch {
    return null;
  }
}

export function MyActions(): JSX.Element {
  // `null` is "not asked yet or still asking", which is not the same as an empty list: the notice
  // of RF-07 must not flash while the answer is still on its way.
  const [favorites, setFavorites] = useState<FavoriteItem[] | null>(null);
  // RF-31: without a suggestion chosen there is nothing to add, and the button says so.
  const [selected, setSelected] = useState<StockSuggestion | null>(null);
  const [notice, setNotice] = useState<Notice | null>(null);
  // RF-25: the row that is about to be removed, and `null` when nothing was asked. Holding the
  // favourite and not a boolean is what lets the question name the symbol of *that* row.
  const [confirming, setConfirming] = useState<FavoriteItem | null>(null);

  const reloadTheGrid = useCallback(async (): Promise<void> => {
    setFavorites(await theListOfTheSession());
  }, []);

  useEffect(() => {
    let abandoned = false;

    void (async (): Promise<void> => {
      const list = await theListOfTheSession();
      // The screen may be gone by the time our API answers -- a logout, a reload -- and painting
      // then would be writing into a component nobody is looking at.
      if (!abandoned) setFavorites(list);
    })();

    return () => {
      abandoned = true;
    };
  }, []);

  async function add(): Promise<void> {
    if (selected === null) {
      // The button is disabled, so this is the addition fired from the field with Enter
      // (RF-20, RF-21): nothing is added, and the notice says what is missing.
      setNotice('no-selection');
      return;
    }

    try {
      const addition = await addFavorite(selected.symbol);
      // 200 and not 201: it was already on the list, and nothing was written (RF-18, RF-19).
      setNotice(addition.created ? null : 'already-there');
      await reloadTheGrid();
    } catch {
      // The catalogue refused it, or the call did not land. The grid stays as it was rather than
      // claiming an addition that did not happen.
      setNotice(null);
    }
  }

  async function remove(favorite: FavoriteItem): Promise<void> {
    // The question is answered, so it goes away first: a confirmation still on screen after being
    // answered reads as not having been heard.
    setConfirming(null);

    try {
      await removeFavorite(favorite.symbol);
      await reloadTheGrid();
    } catch {
      // The row stays where it is rather than disappearing from a removal that did not happen.
    }
  }

  return (
    <div className="mx-auto max-w-5xl px-6">
      <Header title="Mis Acciones" />

      <div className="flex flex-col gap-3 py-6">
        <div className="flex items-center gap-4">
          <Autocomplete
            onChoose={(suggestion) => {
              setSelected(suggestion);
              // What the notice said is about an addition that is no longer the one being made.
              setNotice(null);
            }}
            onSubmit={() => {
              void add();
            }}
          />

          <button
            type="button"
            disabled={selected === null}
            onClick={() => {
              void add();
            }}
            className="rounded-sm border border-border bg-surface-muted px-4 py-1 disabled:opacity-60"
          >
            {ADD_BUTTON}
          </button>
        </div>

        {notice !== null && <p className="m-0 text-warn">{NOTICE_TEXT[notice]}</p>}

        {favorites !== null && <StockGrid favorites={favorites} onRemove={setConfirming} />}
      </div>

      {confirming !== null && (
        <ConfirmDialog
          symbol={confirming.symbol}
          onConfirm={() => {
            void remove(confirming);
          }}
          onCancel={() => {
            setConfirming(null);
          }}
        />
      )}
    </div>
  );
}
