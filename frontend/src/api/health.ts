/** Client for the API's own status endpoint. */

/** What GET /api/health answers, in both the healthy and the degraded case. */
export interface HealthStatus {
  status: string;
  database: string;
  version: string;
}

/**
 * Ask our own API how it is doing.
 *
 * A 503 is not an error here: it is the degraded answer, and it carries the same body as the
 * healthy one. Only a network failure rejects, which is what lets the page tell "the backend
 * is down" apart from "the backend is up and honest about a broken dependency".
 */
export async function fetchHealth(): Promise<HealthStatus> {
  const response = await fetch('/api/health');
  return (await response.json()) as HealthStatus;
}
