/** Browser entry point. */

import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';

import { HealthPage } from './pages/HealthPage';
import './styles/tokens.css';

const container = document.getElementById('root');
if (!container) throw new Error('missing #root');

createRoot(container).render(
  <StrictMode>
    <HealthPage />
  </StrictMode>,
);
