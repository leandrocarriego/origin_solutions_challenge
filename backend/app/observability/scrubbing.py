"""Blanking a credential out of anything that is about to leave the process.

Text rules and nothing else: no reporter, no transport, no vendor. Whoever is carrying the event
away is the caller's business, and the day that changes the redaction stays.

Three passes, because a credential travels in three shapes. Two are matched by shape, so an
unknown or rotated value is caught anyway; the third is the literal, which is the only thing that
covers a value no pattern describes.
"""

import re
from typing import Any

REDACTED = "[redacted]"

# The credential-carrying query parameters, matched by shape.
SECRET_PARAM = re.compile(
    r"(?i)\b(apikey|api_key|token|password|secret|authorization)=([^&\s\"']+)"
)

# The password inside any connection string, whether or not this process configured it.
DSN_PASSWORD = re.compile(r"(://[^:/@\s]+:)([^@\s]+)(@)")


def scrub(value: Any, secrets: tuple[str, ...]) -> Any:
    """Walk any nested structure and blank out every secret it carries."""
    if isinstance(value, str):
        cleaned = SECRET_PARAM.sub(rf"\1={REDACTED}", value)
        cleaned = DSN_PASSWORD.sub(rf"\1{REDACTED}\3", cleaned)

        for secret in secrets:
            cleaned = cleaned.replace(secret, REDACTED)

        return cleaned

    if isinstance(value, dict):
        return {key: scrub(item, secrets) for key, item in value.items()}

    if isinstance(value, list):
        return [scrub(item, secrets) for item in value]

    if isinstance(value, tuple):
        return tuple(scrub(item, secrets) for item in value)

    return value
