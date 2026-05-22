from __future__ import annotations

import asyncio

from repositories.book_search_repository import BookSearchRepository
from schemas.book_search_schema import BookSearchRequest, BookSearchResponse


class BookSearchService:
    """Application service for structured database book search."""

    def __init__(self, repository: BookSearchRepository | None = None) -> None:
        self._repository = repository or BookSearchRepository()

    async def search_books(self, request: BookSearchRequest) -> BookSearchResponse:
        return await asyncio.to_thread(self._repository.search_books, request)

    async def search_by_title(self, title: str, limit: int = 10) -> BookSearchResponse:
        return await self.search_books(BookSearchRequest(title=title, limit=limit))

    async def search_by_category(self, category: str, limit: int = 10) -> BookSearchResponse:
        return await self.search_books(BookSearchRequest(category=category, limit=limit))

    async def search_by_author(self, author: str, limit: int = 10) -> BookSearchResponse:
        return await self.search_books(BookSearchRequest(author=author, limit=limit))

    async def search_by_price_range(
        self,
        min_price: float | None = None,
        max_price: float | None = None,
        limit: int = 10,
    ) -> BookSearchResponse:
        return await self.search_books(
            BookSearchRequest(
                min_price=min_price,
                max_price=max_price,
                limit=limit,
            )
        )


def get_book_search_service() -> BookSearchService:
    return BookSearchService()
