/**
 * The session, as the rest of the application sees it.
 *
 * It survives a reload: what the browser kept is read at start-up and confirmed against our own
 * API, because only the API can say whether a signed token is still any good. That question takes
 * a moment, and `loading` is that moment -- without it a reload paints the login for a frame and
 * then leaves it, which reads as having been logged out and back in.
 *
 * Leaving is this file forgetting: `logOut` tells the server nothing, because there is nothing
 * there to tell. The token is signed and short-lived and the server keeps no list of the live ones
 * (`ADR-004`), so the session ends when the browser stops presenting it.
 */

import { createContext, useContext } from 'react';

/** Who is logged in, in the terms a screen uses. */
export interface SessionUser {
  fullName: string;
}

/**
 * Whether somebody is logged in, and the answer is not always known yet.
 *
 * `loading` is the start-up: there is a token kept from before and the API has not said whether it
 * still accepts it. Nothing that depends on the answer may be drawn while this is the state.
 */
export type SessionStatus = 'loading' | 'authenticated' | 'anonymous';

export interface Session {
  status: SessionStatus;
  user: SessionUser | null;
  /** The credential every later call travels with. Nothing reads it until an inner screen calls. */
  token: string | null;
  /**
   * Whether the login is being looked at because a session ended, and not because none was started.
   *
   * RF-17: landing on the login in silence reads as the application having lost the session by
   * mistake. It is the one thing that tells the two arrivals apart, so the screen can say which.
   */
  expired: boolean;
  /** Resolves with the session in place, or throws what the API refused with. */
  logIn: (username: string, password: string) => Promise<void>;
  /**
   * End the session and go back to the login (RF-19, RF-20).
   *
   * Synchronous, and that is the point: there is no round trip to wait for and none to fail. A way
   * out that could fail is a way out that can strand somebody inside somebody else's account.
   */
  logOut: () => void;
}

export const SessionContext = createContext<Session | null>(null);

/** The session of the surrounding provider, or a loud failure if there is none. */
export function useSession(): Session {
  const session = useContext(SessionContext);
  if (!session) throw new Error('useSession was called outside of a SessionProvider');

  return session;
}
