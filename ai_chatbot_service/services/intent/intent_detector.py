from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass, field
from difflib import SequenceMatcher

from services.intent.intent_examples import INTENT_EXAMPLES, INTENT_PRIORITY


SUPPORTED_INTENTS = frozenset(
    {
        "greeting",
        "faq",
        "search_book",
        "recommend_book",
        "promotion",
    }
)


@dataclass(frozen=True)
class IntentDetectionResult:
    intent: str
    confidence: float
    matched_terms: list[str] = field(default_factory=list)


class IntentDetector:
    """Lightweight rule-based intent detector.

    The detector uses normalized Vietnamese/English text, phrase matches, and
    fuzzy similarity against small example sets. It is intentionally simple and
    dependency-free so it can run fast before heavier AI/NLP steps.
    """

    def __init__(
        self,
        examples: dict[str, list[str]] | None = None,
        default_intent: str = "faq",
    ) -> None:
        self._examples = examples or INTENT_EXAMPLES
        self._default_intent = default_intent

    def detect(self, message: str) -> IntentDetectionResult:
        normalized_message = normalize_text(message)
        if not normalized_message:
            return IntentDetectionResult(intent=self._default_intent, confidence=0.0)

        scores: dict[str, tuple[float, list[str]]] = {}
        for intent, examples in self._examples.items():
            if intent not in SUPPORTED_INTENTS:
                continue

            confidence, matched_terms = self._score_intent(normalized_message, examples)
            scores[intent] = (confidence, matched_terms)

        if not scores:
            return IntentDetectionResult(intent=self._default_intent, confidence=0.0)

        best_intent, (confidence, matched_terms) = max(
            scores.items(),
            key=lambda item: (
                item[1][0],
                INTENT_PRIORITY.get(item[0], 0),
            ),
        )

        if confidence < 0.25:
            return IntentDetectionResult(
                intent=self._default_intent,
                confidence=round(confidence, 4),
                matched_terms=matched_terms,
            )

        return IntentDetectionResult(
            intent=best_intent,
            confidence=round(confidence, 4),
            matched_terms=matched_terms,
        )

    def _score_intent(self, message: str, examples: list[str]) -> tuple[float, list[str]]:
        matched_terms: list[str] = []
        best_fuzzy_score = 0.0

        for raw_example in examples:
            example = normalize_text(raw_example)
            if not example:
                continue

            if _contains_phrase(message, example):
                matched_terms.append(raw_example)
                continue

            fuzzy_score = SequenceMatcher(None, message, example).ratio()
            best_fuzzy_score = max(best_fuzzy_score, fuzzy_score)

        phrase_score = min(0.85, 0.35 + len(matched_terms) * 0.18) if matched_terms else 0.0
        fuzzy_score = best_fuzzy_score * 0.6
        confidence = max(phrase_score, fuzzy_score)

        return min(confidence, 0.98), matched_terms


def normalize_text(value: str) -> str:
    value = value.strip().lower()
    value = unicodedata.normalize("NFD", value)
    value = "".join(ch for ch in value if unicodedata.category(ch) != "Mn")
    value = value.replace("đ", "d")
    value = re.sub(r"[^a-z0-9\s]", " ", value)
    value = re.sub(r"\s+", " ", value)
    return value.strip()


def _contains_phrase(message: str, phrase: str) -> bool:
    return re.search(rf"(^|\s){re.escape(phrase)}($|\s)", message) is not None
