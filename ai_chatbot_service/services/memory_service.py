from __future__ import annotations

from collections import OrderedDict
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from threading import RLock
from typing import Any


@dataclass(frozen=True)
class ConversationTurn:
    role: str
    message: str
    created_at: datetime
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class ConversationContext:
    session_key: str
    turns: list[ConversationTurn]

    @property
    def last_user_message(self) -> str | None:
        for turn in reversed(self.turns):
            if turn.role == "user":
                return turn.message
        return None

    @property
    def last_assistant_message(self) -> str | None:
        for turn in reversed(self.turns):
            if turn.role == "assistant":
                return turn.message
        return None

    @property
    def last_intent(self) -> str | None:
        for turn in reversed(self.turns):
            intent = turn.metadata.get("intent")
            if isinstance(intent, str) and intent:
                return intent
        return None

    @property
    def message_count(self) -> int:
        return len(self.turns)


class ConversationMemoryService:
    """Lightweight in-memory conversation cache.

    This service is intentionally process-local. It is suitable for a small
    chatbot service or local development. For multi-instance deployments, swap
    this class for Redis while keeping the same public methods.
    """

    def __init__(
        self,
        max_turns_per_session: int = 12,
        ttl_minutes: int = 30,
        max_sessions: int = 500,
    ) -> None:
        self._max_turns_per_session = max_turns_per_session
        self._ttl = timedelta(minutes=ttl_minutes)
        self._max_sessions = max_sessions
        self._sessions: OrderedDict[str, list[ConversationTurn]] = OrderedDict()
        self._lock = RLock()

    def build_session_key(self, session_id: str | None, user_id: int | None) -> str:
        if session_id and session_id.strip():
            return f"session:{session_id.strip()}"
        if user_id is not None:
            return f"user:{user_id}"
        return "anonymous"

    def get_context(self, session_key: str) -> ConversationContext:
        with self._lock:
            self._purge_expired_locked()
            turns = list(self._sessions.get(session_key, []))
            if session_key in self._sessions:
                self._sessions.move_to_end(session_key)
            return ConversationContext(session_key=session_key, turns=turns)

    def add_turn(
        self,
        session_key: str,
        role: str,
        message: str,
        metadata: dict[str, Any] | None = None,
    ) -> None:
        cleaned_message = message.strip()
        if not cleaned_message:
            return

        with self._lock:
            self._purge_expired_locked()
            turns = self._sessions.setdefault(session_key, [])
            turns.append(
                ConversationTurn(
                    role=role,
                    message=cleaned_message,
                    created_at=_utc_now(),
                    metadata=metadata or {},
                )
            )
            if len(turns) > self._max_turns_per_session:
                del turns[: len(turns) - self._max_turns_per_session]
            self._sessions.move_to_end(session_key)
            self._trim_sessions_locked()

    def clear_session(self, session_key: str) -> None:
        with self._lock:
            self._sessions.pop(session_key, None)

    def _purge_expired_locked(self) -> None:
        now = _utc_now()
        expired_keys = [
            key
            for key, turns in self._sessions.items()
            if not turns or now - turns[-1].created_at > self._ttl
        ]
        for key in expired_keys:
            self._sessions.pop(key, None)

    def _trim_sessions_locked(self) -> None:
        while len(self._sessions) > self._max_sessions:
            self._sessions.popitem(last=False)


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


_memory_service = ConversationMemoryService()


def get_conversation_memory_service() -> ConversationMemoryService:
    return _memory_service
