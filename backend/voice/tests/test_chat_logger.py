"""Tests for ChatLogger integration in backend/voice."""

from __future__ import annotations

import json
import shutil
import tempfile
import unittest
from pathlib import Path

import sys
SRC_DIR = Path(__file__).resolve().parents[1] / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from chat_logger import ChatLogger


class TestBackendVoiceChatLogger(unittest.TestCase):
    def setUp(self) -> None:
        self.test_dir = Path(tempfile.mkdtemp(prefix="backend_voice_chat_"))
        self.log_path = self.test_dir / "chat_log.json"

    def tearDown(self) -> None:
        if self.test_dir.exists():
            shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_voice_turn_flow(self) -> None:
        logger = ChatLogger(self.log_path)
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

        # Verify disk persistence
        data = json.loads(self.log_path.read_text(encoding="utf-8"))
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]["chat"][0]["mode"], "voice")


if __name__ == "__main__":
    unittest.main()
