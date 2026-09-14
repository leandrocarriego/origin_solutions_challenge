/**
 * The application: the session around it, and the routes inside it.
 *
 * The `Router` is not here -- it wraps `<App />` in `main.tsx`. That is what lets a test open the
 * application at an address instead of assembling a screen by hand, and RF-09 is written as an
 * address pasted into a browser, so it has to be verifiable as one.
 *
 * `/` is `Mis Acciones` on purpose: the brief gives no addresses, and translating the name of the
 * screen to a slug means choosing between spanglish and a name nobody uses.
 */

import type { JSX } from 'react';
import { Navigate, Route, Routes } from 'react-router';

import { RequireSession } from './auth/RequireSession';
import { SessionProvider } from './auth/SessionProvider';
import { HealthPage } from './pages/HealthPage';
import { Login } from './pages/Login';
import { MyActions } from './pages/MyActions';

export function App(): JSX.Element {
  return (
    <SessionProvider>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route
          path="/"
          element={
            <RequireSession>
              <MyActions />
            </RequireSession>
          }
        />
        {/* Operational, and not one of the three screens of the brief: it hangs off its own
            address and stays public, because it answers "is this thing up?". */}
        <Route path="/health" element={<HealthPage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </SessionProvider>
  );
}
