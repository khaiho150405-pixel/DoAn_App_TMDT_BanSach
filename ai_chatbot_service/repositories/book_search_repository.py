from __future__ import annotations

import os
from decimal import Decimal
from typing import Any

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

from schemas.book_search_schema import BookSearchRequest, BookSearchResponse, BookSearchResult


class DatabaseConfigurationError(RuntimeError):
    """Raised when the chatbot service has no SQLAlchemy database URL."""


class BookSearchRepository:
    """SQLAlchemy repository for searching books in SQL Server.

    Expected environment variable:
    - BOOKSTORE_DATABASE_URL

    Example SQL Server URL:
    mssql+pyodbc://@./BookStoreDB?driver=ODBC+Driver+17+for+SQL+Server&Trusted_Connection=yes&TrustServerCertificate=yes
    """

    def __init__(self, database_url: str | None = None, engine: Engine | None = None) -> None:
        self._database_url = database_url or os.getenv("BOOKSTORE_DATABASE_URL")
        self._engine = engine

    def search_books(self, request: BookSearchRequest) -> BookSearchResponse:
        engine = self._get_engine()
        where_sql, params = self._build_filters(request)
        params["limit"] = request.limit
        params["offset"] = request.offset

        count_sql = text(
            f"""
            SELECT COUNT(1) AS total
            FROM SACH S
            INNER JOIN TACGIA TG ON TG.MATG = S.MATG
            INNER JOIN THELOAI TL ON TL.MATHELOAI = S.MATHELOAI
            {where_sql}
            """
        )

        query_sql = text(
            f"""
            SELECT
                S.MASACH AS book_id,
                S.TENSACH AS title,
                S.HINHANH AS image,
                S.MOTA AS description,
                S.GIABAN AS price,
                S.SOLUONGTON AS stock_quantity,
                TG.MATG AS author_id,
                TG.TENTG AS author,
                TL.MATHELOAI AS category_id,
                TL.TENTHELOAI AS category
            FROM SACH S
            INNER JOIN TACGIA TG ON TG.MATG = S.MATG
            INNER JOIN THELOAI TL ON TL.MATHELOAI = S.MATHELOAI
            {where_sql}
            ORDER BY
                CASE WHEN S.SOLUONGTON > 0 THEN 0 ELSE 1 END,
                S.TENSACH
            OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY
            """
        )

        with engine.connect() as connection:
            total = int(connection.execute(count_sql, params).scalar_one())
            rows = connection.execute(query_sql, params).mappings().all()

        return BookSearchResponse(
            items=[self._map_row(row) for row in rows],
            total=total,
            limit=request.limit,
            offset=request.offset,
        )

    def _get_engine(self) -> Engine:
        if self._engine is not None:
            return self._engine

        if not self._database_url:
            raise DatabaseConfigurationError(
                "Missing BOOKSTORE_DATABASE_URL for SQLAlchemy SQL Server connection."
            )

        self._engine = create_engine(
            self._database_url,
            pool_pre_ping=True,
            pool_size=5,
            max_overflow=10,
            future=True,
        )
        return self._engine

    def _build_filters(self, request: BookSearchRequest) -> tuple[str, dict[str, Any]]:
        conditions = []
        params: dict[str, Any] = {}

        if request.title:
            conditions.append("S.TENSACH LIKE :title")
            params["title"] = f"%{request.title.strip()}%"

        if request.category:
            conditions.append("TL.TENTHELOAI LIKE :category")
            params["category"] = f"%{request.category.strip()}%"

        if request.author:
            conditions.append("TG.TENTG LIKE :author")
            params["author"] = f"%{request.author.strip()}%"

        if request.min_price is not None:
            conditions.append("S.GIABAN >= :min_price")
            params["min_price"] = request.min_price

        if request.max_price is not None:
            conditions.append("S.GIABAN <= :max_price")
            params["max_price"] = request.max_price

        if request.in_stock_only:
            conditions.append("S.SOLUONGTON > 0")

        if not conditions:
            return "", params

        return "WHERE " + " AND ".join(conditions), params

    def _map_row(self, row: Any) -> BookSearchResult:
        return BookSearchResult(
            book_id=int(row["book_id"]),
            title=row["title"],
            image=row["image"],
            description=row["description"],
            price=self._to_float(row["price"]),
            stock_quantity=int(row["stock_quantity"] or 0),
            author_id=int(row["author_id"]),
            author=row["author"],
            category_id=int(row["category_id"]),
            category=row["category"],
        )

    def _to_float(self, value: Any) -> float:
        if value is None:
            return 0.0
        if isinstance(value, Decimal):
            return float(value)
        return float(value)
