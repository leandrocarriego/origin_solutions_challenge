/**
 * The guard on an inner screen (RF-09).
 *
 * It decides before rendering anything, and that is the whole point: a guard that shows the
 * screen and redirects afterwards leaks a frame of somebody's data to somebody who has no
 * session. Hiding a link is not a control either -- the real one is the backend's, and this only
 * saves the visitor from a screen that would answer 401 on every call.
 *
 * While the session is still being confirmed it draws nothing at all. Neither answer is known yet,
 * so both are wrong: the inner screen would be the leak above, and the login would be a frame of
 * "you are logged out" on a reload that ends with the visitor still inside.
 */

import { Navigate } from 'react-router';
import type { JSX, ReactNode } from 'react';

import { useSession } from './session';

export function RequireSession({ children }: { children: ReactNode }): JSX.Element {
  const { status } = useSession();

  if (status === 'loading') return <></>;
  if (status !== 'authenticated') return <Navigate to="/login" replace />;

  return <>{children}</>;
}
