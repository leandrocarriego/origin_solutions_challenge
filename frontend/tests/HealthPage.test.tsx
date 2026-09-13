/**
 * The health page: what someone opens to find out whether the deployment is alive.
 *
 * It is the frontend half of the backend's /api/health, and it exists for the same reason:
 * answering "is this thing up?" without an SSH session. TS-06 is what most of this file is
 * about — loading, error and empty are states, not afterthoughts.
 */

import { render, screen, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { HealthPage } from '../src/pages/HealthPage';

const OK_RESPONSE = { status: 'ok', database: 'ok', version: '1.4.2' };
const DEGRADED_RESPONSE = { status: 'degraded', database: 'unavailable', version: '1.4.2' };

/** Reply to fetch with a body and a status, the way the API would. */
function respondWith(body: unknown, status = 200): void {
  vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response(JSON.stringify(body), { status })));
}

/** Leave fetch pending forever, so the loading state can be observed. */
function neverResolve(): void {
  vi.stubGlobal('fetch', vi.fn().mockReturnValue(new Promise(() => {})));
}

beforeEach(() => {
  vi.unstubAllGlobals();
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe('HealthPage while it is loading', () => {
  it('shows that it is checking, instead of an empty screen', async () => {
    neverResolve();

    render(<HealthPage />);

    expect(await screen.findByText(/verificando/i)).toBeInTheDocument();
  });
});

describe('HealthPage when the API is healthy', () => {
  it('reports the service as operational', async () => {
    respondWith(OK_RESPONSE);

    render(<HealthPage />);

    expect(await screen.findByText(/operativo/i)).toBeInTheDocument();
  });

  it('shows the version that is running', async () => {
    respondWith(OK_RESPONSE);

    render(<HealthPage />);

    expect(await screen.findByText('1.4.2')).toBeInTheDocument();
  });

  it('shows the state of the database as its own line', async () => {
    // The page reports each dependency separately: "everything is fine" is not diagnosable.
    respondWith(OK_RESPONSE);

    render(<HealthPage />);

    expect(await screen.findByTestId('health-database')).toHaveTextContent(/ok/i);
  });
});

describe('HealthPage when the API is degraded', () => {
  it('reports the degraded state instead of treating 503 as a crash', async () => {
    // A 503 from health is a valid answer that carries information, not a failed request.
    respondWith(DEGRADED_RESPONSE, 503);

    render(<HealthPage />);

    expect(await screen.findByText(/degradado/i)).toBeInTheDocument();
  });

  it('says which dependency is down', async () => {
    respondWith(DEGRADED_RESPONSE, 503);

    render(<HealthPage />);

    expect(await screen.findByTestId('health-database')).toHaveTextContent(/no disponible/i);
  });
});

describe('HealthPage when the API cannot be reached', () => {
  it('shows an error instead of staying on the loading state forever', async () => {
    // The network failing is different from the API answering "degraded", and the page has to
    // tell them apart: one means the backend is down, the other that it is up and honest.
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new TypeError('Failed to fetch')));

    render(<HealthPage />);

    expect(await screen.findByRole('alert')).toBeInTheDocument();
  });

  it('never shows a raw exception message to the user', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new TypeError('Failed to fetch')));

    render(<HealthPage />);

    const alert = await screen.findByRole('alert');
    expect(alert).not.toHaveTextContent(/failed to fetch/i);
    expect(alert).not.toHaveTextContent(/TypeError/i);
  });
});

describe('HealthPage and the provider', () => {
  it('asks our own API and never the provider directly', async () => {
    // Article I and II: the browser does not know the provider's domain and never spends quota.
    respondWith(OK_RESPONSE);

    render(<HealthPage />);

    await waitFor(() => expect(fetch).toHaveBeenCalled());
    const [url] = vi.mocked(fetch).mock.calls[0] ?? [];
    expect(url).toBe('/api/health');
  });

  it('sends no credentials of any kind', async () => {
    respondWith(OK_RESPONSE);

    render(<HealthPage />);

    await waitFor(() => expect(fetch).toHaveBeenCalled());
    const [, init] = vi.mocked(fetch).mock.calls[0] ?? [];
    const headers = new Headers(init?.headers);
    expect(headers.get('authorization')).toBeNull();
    expect(headers.has('x-api-key')).toBe(false);
  });
});
