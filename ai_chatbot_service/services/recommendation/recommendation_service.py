from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from services.recommendation.embedding_service import EmbeddingService, normalize_semantic_text


DEFAULT_TOP_K = 5


@dataclass(frozen=True)
class BookSemanticItem:
    book_id: int
    title: str
    description: str | None = None
    category: str | None = None


@dataclass(frozen=True)
class SemanticRecommendation:
    book_id: int
    title: str
    score: float
    reason: str
    category: str | None = None


class SemanticRecommendationService:
    """Semantic recommendation and search over book title, description, category."""

    def __init__(self, embedding_service: EmbeddingService | None = None) -> None:
        self._embedding_service = embedding_service or EmbeddingService()

    def recommend_similar_books(
        self,
        source_book: BookSemanticItem,
        candidate_books: list[BookSemanticItem],
        top_k: int = DEFAULT_TOP_K,
    ) -> list[SemanticRecommendation]:
        candidates = [book for book in candidate_books if book.book_id != source_book.book_id]
        if not candidates:
            return []

        source_text = self._build_book_text(source_book)
        candidate_texts = [self._build_book_text(book) for book in candidates]

        query_embedding = self._embedding_service.encode_text(source_text)
        candidate_embeddings = self._embedding_service.encode_texts(candidate_texts)
        scores = self._embedding_service.cosine_similarity(query_embedding, candidate_embeddings)

        return self._rank_candidates(
            candidates=candidates,
            scores=scores,
            top_k=top_k,
            reason_builder=lambda book: self._build_recommendation_reason(source_book, book),
        )

    def semantic_search(
        self,
        query: str,
        books: list[BookSemanticItem],
        top_k: int = DEFAULT_TOP_K,
    ) -> list[SemanticRecommendation]:
        if not query.strip() or not books:
            return []

        query_embedding = self._embedding_service.encode_text(query)
        book_embeddings = self._embedding_service.encode_texts(
            self._build_book_text(book) for book in books
        )
        scores = self._embedding_service.cosine_similarity(query_embedding, book_embeddings)

        return self._rank_candidates(
            candidates=books,
            scores=scores,
            top_k=top_k,
            reason_builder=lambda book: self._build_search_reason(query, book),
        )

    def _rank_candidates(
        self,
        candidates: list[BookSemanticItem],
        scores: np.ndarray,
        top_k: int,
        reason_builder,
    ) -> list[SemanticRecommendation]:
        if scores.size == 0:
            return []

        safe_top_k = max(1, min(top_k, DEFAULT_TOP_K, len(candidates)))
        ranked_indexes = np.argsort(scores)[::-1][:safe_top_k]

        return [
            SemanticRecommendation(
                book_id=candidates[index].book_id,
                title=candidates[index].title,
                category=candidates[index].category,
                score=round(float(scores[index]), 4),
                reason=reason_builder(candidates[index]),
            )
            for index in ranked_indexes
        ]

    def _build_book_text(self, book: BookSemanticItem) -> str:
        return normalize_semantic_text(
            " ".join(
                part
                for part in [
                    book.title,
                    book.category or "",
                    book.description or "",
                ]
                if part
            )
        )

    def _build_recommendation_reason(
        self,
        source_book: BookSemanticItem,
        candidate_book: BookSemanticItem,
    ) -> str:
        if source_book.category and source_book.category == candidate_book.category:
            return f"Similar semantic content and same category: {candidate_book.category}"
        return "Similar semantic content based on title, description, and category"

    def _build_search_reason(self, query: str, book: BookSemanticItem) -> str:
        if book.category and normalize_semantic_text(book.category) in normalize_semantic_text(query):
            return f"Matched semantic query and category: {book.category}"
        return "Matched semantic query based on title, description, and category"
