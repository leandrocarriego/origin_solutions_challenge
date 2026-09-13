/**
 * Operational page: whether the deployment is alive, and which build is serving.
 *
 * Not a wireframe page. It exists for the same reason as the backend's /api/health: answering
 * "is this thing up?" without an SSH session. Its copy is ours, not the brief's, because the
 * brief does not ask for this screen.
 */

import { useEffect, useState, type JSX } from 'react';

import { fetchHealth, type HealthStatus } from '../api/health';

type Phase =
  { kind: 'checking' } | { kind: 'answered'; health: HealthStatus } | { kind: 'unreachable' };

type Tone = 'ok' | 'warn' | 'error';

/*
 * Written out rather than built as `text-${tone}`: Tailwind scans the source as text, so a class
 * name that only exists once the code runs is a class name it never generates.
 */
const TONE_CLASS: Record<Tone, string> = {
  ok: 'text-ok',
  warn: 'text-warn',
  error: 'text-error',
};

/** Turn the API's machine words into the ones a person reads. */
function describeDatabase(database: string): { label: string; tone: Tone } {
  return database === 'ok'
    ? { label: 'OK', tone: 'ok' }
    : { label: 'No disponible', tone: 'error' };
}

/** Turn the overall status into a headline and its tone. */
function describeService(status: string): { label: string; tone: Tone } {
  return status === 'ok'
    ? { label: 'Operativo', tone: 'ok' }
    : { label: 'Degradado', tone: 'warn' };
}

export function HealthPage(): JSX.Element {
  const [phase, setPhase] = useState<Phase>({ kind: 'checking' });

  useEffect(() => {
    let active = true;

    fetchHealth()
      .then((health) => {
        if (active) setPhase({ kind: 'answered', health });
      })
      .catch(() => {
        // The exception text stays here: a TypeError on screen is an internal detail leaking
        // to someone who cannot act on it (ERR-02).
        if (active) setPhase({ kind: 'unreachable' });
      });

    return () => {
      active = false;
    };
  }, []);

  return (
    <main className="mx-auto my-8 max-w-lg rounded-sm border border-border bg-surface p-6">
      <h1 className="mb-6 text-lg font-bold">Estado del servicio</h1>

      {phase.kind === 'checking' && <p className="text-text-muted">Verificando…</p>}

      {phase.kind === 'unreachable' && (
        <p role="alert" className="m-0 rounded-sm border border-error bg-surface p-4 text-error">
          No se pudo contactar a la API. Puede estar reiniciando o fuera de servicio.
        </p>
      )}

      {phase.kind === 'answered' && <HealthReport health={phase.health} />}
    </main>
  );
}

/** The answer, one dependency per row: "everything is fine" is not diagnosable. */
function HealthReport({ health }: { health: HealthStatus }): JSX.Element {
  const service = describeService(health.status);
  const database = describeDatabase(health.database);

  return (
    <dl className="m-0">
      <Row label="Servicio">
        <dd className={`m-0 font-semibold ${TONE_CLASS[service.tone]}`}>{service.label}</dd>
      </Row>

      <Row label="Base de datos">
        <dd
          data-testid="health-database"
          className={`m-0 font-semibold ${TONE_CLASS[database.tone]}`}
        >
          {database.label}
        </dd>
      </Row>

      <Row label="Versión">
        {/* UI-04: the version is an identifier, so it lines up in mono. */}
        <dd className="m-0 font-mono tabular-nums">{health.version}</dd>
      </Row>
    </dl>
  );
}

/** One line of the report: the name on the left, the value on the right. */
function Row({ label, children }: { label: string; children: JSX.Element }): JSX.Element {
  return (
    <div className="flex justify-between gap-4 border-b border-border py-2 last:border-b-0">
      <dt className="text-text-muted">{label}</dt>
      {children}
    </div>
  );
}
