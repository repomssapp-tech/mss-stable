"""Tests for ChatLogger integration in backend/voice using Supabase."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

import sys
SRC_DIR = Path(__file__).resolve().parents[1] / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from chat_logger import ChatLogger


class TestBackendVoiceChatLogger(unittest.TestCase):
    def setUp(self) -> None:
        self.dispatched_payloads: list[dict] = []

        def mock_insert(payload: dict) -> dict:
            self.dispatched_payloads.append(payload)
            return {"id": len(self.dispatched_payloads), **payload}

        self.mock_insert = mock_insert

    def test_voice_turn_flow(self) -> None:
        logger = ChatLogger(
            supabase_url="https://houpzsxmwemoztpuigmo.supabase.co",
            supabase_key="test-key",
            table_name="chat_logs",
        )
        logger._insert_supabase_row = self.mock_insert  # type: ignore[assignment]

        uid = logger.start_conversation()

        turn_ref = logger.begin_turn(uid=uid, mode="voice", user_message="மகளிர் உரிமைத் தொகை")
        self.assertIsNotNone(turn_ref)

        stored = logger.complete_turn(
            uid=uid,
            turn_ref=turn_ref,
            ai_message="கலைஞர் மகளிர் உரிமைத் திட்டம் மூலம் மாதம் ₹1,000 வழங்கப்படுகிறது.",
        )
        self.assertIsNotNone(stored)
        self.assertEqual(stored["mode"], "voice")
        self.assertEqual(stored["user"], "மகளிர் உரிமைத் தொகை")

        # Verify dispatched payload to Supabase
        self.assertEqual(len(self.dispatched_payloads), 1)
        payload = self.dispatched_payloads[0]
        self.assertEqual(payload["conversation_uid"], uid)
        self.assertEqual(payload["mode"], "voice")
        self.assertEqual(payload["user_message"], "மகளிர் உரிமைத் தொகை")
        self.assertEqual(payload["turn_index"], 1)


if __name__ == "__main__":
    unittest.main()
