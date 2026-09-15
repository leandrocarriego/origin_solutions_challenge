// The load test that turns Article II from a claim into a measurement.
//
// The claim is that the provider's quota is spent on *symbols observed*, never on *clients
// connected*: fifty people watching TSLA have to cost the same as one. Everything else in the
// repository argues for it -- the cache, the gate, the TTL, a dashboard -- but every one of those
// is the system describing itself. This is the only thing here that puts concurrent load on the
// running application and then reads what it cost.
//
// So the assertion is not "it was fast". It is: hundreds of requests went in, and the counter of
// calls that actually left for the provider moved by at most one. The counter is read from
// /metrics before and after, which is the same number the Grafana dashboard charts -- if this
// test passes, that panel is telling the truth.
//
// Run it with `make load`, against a stack that is already up.

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter } from 'k6/metrics';

const BASE = __ENV.BASE_URL || 'http://backend:8000';
const USER = __ENV.APP_USER || 'juan@demo.com';
const PASSWORD = __ENV.APP_PASSWORD || 'Demo1234*';
const SYMBOL = __ENV.SYMBOL || 'TSLA';
const INTERVAL = __ENV.INTERVAL || '5min';

// Every virtual user asks for the same symbol on purpose. Spreading them over different symbols
// would measure something real too, but not this: the point is that concurrency on one symbol is
// free, because the second reader is served what the first one already paid for.
export const options = {
  scenarios: {
    everyone_watching_the_same_symbol: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '15s', target: 50 },
        { duration: '60s', target: 50 },
        { duration: '10s', target: 0 },
      ],
      gracefulRampDown: '10s',
    },
  },
  thresholds: {
    // The SLOs of the README, asserted instead of hoped for.
    'http_req_duration{expected_response:true}': ['p(95)<300'],
    http_req_failed: ['rate<0.01'],
    // The one that matters: the quota is not consumed by the crowd.
    provider_calls_during_the_run: ['count<=1'],
  },
};

const providerCalls = new Counter('provider_calls_during_the_run');

/** Sum every `provider_requests_total{...,outcome="attempt"}` sample the endpoint exposes. */
function providerAttempts() {
  const body = http.get(`${BASE}/metrics`).body;
  let total = 0;

  for (const line of body.split('\n')) {
    if (line.startsWith('provider_requests_total{') && line.includes('outcome="attempt"')) {
      total += Number(line.slice(line.lastIndexOf(' ') + 1));
    }
  }

  return total;
}

export function setup() {
  const logged = http.post(
    `${BASE}/api/auth/login`,
    JSON.stringify({ username: USER, password: PASSWORD }),
    { headers: { 'Content-Type': 'application/json' } },
  );

  if (logged.status !== 200) {
    throw new Error(`no se pudo iniciar sesión (${logged.status}). ¿Está levantado el stack?`);
  }

  return { token: logged.json('access_token'), attemptsBefore: providerAttempts() };
}

export default function (data) {
  const response = http.get(`${BASE}/api/quotes/${SYMBOL}?interval=${INTERVAL}&mode=realtime`, {
    headers: { Authorization: `Bearer ${data.token}` },
    tags: { name: 'GET /api/quotes/{symbol}' },
  });

  check(response, {
    'responde 200': (r) => r.status === 200,
    'trae puntos para graficar': (r) => (r.json('points') || []).length > 0,
    'no nombra al proveedor': (r) => !r.body.toLowerCase().includes('twelvedata'),
  });

  // What the chart does while somebody looks at it: one poll per interval, not a tight loop.
  sleep(1);
}

export function teardown(data) {
  const spent = providerAttempts() - data.attemptsBefore;

  providerCalls.add(spent);

  console.log(`llamadas al proveedor durante la corrida: ${spent}`);
}
