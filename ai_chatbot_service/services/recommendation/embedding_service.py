from __future__ import annotations

import os
import re
from functools import lru_cache
from typing import Iterable

import numpy as np
from sentence_transformers import SentenceTransformer


DEFAULT_MODEL_NAME = "paraphrase-multilingual-MiniLM-L12-v2"


class EmbeddingService:
    """Creates semantic embeddings and cosine similarity scores.

    The default model is multilingual and works reasonably well for Vietnamese
    bookstore queries without requiring a heavy custom training pipeline.
    """

    def __init__(self, model_name: str | None = None, batch_size: int = 32) -> None:
        self._model_name = model_name or os.getenv(
            "BOOKSTORE_EMBEDDING_MODEL",
            DEFAULT_MODEL_NAME,
        )
        self._batch_size = batch_size

    def encode_text(self, text: str) -> np.ndarray:
        embeddings = self.encode_texts([text])
        if embeddings.size == 0:
            return np.array([], dtype=np.float32)
        return embeddings[0]

    def encode_texts(self, texts: Iterable[str]) -> np.ndarray:
        normalized_texts = [normalize_semantic_text(text) for text in texts]
        if not normalized_texts:
            return np.empty((0, 0), dtype=np.float32)

        return self._model.encode(
            normalized_texts,
            batch_size=self._batch_size,
            convert_to_numpy=True,
            normalize_embeddings=True,
            show_progress_bar=False,
        )

    def cosine_similarity(self, query_embedding: np.ndarray, corpus_embeddings: np.ndarray) -> np.ndarray:
        if query_embedding.size == 0 or corpus_embeddings.size == 0:
            return np.array([], dtype=np.float32)

        query = _ensure_2d(query_embedding)
        corpus = _ensure_2d(corpus_embeddings)

        query_norm = np.linalg.norm(query, axis=1, keepdims=True)
        corpus_norm = np.linalg.norm(corpus, axis=1, keepdims=True)
        denominator = np.clip(query_norm * corpus_norm.T, a_min=1e-12, a_max=None)

        return (query @ corpus.T / denominator).flatten()

    @property
    def _model(self) -> SentenceTransformer:
        return _load_model(self._model_name)


@lru_cache(maxsize=2)
def _load_model(model_name: str) -> SentenceTransformer:
    return SentenceTransformer(model_name)


def normalize_semantic_text(value: str | None) -> str:
    value = (value or "").strip().lower()
    value = re.sub(r"\s+", " ", value)
    return value


def _ensure_2d(embedding: np.ndarray) -> np.ndarray:
    if embedding.ndim == 1:
        return embedding.reshape(1, -1)
    return embedding
