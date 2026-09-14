"""Authentication: the login, and the users it checks a credential against.

The contract is the router, and deliberately nothing else. No other module needs to authenticate
anybody -- `authenticate`, `AuthenticatedUser`, `find_by_username` and everything in
`schemas.py` are all internal -- and the identity every other router does need is a primitive of
the kernel (`from app.security import get_current_user, CurrentUser`), not a domain capability of
this module. Exporting the rest would be public surface for a consumer that does not exist.
"""

from app.modules.auth.router import router

__all__ = ["router"]
