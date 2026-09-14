"""Authentication: the login, and the users it checks a credential against.

The contract is the router and nothing else. No other module authenticates anybody, and the
identity every other router needs is a primitive of the kernel, not a capability of this one.
"""

from app.modules.auth.router import router

__all__ = ["router"]
