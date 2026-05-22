from __future__ import annotations

from typing import Dict, List, Optional, Set

import numpy as np
import pandas as pd
from fastapi import FastAPI
from pydantic import BaseModel, Field
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


class BookFeature(BaseModel):
    book_id: int = Field(alias="bookId")
    title: str = ""
    category_id: Optional[int] = Field(default=None, alias="categoryId")
    category: str = ""
    author_id: Optional[int] = Field(default=None, alias="authorId")
    author: str = ""
    description: str = ""
    average_rating: float = Field(default=0, alias="averageRating")
    review_count: int = Field(default=0, alias="reviewCount")
    sold_count: int = Field(default=0, alias="soldCount")
    cart_count: int = Field(default=0, alias="cartCount")


class UserBehavior(BaseModel):
    user_id: int = Field(alias="userId")
    purchased_book_ids: List[int] = Field(default_factory=list, alias="purchasedBookIds")
    cart_book_ids: List[int] = Field(default_factory=list, alias="cartBookIds")
    reviewed_book_ids: List[int] = Field(default_factory=list, alias="reviewedBookIds")
    viewed_book_ids: List[int] = Field(default_factory=list, alias="viewedBookIds")
    preferred_category_ids: List[int] = Field(default_factory=list, alias="preferredCategoryIds")
    preferred_author_ids: List[int] = Field(default_factory=list, alias="preferredAuthorIds")


class UserRecommendRequest(BaseModel):
    user_id: int = Field(alias="userId")
    limit: int = 10
    books: List[BookFeature]
    behavior: UserBehavior


class BookRecommendRequest(BaseModel):
    book_id: int = Field(alias="bookId")
    limit: int = 10
    books: List[BookFeature]


class RecommendationItem(BaseModel):
    bookId: int
    score: float
    reason: str


class RecommendationResponse(BaseModel):
    items: List[RecommendationItem]


app = FastAPI(title="BookStore AI Recommendation Service", version="1.0.0")


def _build_frame(books: List[BookFeature]) -> pd.DataFrame:
    rows = []
    for book in books:
        rows.append(
            {
                "book_id": book.book_id,
                "title": book.title or "",
                "category_id": book.category_id,
                "category": book.category or "",
                "author_id": book.author_id,
                "author": book.author or "",
                "description": book.description or "",
                "average_rating": float(book.average_rating or 0),
                "review_count": int(book.review_count or 0),
                "sold_count": int(book.sold_count or 0),
                "cart_count": int(book.cart_count or 0),
            }
        )

    df = pd.DataFrame(rows)
    if df.empty:
        return df

    df["content"] = (
        (df["title"] + " ") * 2
        + (df["category"] + " ") * 4
        + (df["author"] + " ") * 3
        + df["description"]
    )
    return df


def _similarity_matrix(df: pd.DataFrame) -> np.ndarray:
    if df.empty:
        return np.zeros((0, 0))

    vectorizer = TfidfVectorizer(
        lowercase=True,
        strip_accents="unicode",
        ngram_range=(1, 2),
        min_df=1,
    )
    matrix = vectorizer.fit_transform(df["content"].fillna(""))
    return cosine_similarity(matrix)


def _popularity_score(df: pd.DataFrame) -> pd.Series:
    if df.empty:
        return pd.Series(dtype=float)

    max_sold = max(float(df["sold_count"].max()), 1.0)
    max_cart = max(float(df["cart_count"].max()), 1.0)
    max_reviews = max(float(df["review_count"].max()), 1.0)

    return (
        0.45 * (df["average_rating"].clip(0, 5) / 5)
        + 0.30 * (df["sold_count"] / max_sold)
        + 0.15 * (df["cart_count"] / max_cart)
        + 0.10 * (df["review_count"] / max_reviews)
    )


def _reason_for_user(row: pd.Series, behavior: UserBehavior) -> str:
    if row["category_id"] in set(behavior.preferred_category_ids):
        return f"De xuat vi ban quan tam the loai {row['category']}"
    if row["author_id"] in set(behavior.preferred_author_ids):
        return f"De xuat vi ban thich tac gia {row['author']}"
    if row["average_rating"] >= 4:
        return "De xuat vi sach duoc danh gia cao"
    return "De xuat dua tren sach ban da tuong tac"


@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.post("/recommend/book", response_model=RecommendationResponse)
def recommend_book(request: BookRecommendRequest) -> RecommendationResponse:
    df = _build_frame(request.books)
    if df.empty or request.book_id not in set(df["book_id"]):
        return RecommendationResponse(items=[])

    sim = _similarity_matrix(df)
    source_index = int(df.index[df["book_id"] == request.book_id][0])
    popularity = _popularity_score(df)

    scores = []
    source_category = df.loc[source_index, "category"]
    source_author = df.loc[source_index, "author"]

    for idx, row in df.iterrows():
        if int(row["book_id"]) == request.book_id:
            continue

        score = 0.82 * float(sim[source_index][idx]) + 0.18 * float(popularity.loc[idx])
        reason = f"Cung gu voi {source_category}"
        if row["author"] == source_author:
            reason = f"Cung tac gia {source_author}"

        scores.append((int(row["book_id"]), score, reason))

    items = [
        RecommendationItem(bookId=book_id, score=round(float(score), 4), reason=reason)
        for book_id, score, reason in sorted(scores, key=lambda x: x[1], reverse=True)[: request.limit]
    ]
    return RecommendationResponse(items=items)


@app.post("/recommend/user", response_model=RecommendationResponse)
def recommend_user(request: UserRecommendRequest) -> RecommendationResponse:
    df = _build_frame(request.books)
    if df.empty:
        return RecommendationResponse(items=[])

    interacted: Set[int] = set(request.behavior.purchased_book_ids)
    interacted.update(request.behavior.cart_book_ids)
    interacted.update(request.behavior.reviewed_book_ids)
    interacted.update(request.behavior.viewed_book_ids)

    if not interacted:
        popularity = _popularity_score(df)
        ranked = df.assign(score=popularity).sort_values("score", ascending=False)
        return RecommendationResponse(
            items=[
                RecommendationItem(
                    bookId=int(row.book_id),
                    score=round(float(row.score), 4),
                    reason="Sach dang duoc nhieu doc gia quan tam",
                )
                for row in ranked.head(request.limit).itertuples()
            ]
        )

    sim = _similarity_matrix(df)
    popularity = _popularity_score(df)
    book_id_to_index = {int(book_id): idx for idx, book_id in enumerate(df["book_id"].tolist())}
    seed_indexes = [book_id_to_index[x] for x in interacted if x in book_id_to_index]

    if not seed_indexes:
        ranked = df.assign(score=popularity).sort_values("score", ascending=False)
    else:
        content_scores = sim[seed_indexes].mean(axis=0)
        category_bonus = df["category_id"].isin(request.behavior.preferred_category_ids).astype(float) * 0.12
        author_bonus = df["author_id"].isin(request.behavior.preferred_author_ids).astype(float) * 0.10
        final_scores = (
            0.68 * content_scores
            + 0.17 * popularity.to_numpy()
            + category_bonus.to_numpy()
            + author_bonus.to_numpy()
        )
        ranked = df.assign(score=final_scores)

    ranked = ranked[~ranked["book_id"].isin(interacted)].sort_values("score", ascending=False)
    items = [
        RecommendationItem(
            bookId=int(row.book_id),
            score=round(float(row.score), 4),
            reason=_reason_for_user(pd.Series(row._asdict()), request.behavior),
        )
        for row in ranked.head(request.limit).itertuples()
    ]
    return RecommendationResponse(items=items)
