
class TestReadingTheChart:
    """RF-35 and Article III: the chart is served only for the favourites of who is asking.

    The pair is the whole statement. The 404 is the part a reviewer looks for; the second test is
    the part that matters for Article II, because an implementation that authorizes *after*
    fetching answers the same 404 and has already spent a credit on somebody else's symbol.

    404 and not 403: a 403 confirms that the symbol exists and belongs to another user, and here
    there is nothing to confirm. It is also the answer `002` gives for a symbol that cannot be
    added, so the frontend has one case to handle and not two.
    """

    @pytest.fixture
    def provider(self) -> Iterator[_CallCounter]:
        """The market data provider the request would be served with, counting its calls."""
        counter = _CallCounter()
        app.dependency_overrides[get_market_data_provider] = lambda: counter

        yield counter

        app.dependency_overrides.pop(get_market_data_provider, None)

    async def test_a_symbol_of_the_other_user_is_not_found(
        self, client: AsyncClient, juan: User, ana: User, provider: _CallCounter
    ) -> None:
        """TSLA is juan's. For ana's token it does not exist."""
        response = await client.get(
            "/api/quotes/TSLA", params={"interval": "1min"}, headers=_bearer(ana)
        )

        assert response.status_code == 404

    async def test_a_symbol_of_the_other_user_costs_no_quota(
        self, client: AsyncClient, juan: User, ana: User, provider: _CallCounter
    ) -> None:
        """Authorizing first is what makes the refusal free (Article II)."""
        await client.get("/api/quotes/TSLA", params={"interval": "1min"}, headers=_bearer(ana))

        assert provider.calls == []

    async def test_the_owner_of_the_symbol_is_served(
        self, client: AsyncClient, juan: User, provider: _CallCounter
    ) -> None:
        """The same request, with the token of whoever has TSLA in their list."""
        response = await client.get(
            "/api/quotes/TSLA", params={"interval": "1min"}, headers=_bearer(juan)
        )

        assert response.status_code == 200
