"""Local AI Chat Logging System for MSS (My Scheme Search).

Stores conversation history locally in a JSON file using paired turns.
Each turn consists of a user input (text or transcribed voice) paired with
the AI's corresponding reply.
"""

from __future__ import annotations

import datetime
import json
import logging
import os
import threading
import uuid
from pathlib import Path
from typing import Any

logger = logging.getLogger("chat_logger")

DEFAULT_LOG_PATH = Path(__file__).resolve().parents[1] / "data" / "chat_log.json"


class ChatLogger:
    """Thread-safe, atomic local conversation logger for text and voice AI interactions."""

    def __init__(self, path: str | Path | None = None) -> None:
        """Initialize the chat logger.

        Resolves storage path, ensures file/dir exist, and loads existing conversations
        into memory.

        Args:
            path: Target JSON file path. Defaults to data/chat_log.json relative to the
                package data directory.
        """
        if path is None:
            self.path = DEFAULT_LOG_PATH.resolve()
        else:
            self.path = Path(path).resolve()

        self._lock = threading.Lock()
        self._conversations: list[dict[str, Any]] = []
        self._pending_turns: dict[str, dict[str, Any]] = {}
        self._pending_writes: bool = False

        self._ensure_storage_and_load()

    def _ensure_storage_and_load(self) -> None:
        """Ensure parent directory exists and load conversation history from disk."""
        with self._lock:
            try:
                self.path.parent.mkdir(parents=True, exist_ok=True)
            except OSError as error:
                logger.error(f"Could not create directory for chat log {self.path.parent}: {error}")

            if not self.path.exists():
                self._conversations = []
                self._write_file_locked()
                return

            try:
                content = self.path.read_text(encoding="utf-8").strip()
                if not content:
                    # Empty file treated as empty conversation list
                    self._conversations = []
                    self._write_file_locked()
                    return

                data = json.loads(content)
                if isinstance(data, list):
                    self._conversations = data
                else:
                    logger.warning(
                        f"Expected JSON array in {self.path}, got {type(data).__name__}. Recovering."
                    )
                    self._recover_corrupted_file()
            except (json.JSONDecodeError, UnicodeDecodeError, OSError) as error:
                logger.warning(f"Failed to parse chat log at {self.path}: {error}. Recovering.")
                self._recover_corrupted_file()

    def _recover_corrupted_file(self) -> None:
        """Back up corrupted file and start a fresh log without losing the corrupted data."""
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_name = f"{self.path.stem}.corrupt-{timestamp}{self.path.suffix}"
        backup_path = self.path.with_name(backup_name)

        try:
            if self.path.exists():
                os.replace(self.path, backup_path)
                logger.warning(f"Corrupted chat log backed up to {backup_path}")
        except OSError as error:
            logger.error(f"Failed to rename corrupted chat log {self.path} -> {backup_path}: {error}")

        self._conversations = []
        self._write_file_locked()

    def _next_conversation_id(self) -> int:
        """Calculate the next sequential conversation ID."""
        existing_ids = [
            conv["id"]
            for conv in self._conversations
            if isinstance(conv, dict) and isinstance(conv.get("id"), int)
        ]
        return max(existing_ids, default=0) + 1

    def _write_file_locked(self) -> bool:
        """Atomically persist current in-memory conversations to disk.

        Must be called with self._lock held.
        """
        temp_path = self.path.with_name(
            f"{self.path.name}.tmp.{os.getpid()}.{uuid.uuid4().hex[:8]}"
        )
        try:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            payload = json.dumps(self._conversations, ensure_ascii=False, indent=2) + "\n"
            with open(temp_path, "w", encoding="utf-8") as f:
                f.write(payload)
                f.flush()
                os.fsync(f.fileno())

            os.replace(temp_path, self.path)
            self._pending_writes = False
            return True
        except OSError as error:
            logger.error(f"Failed to persist chat log to {self.path}: {error}")
            self._pending_writes = True
            # Clean up temp file if present
            try:
                if temp_path.exists():
                    temp_path.unlink()
            except OSError:
                pass
            return False

    def start_conversation(self, custom_uid: str | None = None) -> str:
        """Create a new conversation object and persist it.

        Args:
            custom_uid: Optional existing session / conversation identifier. If not
                provided, a new UUID4 string is generated.

        Returns:
            The conversation UID (str).
        """
        with self._lock:
            uid = str(custom_uid).strip() if custom_uid and str(custom_uid).strip() else str(uuid.uuid4())

            # Check if this exact uid already exists in the loaded history
            existing = next(
                (conv for conv in self._conversations if isinstance(conv, dict) and conv.get("uid") == uid),
                None,
            )
            if existing is not None:
                return uid

            new_conv: dict[str, Any] = {
                "id": self._next_conversation_id(),
                "uid": uid,
                "chat": [],
            }
            self._conversations.append(new_conv)
            self._write_file_locked()
            return uid

    def begin_turn(self, uid: str, mode: str, user_message: str) -> str | None:
        """Validate and hold the user side of a turn in memory.

        Args:
            uid: Target conversation UID.
            mode: "text" | "voice".
            user_message: User input text or transcribed voice text.

        Returns:
            turn_ref (str) if valid, or None if rejected.
        """
        if not isinstance(uid, str) or not uid.strip():
            logger.debug("begin_turn rejected: empty or invalid uid")
            return None

        if mode not in {"text", "voice"}:
            logger.debug(f"begin_turn rejected: invalid mode '{mode}'")
            return None

        if not isinstance(user_message, str) or not user_message.strip():
            logger.debug("begin_turn rejected: empty or whitespace-only user_message")
            return None

        cleaned_user = user_message.strip()

        with self._lock:
            conv = next(
                (c for c in self._conversations if isinstance(c, dict) and c.get("uid") == uid),
                None,
            )
            if conv is None:
                logger.debug(f"begin_turn rejected: conversation uid '{uid}' not found")
                return None

            turn_ref = f"{uid}_{uuid.uuid4().hex}"
            self._pending_turns[turn_ref] = {
                "uid": uid,
                "mode": mode,
                "user": cleaned_user,
            }
            return turn_ref

    def complete_turn(self, uid: str, turn_ref: str, ai_message: str) -> dict[str, Any] | None:
        """Attach AI reply, set finalized ISO 8601 timestamp, and persist complete turn.

        Args:
            uid: Target conversation UID.
            turn_ref: Active turn reference returned by begin_turn.
            ai_message: AI response text.

        Returns:
            The stored turn object dict, or None if rejected / incomplete.
        """
        if not isinstance(turn_ref, str) or not turn_ref.strip():
            logger.debug("complete_turn rejected: invalid turn_ref")
            return None

        if not isinstance(ai_message, str) or not ai_message.strip():
            logger.debug("complete_turn rejected: empty or whitespace-only ai_message")
            return None

        cleaned_ai = ai_message.strip()

        with self._lock:
            pending = self._pending_turns.pop(turn_ref, None)
            if pending is None:
                logger.debug(f"complete_turn rejected: turn_ref '{turn_ref}' not found in pending turns")
                return None

            if pending.get("uid") != uid:
                logger.debug(f"complete_turn rejected: uid '{uid}' does not match pending turn uid '{pending.get('uid')}'")
                return None

            conv = next(
                (c for c in self._conversations if isinstance(c, dict) and c.get("uid") == uid),
                None,
            )
            if conv is None:
                logger.debug(f"complete_turn rejected: conversation uid '{uid}' not found")
                return None

            # Generate ISO 8601 timestamp with local timezone offset at finalization time
            timestamp = datetime.datetime.now().astimezone().isoformat(timespec="seconds")

            turn_obj: dict[str, Any] = {
                "timestamp": timestamp,
                "mode": pending["mode"],
                "user": pending["user"],
                "ai": cleaned_ai,
            }

            if not isinstance(conv.get("chat"), list):
                conv["chat"] = []

            conv["chat"].append(turn_obj)

            # Persist atomically to disk
            self._write_file_locked()

            return turn_obj

    def get_history(self) -> list[dict[str, Any]]:
        """Return the full list of conversations."""
        with self._lock:
            # Return a shallow copy of the conversation list
            return [dict(conv) for conv in self._conversations]

    def get_conversation(self, uid: str) -> dict[str, Any] | None:
        """Return one conversation by its UID."""
        with self._lock:
            conv = next(
                (c for c in self._conversations if isinstance(c, dict) and c.get("uid") == uid),
                None,
            )
            return dict(conv) if conv is not None else None

    def clear(self) -> None:
        """Clear all conversations and reset the log file (primarily for tests)."""
        with self._lock:
            self._conversations = []
            self._pending_turns.clear()
            self._write_file_locked()
