/**
 * The login screen -- wireframe 01 (RF-01 to RF-05, RF-12, RF-13, RF-23).
 *
 * Two fields and a button, in that order, and nothing else: the wireframe draws no page title and
 * no logo, so neither is added (UI-01). Every text is a literal of `docs/design/COPY.md`, verbatim
 * and with the misspelling the brief wrote (UI-02).
 *
 * The four notices are exclusive and ordered, and the copy is explicit about it: an empty field is
 * a slip and never reaches the API; the attempt limit is answered without looking at the
 * credential; not having been able to reach the server at all says nothing about the credential
 * either (`RF-27`); and `usuario o clave invalida` is left for when none of the three applies,
 * because it is the only one that asserts something about what the person typed.
 *
 * The screen is also where a session that ended is announced (`RF-17`). It is not one of the four:
 * it is about the session before this one, so it steps aside the moment the visitor tries again.
 */

import { useState, type FormEvent, type JSX } from 'react';
import { useNavigate } from 'react-router';

import { ApiError } from '../api/client';
import { useSession } from '../auth/session';

/** Which of the three notices an attempt that did not get in earns. */
type Refusal = 'bad-credential' | 'too-many-attempts' | 'unreachable';

/*
 * Verbatim from docs/design/COPY.md. `invalida` has no accent there, and it has none here: the
 * brief spells it that way and copying it is the requirement (UI-02, Article VII).
 */
const REFUSAL_TEXT: Record<Refusal, string> = {
  'bad-credential': 'usuario o clave invalida',
  'too-many-attempts': 'Demasiados intentos. Probá de nuevo en unos minutos.',
  unreachable: 'No pudimos conectarnos con el servidor. Intentá de nuevo en unos minutos.',
};

const EMPTY_FIELD = 'Completá este campo.';

const SESSION_EXPIRED = 'Tu sesión expiró. Volvé a ingresar.';

/**
 * How an attempt that did not get in is told to the visitor.
 *
 * Two of the three are about not having learnt anything. No `ApiError` means there was no answer
 * to read -- the request never reached our API -- so the credential was never checked, and blaming
 * it sends the visitor to change a password that was right (`RF-27`). The limit is the same
 * situation on purpose: while it holds, the answer is the same whether the password was right or
 * wrong, because saying which would hand back the fact the limit is withholding.
 *
 * `usuario o clave invalida` is what is left, and it is the only one that asserts something about
 * what the person typed.
 */
function refusalFor(error: unknown): Refusal {
  if (!(error instanceof ApiError)) return 'unreachable';

  return error.status === 429 ? 'too-many-attempts' : 'bad-credential';
}

export function Login(): JSX.Element {
  const { logIn, expired } = useSession();
  const navigate = useNavigate();

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [emptyFields, setEmptyFields] = useState({ username: false, password: false });
  const [refusal, setRefusal] = useState<Refusal | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function attempt(): Promise<void> {
    const empty = { username: username === '', password: password === '' };
    setEmptyFields(empty);
    setRefusal(null);

    // RF-13: a blank field is a slip, not a credential worth checking, so nothing is asked.
    if (empty.username || empty.password) return;

    setSubmitting(true);
    try {
      await logIn(username, password);
      await navigate('/', { replace: true });
    } catch (error) {
      setRefusal(refusalFor(error));
    } finally {
      setSubmitting(false);
    }
  }

  function onSubmit(event: FormEvent<HTMLFormElement>): void {
    event.preventDefault();
    void attempt();
  }

  const anyFieldEmpty = emptyFields.username || emptyFields.password;

  return (
    <main className="mx-auto my-8 max-w-md rounded-sm border border-border bg-surface p-8">
      {/* Why this screen is on view, above the form it is talking about (UI-05). It yields to any
          notice about the attempt just made: that one is the news, and the four are exclusive. */}
      {expired && !anyFieldEmpty && refusal === null && (
        <p role="alert" className="m-0 mb-4 text-warn">
          {SESSION_EXPIRED}
        </p>
      )}

      <form className="flex flex-col gap-4" onSubmit={onSubmit} noValidate>
        <Field
          id="username"
          label="Usuario"
          type="text"
          placeholder="Ingresar nombre de usuario"
          value={username}
          onChange={setUsername}
          empty={emptyFields.username}
        />

        <Field
          id="password"
          label="Clave"
          type="password"
          value={password}
          onChange={setPassword}
          empty={emptyFields.password}
        />

        {refusal && (
          <p role="alert" className="m-0 text-error">
            {REFUSAL_TEXT[refusal]}
          </p>
        )}

        <button
          type="submit"
          disabled={submitting}
          className="self-center rounded-sm border border-border bg-surface-muted px-6 py-2 disabled:opacity-60"
        >
          Ingresar
        </button>
      </form>
    </main>
  );
}

interface FieldProps {
  id: string;
  label: string;
  type: 'text' | 'password';
  placeholder?: string;
  value: string;
  onChange: (value: string) => void;
  empty: boolean;
}

/** One labelled field of the form, with the notice for when it was left empty underneath it. */
function Field({ id, label, type, placeholder, value, onChange, empty }: FieldProps): JSX.Element {
  const noticeId = `${id}-empty`;

  return (
    <div className="flex flex-col gap-1">
      <label htmlFor={id}>{label}</label>

      <input
        id={id}
        name={id}
        type={type}
        placeholder={placeholder}
        value={value}
        onChange={(event) => {
          onChange(event.target.value);
        }}
        aria-invalid={empty}
        aria-describedby={empty ? noticeId : undefined}
        className="rounded-sm border border-border bg-surface px-2 py-1"
      />

      {empty && (
        <p id={noticeId} role="alert" className="m-0 text-error">
          {EMPTY_FIELD}
        </p>
      )}
    </div>
  );
}
