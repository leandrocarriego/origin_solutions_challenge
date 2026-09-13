"""Alembic environment.

This file is allowed to import from app.modules, and it is the only place outside main.py that
is: GEN-03 keeps the kernel and the providers from importing a module, but Alembic needs every
model registered against a single metadata to order a single chain of migrations. It plays the
same role main.py does -- a composition root -- for the schema rather than for the routes.

The URL comes from Settings and never from alembic.ini. Writing it in the ini would mean a
second place where the DSN lives, and the second place is the one that goes stale (SEC-03).
"""

import asyncio
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

from app.db import Base
from app.settings import get_settings

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

config.set_main_option("sqlalchemy.url", get_settings().database_url)

# Importing the modules is what registers their tables on Base.metadata. Without this the
# autogenerate would see an empty schema and cheerfully write a migration that drops everything.
# Each module is added here when it is created; there are none yet.
target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Emit SQL to stdout instead of running it, for review or for a DBA."""
    context.configure(
        url=config.get_main_option("sqlalchemy.url"),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    """Run the migrations on an already-open connection."""
    # compare_type and compare_server_default make autogenerate notice a column whose type or
    # default changed, which it ignores by default and which is exactly how a model and its
    # table drift apart without anyone seeing it (DB-01).
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,
        compare_server_default=True,
    )

    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """Open an async engine and run the migrations through it."""
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_migrations_online() -> None:
    """Entry point for the online mode."""
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
