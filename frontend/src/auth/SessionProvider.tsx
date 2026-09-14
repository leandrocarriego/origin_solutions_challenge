/**
 * Holds the session, restores it after a reload, and reacts to the API refusing it.
 *
 * Three responsibilities, and they are here together because they are the same one seen from three
 * sides: this is the only place that decides whether there is a session.
 *
 * **The start-up.** What the browser kept is not a session, it is a claim: the token is signed and
 * only our API can say whether the signature and the hour still hold. So the provider starts in
 * `loading` with the kept name already in hand, asks `GET /api/auth/me`, and only then decides. The
 * kept session is held from the first render on purpose -- once the answer arrives there is nothing
 * left to paint, and the header does not appear a frame late.
 *
 * **The expiry.** A token whose hour has already passed is not worth a round trip: the API is going
 * to refuse it, and the visitor gets the same notice either way, sooner.
 *
 * **Leaving on purpose.** `logOut` forgets the three things a session is -- what the browser kept,
 * what this provider holds, and the address on screen -- and says nothing about an expiry, because
 * nothing expired. It asks the server nothing (`ADR-004`).
 *
 * **The interceptor.** Registered here, once, because the correction is a single one for the whole
 * application (`plan.md`): forget the session, say why, and go to the login. The login opts out of
 * it in `api/auth.ts` -- its 401 is a wrong credential and its 429 is the attempt limit, and
 * neither is a session that ended.
 *
 * **Where the token comes from.** Registered in that same effect, and it is the other half of the
 * same statement: this is the only place that knows whether there is a session, so it is the only
 * place that can say what an inner screen's call travels with. A screen that threaded the token
 * through every call would be the session scattered across the application.
 */

import { useCallback, useEffect, useMemo, useRef, useState, type JSX, type ReactNode } from 'react';
import { useNavigate } from 'react-router';

import { fetchMe, login } from '../api/auth';
import { setAuthTokenProvider, setUnauthorizedHandler } from '../api/client';
import { SessionContext, type Session, type SessionUser } from './session';
import { clearStoredSession, readStoredSession, writeStoredSession } from './storage';

/** What the provider holds between renders: nothing at all, or a token and who it belongs to. */
interface HeldSession {
  token: string;
  user: SessionUser;
}

/** What the browser had kept when this page started, read once and never again. */
type Startup =
  | { kind: 'nothing' }
  /** There was one, and its hour had already passed: the visitor is here because it ended. */
  | { kind: 'expired' }
  /** There is one worth presenting, and the API has not been asked about it yet. */
  | { kind: 'unconfirmed'; token: string; user: SessionUser };

function startupFromStorage(): Startup {
  const stored = readStoredSession();
  if (stored === null) return { kind: 'nothing' };
  if (stored.expiresAt <= Date.now()) return { kind: 'expired' };

  return { kind: 'unconfirmed', token: stored.token, user: { fullName: stored.fullName } };
}

export function SessionProvider({ children }: { children: ReactNode }): JSX.Element {
  const navigate = useNavigate();

  // Read on the first render and kept as state, so it is one reading of the storage for the life
  // of this mount and the start-up effect below runs exactly once.
  const [startup] = useState(startupFromStorage);

  const [held, setHeld] = useState<HeldSession | null>(
    startup.kind === 'unconfirmed' ? { token: startup.token, user: startup.user } : null,
  );
  // What the provider registered below reads. The effect that registers it runs once, so the
  // token cannot be captured: it has to be looked up at the moment the call goes out.
  const heldRef = useRef(held);

  const [confirming, setConfirming] = useState(startup.kind === 'unconfirmed');
  const [expired, setExpired] = useState(startup.kind === 'expired');

  useEffect(() => {
    heldRef.current = held;
  }, [held]);

  useEffect(() => {
    // Read through a ref of the latest value rather than captured: this effect runs once, and a
    // provider closed over the session of the first render would hand out a token from before
    // logging in -- which is no token at all.
    setAuthTokenProvider(() => heldRef.current?.token ?? null);

    setUnauthorizedHandler(() => {
      clearStoredSession();
      setHeld(null);
      setConfirming(false);
      setExpired(true);
      void navigate('/login', { replace: true });
    });

    return () => {
      setUnauthorizedHandler(null);
      setAuthTokenProvider(null);
    };
  }, [navigate]);

  useEffect(() => {
    if (startup.kind === 'expired') clearStoredSession();
    if (startup.kind !== 'unconfirmed') return;

    const { token } = startup;
    let abandoned = false;

    void (async (): Promise<void> => {
      try {
        const who = await fetchMe(token);
        // The name comes from the answer and not from what was kept: the API is the source.
        if (!abandoned) setHeld({ token, user: { fullName: who.full_name } });
      } catch {
        // A 401 already went through the interceptor, which is what says why. Anything else left
        // the token unconfirmed, and an unconfirmed token is not a session.
        clearStoredSession();
        if (!abandoned) setHeld(null);
      } finally {
        if (!abandoned) setConfirming(false);
      }
    })();

    return () => {
      abandoned = true;
    };
  }, [startup]);

  const logIn = useCallback(async (username: string, password: string): Promise<void> => {
    const session = await login(username, password);

    writeStoredSession({
      token: session.access_token,
      fullName: session.full_name,
      // `expires_in` is seconds, and the frontend holds no copy of the number itself.
      expiresAt: Date.now() + session.expires_in * 1000,
    });

    setHeld({ token: session.access_token, user: { fullName: session.full_name } });
    setConfirming(false);
    setExpired(false);
  }, []);

  const logOut = useCallback((): void => {
    clearStoredSession();
    setHeld(null);
    setConfirming(false);
    // Not an expiry: it was closed on purpose, so the login must not say the session ran out.
    setExpired(false);
    void navigate('/login', { replace: true });
  }, [navigate]);

  const value = useMemo<Session>(
    () => ({
      status: confirming ? 'loading' : held ? 'authenticated' : 'anonymous',
      user: held?.user ?? null,
      token: held?.token ?? null,
      expired,
      logIn,
      logOut,
    }),
    [confirming, held, expired, logIn, logOut],
  );

  return <SessionContext value={value}>{children}</SessionContext>;
}
