"""What a provider can fail with, and the vocabulary a service catches."""


class ProviderError(Exception):
    """Anything that kept the provider from answering."""


class ProviderUnavailable(ProviderError):
    """No answer: the upstream is down, timed out, or replied with something unreadable."""


class ProviderQuotaExceeded(ProviderError):
    """The quota is spent. The cache answers, with a notice on top."""


class ProviderRejectedCredentials(ProviderError):
    """The API key is missing or wrong."""


class SymbolNotFound(ProviderError):
    """The provider has no data for that symbol."""
