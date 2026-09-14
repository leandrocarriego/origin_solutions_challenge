/**
 * What the browser keeps of a session, so that a reload does not throw it away.
 *
 * `sessionStorage` and not `localStorage`, which `ADR-004` decided and this file does not reopen:
 * the session dies with the tab, and "recordarme" is out of scope. Three things are kept -- the
 * token, the name to paint, and when the token stops being worth presenting -- under a single key,
 * because a session written in three pieces can be read back as half a session.
 *
 * Everything here is defensive on the way in and silent on the way out. `sessionStorage` throws
 * outright in a browser with site data blocked, and what it hands back was written by a previous
 * version of this application, by another tab, or by somebody typing into a console. A session that
 * cannot be read is simply a visitor who is not logged in, which is a state the application already
 * knows how to be in.
 */

/** The one key. Namespaced, because the origin is shared with whatever else is served from it. */
const KEY = 'origin-acciones.session';

/** A session as the browser keeps it between one page and the next. */
export interface StoredSession {
  token: string;
  fullName: string;
  /** Epoch milliseconds at which the token stops being accepted, from the login's `expires_in`. */
  expiresAt: number;
}

/** Whether what came back out of the storage is a session and not somebody else's leftovers. */
function isStoredSession(value: unknown): value is StoredSession {
  if (typeof value !== 'object' || value === null) return false;

  const candidate = value as Record<string, unknown>;

  return (
    typeof candidate.token === 'string' &&
    typeof candidate.fullName === 'string' &&
    typeof candidate.expiresAt === 'number' &&
    Number.isFinite(candidate.expiresAt)
  );
}

/** The session the browser kept, or `null` if there is none, it is unreadable, or it is garbage. */
export function readStoredSession(): StoredSession | null {
  try {
    const raw = sessionStorage.getItem(KEY);
    if (raw === null) return null;

    const parsed: unknown = JSON.parse(raw);

    return isStoredSession(parsed) ? parsed : null;
  } catch {
    // Unreadable storage, or something that is not JSON: either way there is no session.
    return null;
  }
}

/** Keep this session for the next page. */
export function writeStoredSession(session: StoredSession): void {
  try {
    sessionStorage.setItem(KEY, JSON.stringify(session));
  } catch {
    // Storage that refuses to be written costs the visitor a reload, not the session in hand.
  }
}

/** Forget whatever was kept. Called on an expiry, and it has to work even if nothing was there. */
export function clearStoredSession(): void {
  try {
    sessionStorage.removeItem(KEY);
  } catch {
    // Nothing to do about it, and nothing that depends on it having worked.
  }
}
