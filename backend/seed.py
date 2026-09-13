"""Loads the minimum dataset needed to exercise the application (REQ-19).

Runs from the container entrypoint when SEED_ON_START is true, which only the local compose
sets. It is never a default: the users it creates have passwords that live in this repository,
so a seeded production database is a production database with known credentials.

Idempotent by construction. It runs on every `make up`, and a seed that fails the second time
is a seed nobody runs.

It reads the schema before writing: what it can insert depends on which tables the migrations
have created. The dataset itself arrives with the tables it needs, which are the four of
ADR-001 -- that decision is still unsigned, so today the schema check is all there is to run.
"""

import asyncio
import sys

from sqlalchemy import inspect

from app.db import engine
from app.settings import get_settings

# The tables the dataset writes into. ADR-001 defines them; the migration creates them.
REQUIRED_TABLES = ("users", "stocks", "user_stocks")


async def existing_tables() -> set[str]:
    """Names of the tables the database actually has right now."""
    async with engine.connect() as connection:
        return set(await connection.run_sync(lambda sync: inspect(sync).get_table_names()))


def refuses_to_run() -> str | None:
    """Why this must not run here, or None when it is safe."""
    if get_settings().sentry_environment == "production":
        return "environment is production: the seed creates users with published passwords"
    return None


async def run() -> int:
    """Seed the database and report what happened."""
    refusal = refuses_to_run()
    if refusal:
        print(f"seed: refusing -- {refusal}", file=sys.stderr)
        return 1

    present = await existing_tables()
    missing = [table for table in REQUIRED_TABLES if table not in present]
    if missing:
        print(f"seed: nothing to load, no schema yet (missing: {', '.join(missing)})")
        return 0

    print("seed: schema present")
    return 0


def main() -> int:
    """Entry point for `python seed.py`."""
    try:
        return asyncio.run(run())
    finally:
        asyncio.run(engine.dispose())


if __name__ == "__main__":
    sys.exit(main())
