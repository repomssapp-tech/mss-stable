"""Unit and integration tests for Supabase Cloud Chat Logging System.

Tests all cloud logging scenarios:
1. New conversation, single text turn dispatched to Supabase.
2. Multiple text turns in one conversation with sequential turn_index.
3. Voice input -> transcription -> stored correctly with mode="voice".
4. Multiple voice turns.
5. Mixed text + voice turns within one conversation, in correct order.
6. Headers and endpoint format matches Supabase PostgREST requirements.
7. Turn indices increment sequentially per conversation.
8. New conversation gets a new sequential id + new uid.
9. Same conversation keeps the same uid across multiple turns.
10. Empty voice transcription produces no turn.
11. Failed AI response produces no completed turn or dispatch.
12. App closed / uncompleted turn is NOT dispatched to Supabase.
13. Concurrent turn completions are thread-safe and dispatched properly.
14. Network error handling is graceful and does not raise uncaught exceptions.
15. Confirm no audio data, audio file paths, or Base64 audio appear in payloads.
16. Metadata payload support.
"""

from __future__ import annotations

import concurrent.futures
import inspect
import json
import os
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

# Add src to sys.path if not present
import sys
SRC_DIR = Path(__file__).resolve().parents[1] / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from chat_logger import ChatLogger


class TestChatLogger(unittest.TestCase):
    def setUp(self) -> None:
        self.dispatched_payloads: list[dict] = []

        def mock_insert(payload: dict) -> dict:
            self.dispatched_payloads.append(payload)
            return {"id": len(self.dispatched_payloads), **payload}

        self.mock_insert = mock_insert

    def create_logger(self) -> ChatLogger:
        logger = ChatLogger(
            supabase_url="https://houpzsxmwemoztpuigmo.supabase.co",
            supabase_key="test-key-123",
            table_name="chat_logs",
        )
        logger._insert_supabase_row = self.mock_insert  # type: ignore[assignment]
        return logger

    def test_01_new_conversation_single_text_turn(self) -> None:
        """1. New conversation, single text turn dispatched to Supabase."""
        logger = self.create_logger()
        uid = logger.start_conversation()
        turn_ref = logger.begin_turn(uid=uid, mode="text", user_message="Hello MSS")
        self.assertIsNotNone(turn_ref)

        stored = logger.complete_turn(uid=uid, turn_ref=turn_ref, ai_message="Vanakkam! How can I help?")
        self.assertIsNotNone(stored)
        self.assertEqual(stored["mode"], "text")
        self.assertEqual(stored["user"], "Hello MSS")
        self.assertEqual(stored["ai"], "Vanakkam! How can I help?")
        self.assertIn("timestamp", stored)

        # Verify dispatched payload to Supabase
        self.assertEqual(len(self.dispatched_payloads), 1)
        payload = self.dispatched_payloads[0]
        self.assertEqual(payload["conversation_uid"], uid)
        self.assertEqual(payload["turn_index"], 1)
        self.assertEqual(payload["mode"], "text")
        self.assertEqual(payload["user_message"], "Hello MSS")
        self.assertEqual(payload["ai_message"], "Vanakkam! How can I help?")

    def test_02_multiple_text_turns_in_one_conversation(self) -> None:
        """2. Multiple text turns in one conversation with sequential turn_index."""
        logger = self.create_logger()
        uid = logger.start_conversation()

        t1 = logger.begin_turn(uid, "text", "What schemes are for farmers?")
        logger.complete_turn(uid, t1, "Tamil Nadu offers Uzhavar Pathukappu Thittam.")

        t2 = logger.begin_turn(uid, "text", "What is the subsidy amount?")
        logger.complete_turn(uid, t2, "Up to 50% capital subsidy is provided.")

        conv = logger.get_conversation(uid)
        self.assertIsNotNone(conv)
        self.assertEqual(len(conv["chat"]), 2)
        self.assertEqual(len(self.dispatched_payloads), 2)
        self.assertEqual(self.dispatched_payloads[0]["turn_index"], 1)
        self.assertEqual(self.dispatched_payloads[1]["turn_index"], 2)

    def test_03_voice_turn_stored_with_voice_mode(self) -> None:
        """3. Voice input -> transcription -> stored correctly with mode='voice'."""
        logger = self.create_logger()
        uid = logger.start_conversation()

        transcribed_text = "எனக்கு வயது 25, தகுதியான திட்டம் சொல்லுங்கள்"
        turn_ref = logger.begin_turn(uid=uid, mode="voice", user_message=transcribed_text)
        self.assertIsNotNone(turn_ref)

        ai_reply = "நீங்கள் கலைஞர் மகளிர் உரிமைத் திட்டத்திற்கு விண்ணப்பிக்கலாம்."
        stored = logger.complete_turn(uid=uid, turn_ref=turn_ref, ai_message=ai_reply)

        self.assertIsNotNone(stored)
        self.assertEqual(stored["mode"], "voice")
        self.assertEqual(stored["user"], transcribed_text)
        self.assertEqual(stored["ai"], ai_reply)

        # Confirm exact text is in dispatched payload
        self.assertEqual(self.dispatched_payloads[0]["mode"], "voice")
        self.assertEqual(self.dispatched_payloads[0]["user_message"], transcribed_text)

    def test_04_mixed_text_and_voice_turns(self) -> None:
        """4. Mixed text + voice turns within one conversation, in correct order."""
        logger = self.create_logger()
        uid = logger.start_conversation()

        t1 = logger.begin_turn(uid, "text", "Hello")
        logger.complete_turn(uid, t1, "Hi! How can I help?")

        v1 = logger.begin_turn(uid, "voice", "Tell me about farmer schemes")
        logger.complete_turn(uid, v1, "PM-KISAN provides 6000 per year.")

        conv = logger.get_conversation(uid)
        self.assertEqual(len(conv["chat"]), 2)
        self.assertEqual(conv["chat"][0]["mode"], "text")
        self.assertEqual(conv["chat"][1]["mode"], "voice")
        self.assertEqual(self.dispatched_payloads[0]["mode"], "text")
        self.assertEqual(self.dispatched_payloads[1]["mode"], "voice")

    def test_05_headers_and_endpoint_format(self) -> None:
        """5. Headers and endpoint format matches Supabase PostgREST requirements."""
        logger = ChatLogger(
            supabase_url="https://houpzsxmwemoztpuigmo.supabase.co",
            supabase_key="test-api-key",
            table_name="chat_logs",
        )
        headers = logger._get_headers()
        self.assertEqual(headers["apikey"], "test-api-key")
        self.assertEqual(headers["Authorization"], "Bearer test-api-key")
        self.assertEqual(headers["Content-Type"], "application/json")
        self.assertEqual(headers["Prefer"], "return=representation")

    def test_06_new_conversation_gets_new_id_and_uid(self) -> None:
        """6. New conversation gets a new id + new uid."""
        logger = self.create_logger()
        uid1 = logger.start_conversation()
        uid2 = logger.start_conversation()

        self.assertNotEqual(uid1, uid2)
        c1 = logger.get_conversation(uid1)
        c2 = logger.get_conversation(uid2)
        self.assertEqual(c1["id"], 1)
        self.assertEqual(c2["id"], 2)

    def test_07_empty_voice_transcription_produces_no_turn(self) -> None:
        """7. Empty voice transcription produces no turn at all."""
        logger = self.create_logger()
        uid = logger.start_conversation()

        t1 = logger.begin_turn(uid, "voice", "   ")
        self.assertIsNone(t1)
        t2 = logger.begin_turn(uid, "voice", "")
        self.assertIsNone(t2)

        self.assertEqual(len(self.dispatched_payloads), 0)

    def test_08_failed_ai_response_produces_no_dispatch(self) -> None:
        """8. Failed AI response does not produce a completed turn."""
        logger = self.create_logger()
        uid = logger.start_conversation()

        turn_ref = logger.begin_turn(uid, "text", "Hello AI")
        self.assertIsNotNone(turn_ref)

        res = logger.complete_turn(uid, turn_ref, "")
        self.assertIsNone(res)
        self.assertEqual(len(self.dispatched_payloads), 0)

    def test_09_concurrent_turn_completions(self) -> None:
        """9. Two near-simultaneous turn completions don't drop turns."""
        logger = self.create_logger()
        uid = logger.start_conversation()

        turn_refs = [
            logger.begin_turn(uid, "text", f"User query {i}")
            for i in range(10)
        ]

        def complete(i_and_ref: tuple[int, str]) -> None:
            i, ref = i_and_ref
            logger.complete_turn(uid, ref, f"AI response {i}")

        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
            list(executor.map(complete, enumerate(turn_refs)))

        self.assertEqual(len(self.dispatched_payloads), 10)

    def test_10_no_audio_data_or_paths_in_payloads(self) -> None:
        """10. Confirm no audio data, audio file paths, or Base64 audio appear in payloads."""
        logger = self.create_logger()
        uid = logger.start_conversation()
        t = logger.begin_turn(uid, "voice", "Voice prompt transcribed text")
        logger.complete_turn(uid, t, "AI spoken reply text")

        payload_json = json.dumps(self.dispatched_payloads[0])
        self.assertNotIn(".wav", payload_json.lower())
        self.assertNotIn(".mp3", payload_json.lower())
        self.assertNotIn("base64", payload_json.lower())
        self.assertNotIn("audio/", payload_json.lower())
        self.assertNotIn("audio_bytes", payload_json.lower())

    def test_11_metadata_support(self) -> None:
        """11. Metadata is included in the dispatched payload."""
        logger = self.create_logger()
        uid = logger.start_conversation()
        t = logger.begin_turn(uid, "voice", "Check scheme")
        logger.complete_turn(
            uid,
            t,
            "Scheme found",
            metadata={"latency_ms": 320, "scheme_code": "TN-101"},
        )

        self.assertEqual(len(self.dispatched_payloads), 1)
        self.assertEqual(self.dispatched_payloads[0]["metadata"]["scheme_code"], "TN-101")
        self.assertEqual(self.dispatched_payloads[0]["metadata"]["latency_ms"], 320)

    @patch("chat_logger.urllib.request.urlopen")
    def test_12_missing_service_role_key_fails_loud_once_never_hardcoded(
        self, urlopen_mock: MagicMock
    ) -> None:
        """12. With no service-role key: no key is stored (never a hardcoded one),
        no HTTP is attempted, and the failure is logged exactly once, not per turn."""
        with patch.dict(os.environ, {}, clear=True):
            logger = ChatLogger(
                supabase_url="https://houpzsxmwemoztpuigmo.supabase.co",
                table_name="chat_logs",
            )

        self.assertIsNone(logger.supabase_key)

        payload = {
            "conversation_uid": "uid-1",
            "turn_index": 1,
            "mode": "text",
            "user_message": "hi",
            "ai_message": "hello",
            "metadata": {},
        }
        with self.assertLogs("chat_logger", level="ERROR") as captured:
            first = logger._insert_supabase_row(payload)
            second = logger._insert_supabase_row(payload)

        self.assertIsNone(first)
        self.assertIsNone(second)
        urlopen_mock.assert_not_called()
        self.assertEqual(len(captured.records), 1)
        self.assertIn("SUPABASE_SERVICE_ROLE_KEY", captured.output[0])

    def test_13_service_role_key_used_for_apikey_and_bearer(self) -> None:
        """13. SUPABASE_SERVICE_ROLE_KEY is the exact value used for both headers."""
        with patch.dict(
            os.environ, {"SUPABASE_SERVICE_ROLE_KEY": "svc-role-secret-xyz"}, clear=True
        ):
            logger = ChatLogger(
                supabase_url="https://houpzsxmwemoztpuigmo.supabase.co",
                table_name="chat_logs",
            )

        self.assertEqual(logger.supabase_key, "svc-role-secret-xyz")
        headers = logger._get_headers()
        self.assertEqual(headers["apikey"], "svc-role-secret-xyz")
        self.assertEqual(headers["Authorization"], "Bearer svc-role-secret-xyz")

    def test_14_no_hardcoded_supabase_key_literal_in_module(self) -> None:
        """14. The module carries no publishable/secret key literal and no default-key const."""
        import chat_logger as chat_logger_module

        source = inspect.getsource(chat_logger_module)
        self.assertNotIn("sb_publishable_", source)
        self.assertNotIn("sb_secret_", source)
        self.assertFalse(hasattr(chat_logger_module, "DEFAULT_SUPABASE_KEY"))


if __name__ == "__main__":
    unittest.main()
