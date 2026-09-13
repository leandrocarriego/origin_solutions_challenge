/**
 * Operational page: whether the deployment is alive, and which build is serving.
 *
 * Not a wireframe page. It exists for the same reason as the backend's /api/health: answering
 * "is this thing up?" without an SSH session. Its copy is ours, not the brief's, because the
 * brief does not ask for this screen.
 */

import { useEffect, useState, type JSX } from 'react';

import { fetchHealth, type HealthStatus } from '../api/health';
import './HealthPage.css';

type Phase =
  { kind: 'checking' } | { kind: 'answered'; health: HealthStatus } | { kind: 'unreachable' };

/** Turn the API's machine words into the ones a person reads. */
function describeDatabase(database: string): { label: string; tone: string } {
  return database === 'ok'
    ? { label: 'OK', tone: 'ok' }
    : { label: 'No disponible', tone: 'error' };
}

/** Turn the overall status into a headline and its tone. */
function describeService(status: string): { label: string; tone: string } {
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
    <main className="health">
      <h1 className="health__title">Estado del servicio</h1>

      {phase.kind === 'checking' && <p className="health__muted">Verificando…</p>}

      {phase.kind === 'unreachable' && (
        <p role="alert" className="health__alert">
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
    <dl className="health__list">
      <div className="health__row">
        <dt>Servicio</dt>
        <dd className={`health__value health__value--${service.tone}`}>{service.label}</dd>
      </div>

      <div className="health__row">
        <dt>Base de datos</dt>
        <dd
          data-testid="health-database"
          className={`health__value health__value--${database.tone}`}
        >
          {database.label}
        </dd>
      </div>

      <div className="health__row">
        <dt>Versión</dt>
        <dd className="health__value health__value--mono">{health.version}</dd>
      </div>
    </dl>
  );
}
