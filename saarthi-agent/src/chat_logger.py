"""Cloud AI Chat Logging System for MSS (My Scheme Search) using Supabase.

Persists conversation history directly to the dedicated Supabase Cloud table (public.chat_logs)
without storing any local log files on disk. Each turn consists of a user input
(text or transcribed voice) paired with the AI's corresponding reply.
"""

from __future__ import annotations

import datetime
import json
import logging
import os
import threading
import urllib.error
import urllib.request
import uuid
from typing import Any

logger = logging.getLogger("chat_logger")

DEFAULT_SUPABASE_URL = "https://houpzsxmwemoztpuigmo.supabase.co"
DEFAULT_LOGS_TABLE = "chat_logs"

MISSING_KEY_MESSAGE = (
    "ChatLogger requires SUPABASE_SECRET_KEY (a server-side Supabase secret key) "
    "-- or the legacy SUPABASE_SERVICE_ROLE_KEY var, still accepted during the "
    "API-key migration -- or an explicit supabase_key argument. public.chat_logs "
    "denies client SELECT and only the secret / service_role key may write "
    "telemetry rows, so no anon/publishable key can be used as a fallback. "
    "Chat logging is disabled until a secret key is configured."
)


class ChatLogger:
    """Thread-safe Supabase conversation logger for text and voice AI interactions."""

    def __init__(
        self,
        supabase_url: str | None = None,
        supabase_key: str | None = None,
        table_name: str | None = None,
        http_timeout: float = 5.0,
    ) -> None:
        """Initialize the cloud chat logger.

        Args:
            supabase_url: Target Supabase project base URL. Defaults to SUPABASE_URL env var
                or https://houpzsxmwemoztpuigmo.supabase.co.
            supabase_key: Supabase server-side secret key. Resolved from
                this argument, else the SUPABASE_SECRET_KEY env var, else the legacy
                SUPABASE_SERVICE_ROLE_KEY var (still accepted during the API-key migration).
                No anon/publishable-key fallback exists: public.chat_logs denies client reads
                and grants writes to the secret / service_role key alone. Never ship this key
                in a client / APK. When no source provides a key, the logger stores None and
                refuses to dispatch (logging once, loudly, on the first attempt) instead of
                silently using a key that cannot write.
            table_name: Database table name for logs. Defaults to 'chat_logs'.
            http_timeout: Network timeout for HTTP requests in seconds.
        """
        self.supabase_url = (
            supabase_url
            or os.getenv("SUPABASE_URL")
            or DEFAULT_SUPABASE_URL
        ).rstrip("/")

        resolved_key = (
            supabase_key
            or os.getenv("SUPABASE_SECRET_KEY")
            or os.getenv("SUPABASE_SERVICE_ROLE_KEY")
            or ""
        ).strip()
        self.supabase_key: str | None = resolved_key or None

        self.table_name = table_name or os.getenv("SUPABASE_LOGS_TABLE") or DEFAULT_LOGS_TABLE
        self.http_timeout = http_timeout

        self._missing_key_logged = False
        self._lock = threading.Lock()
        self._conversations: list[dict[str, Any]] = []
        self._turn_counters: dict[str, int] = {}
        self._pending_turns: dict[str, dict[str, Any]] = {}

    def _get_headers(self) -> dict[str, str]:
        """Generate HTTP headers for Supabase PostgREST API requests."""
        return {
            "apikey": self.supabase_key,
            "Authorization": f"Bearer {self.supabase_key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        }

    def _insert_supabase_row(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        """Send a single turn record to the Supabase chat_logs table.

        If no service-role key is configured, refuse to dispatch. The failure is
        reported once at ERROR level and then suppressed, so a misconfigured
        deployment is loud on startup traffic without spamming a line per turn
        and without ever falling back to a key that cannot write.
        """
        if not self.supabase_key:
            if not self._missing_key_logged:
                self._missing_key_logged = True
                logger.error(MISSING_KEY_MESSAGE)
            return None

        endpoint = f"{self.supabase_url}/rest/v1/{self.table_name}"
        data_bytes = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        req = urllib.request.Request(
            endpoint,
            data=data_bytes,
            headers=self._get_headers(),
            method="POST",
        )

        try:
            with urllib.request.urlopen(req, timeout=self.http_timeout) as response:
                status = response.getcode()
                response_body = response.read().decode("utf-8")
                if 200 <= status < 300:
                    logger.debug(f"Logged turn to Supabase: uid={payload.get('conversation_uid')}")
                    try:
                        inserted = json.loads(response_body)
                        return inserted[0] if isinstance(inserted, list) and inserted else {}
                    except json.JSONDecodeError:
                        return {}
                else:
                    logger.warning(
                        f"Supabase logging returned non-success status {status}: {response_body}"
                    )
                    return None
        except urllib.error.HTTPError as error:
            error_body = error.read().decode("utf-8", errors="replace")
            logger.error(
                f"HTTP error inserting chat log to Supabase ({error.code} {error.reason}): {error_body}"
            )
            return None
        except (urllib.error.URLError, TimeoutError, OSError) as error:
            logger.error(f"Network error connecting to Supabase chat logs ({endpoint}): {error}")
            return None

    def start_conversation(self, custom_uid: str | None = None) -> str:
        """Create or register a conversation session in memory.

        Args:
            custom_uid: Optional existing session / conversation identifier. If not
                provided, a new UUID4 string is generated.

        Returns:
            The conversation UID (str).
        """
        with self._lock:
            uid = str(custom_uid).strip() if custom_uid and str(custom_uid).strip() else str(uuid.uuid4())

            existing = next(
                (conv for conv in self._conversations if isinstance(conv, dict) and conv.get("uid") == uid),
                None,
            )
            if existing is not None:
                return uid

            new_conv: dict[str, Any] = {
                "id": len(self._conversations) + 1,
                "uid": uid,
                "chat": [],
            }
            self._conversations.append(new_conv)
            self._turn_counters[uid] = 0
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
                self.start_conversation(custom_uid=uid)

            current_turn = self._turn_counters.get(uid, 0) + 1
            self._turn_counters[uid] = current_turn

            turn_ref = f"{uid}_{uuid.uuid4().hex}"
            self._pending_turns[turn_ref] = {
                "uid": uid,
                "turn_index": current_turn,
                "mode": mode,
                "user": cleaned_user,
            }
            return turn_ref

    def complete_turn(
        self,
        uid: str,
        turn_ref: str,
        ai_message: str,
        metadata: dict[str, Any] | None = None,
    ) -> dict[str, Any] | None:
        """Attach AI reply, finalize turn, and persist to Supabase cloud table.

        Args:
            uid: Target conversation UID.
            turn_ref: Active turn reference returned by begin_turn.
            ai_message: AI response text.
            metadata: Optional additional key-value metadata to store with the turn.

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
                logger.debug(
                    f"complete_turn rejected: uid '{uid}' does not match pending turn uid '{pending.get('uid')}'"
                )
                return None

            conv = next(
                (c for c in self._conversations if isinstance(c, dict) and c.get("uid") == uid),
                None,
            )
            if conv is None:
                self.start_conversation(custom_uid=uid)
                conv = next(c for c in self._conversations if c.get("uid") == uid)

            # Generate ISO 8601 timestamp with local timezone offset
            timestamp = datetime.datetime.now().astimezone().isoformat(timespec="seconds")

            turn_obj: dict[str, Any] = {
                "timestamp": timestamp,
                "turn_index": pending.get("turn_index", 1),
                "mode": pending["mode"],
                "user": pending["user"],
                "ai": cleaned_ai,
            }

            if not isinstance(conv.get("chat"), list):
                conv["chat"] = []

            conv["chat"].append(turn_obj)

        # Prepare payload and dispatch to Supabase table
        supabase_payload = {
            "conversation_uid": uid,
            "turn_index": pending.get("turn_index", 1),
            "mode": pending["mode"],
            "user_message": pending["user"],
            "ai_message": cleaned_ai,
            "metadata": metadata or {},
        }

        # Send row to Supabase
        self._insert_supabase_row(supabase_payload)

        return turn_obj

    def get_history(self) -> list[dict[str, Any]]:
        """Return the current list of in-memory conversations."""
        with self._lock:
            return [dict(conv) for conv in self._conversations]

    def get_conversation(self, uid: str) -> dict[str, Any] | None:
        """Return one conversation by its UID from in-memory cache."""
        with self._lock:
            conv = next(
                (c for c in self._conversations if isinstance(c, dict) and c.get("uid") == uid),
                None,
            )
            return dict(conv) if conv is not None else None

    def clear(self) -> None:
        """Reset in-memory state."""
        with self._lock:
            self._conversations.clear()
            self._pending_turns.clear()
            self._turn_counters.clear()
