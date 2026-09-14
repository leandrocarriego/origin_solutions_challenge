/** Browser entry point. */

import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router';

import { App } from './App';
import './styles/tokens.css';

const container = document.getElementById('root');
if (!container) throw new Error('missing #root');

// The router lives here, around <App />, and not inside it: a test then supplies its own and can
// open the application at any address (plan.md -> Frontend).
createRoot(container).render(
  <StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </StrictMode>,
);
