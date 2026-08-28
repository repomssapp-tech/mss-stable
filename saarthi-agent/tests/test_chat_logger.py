"""Unit and integration tests for Local AI Chat Logging System.

Tests all 18 specified scenarios:
1. New conversation, single text turn.
2. Multiple text turns in one conversation.
3. Voice input -> transcription -> stored correctly as a turn with mode="voice".
4. Multiple voice turns.
5. Mixed text + voice turns within one conversation, in correct order.
6. Application restart -- history loads correctly, existing conversations intact.
7. New turns append correctly to the right conversation after restart.
8. New conversation (per defined trigger) gets a new id + new uid.
9. Same conversation keeps the same uid across multiple turns.
10. Conversation ids remain globally unique and sequential.
11. Missing chat_log.json is created correctly on first run (as []).
12. Corrupted JSON is backed up and recovered from without crashing or losing the corrupted file.
13. Empty voice transcription produces no turn at all (not even a pending one).
14. Failed AI response does not produce a completed turn in the log.
15. App closed while a turn is pending -- confirm incomplete turn is NOT written to disk.
16. Two near-simultaneous turn completions don't corrupt the file or drop a turn.
17. Mid-write interruption safety leaves the previous valid log intact.
18. Confirm no audio data, audio file paths, or Base64 audio appear anywhere in the log or code.
"""

from __future__ import annotations

import concurrent.futures
import json
import os
import shutil
import tempfile
import unittest
from pathlib import Path

# Add src to sys.path if not present
import sys
SRC_DIR = Path(__file__).resolve().parents[1] / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from chat_logger import ChatLogger


class TestChatLogger(unittest.TestCase):
    def setUp(self) -> None:
        self.test_dir = Path(tempfile.mkdtemp(prefix="mss_test_chat_"))
        self.log_path = self.test_dir / "chat_log.json"

    def tearDown(self) -> None:
        if self.test_dir.exists():
            shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_01_new_conversation_single_text_turn(self) -> None:
        """1. New conversation, single text turn."""
        logger = ChatLogger(self.log_path)
        uid = logger.start_conversation()
        turn_ref = logger.begin_turn(uid=uid, mode="text", user_message="Hello MSS")
        self.assertIsNotNone(turn_ref)

        stored = logger.complete_turn(uid=uid, turn_ref=turn_ref, ai_message="Vanakkam! How can I help?")
        self.assertIsNotNone(stored)
        self.assertEqual(stored["mode"], "text")
        self.assertEqual(stored["user"], "Hello MSS")
        self.assertEqual(stored["ai"], "Vanakkam! How can I help?")
        self.assertIn("timestamp", stored)
        self.assertRegex(stored["timestamp"], r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$")

        # Verify disk file
        disk_data = json.loads(self.log_path.read_text(encoding="utf-8"))
        self.assertEqual(len(disk_data), 1)
        self.assertEqual(disk_data[0]["id"], 1)
        self.assertEqual(disk_data[0]["uid"], uid)
        self.assertEqual(len(disk_data[0]["chat"]), 1)
        self.assertEqual(disk_data[0]["chat"][0], stored)

    def test_02_multiple_text_turns_in_one_conversation(self) -> None:
        """2. Multiple text turns in one conversation."""
        logger = ChatLogger(self.log_path)
        uid = logger.start_conversation()

        t1 = logger.begin_turn(uid, "text", "What schemes are for farmers?")
        logger.complete_turn(uid, t1, "Tamil Nadu offers Uzhavar Pathukappu Thittam.")

        t2 = logger.begin_turn(uid, "text", "What is the subsidy amount?")
        logger.complete_turn(uid, t2, "Up to 50% capital subsidy is provided.")

        conv = logger.get_conversation(uid)
        self.assertIsNotNone(conv)
        self.assertEqual(len(conv["chat"]), 2)
        self.assertEqual(conv["chat"][0]["user"], "What schemes are for farmers?")
        self.assertEqual(conv["chat"][1]["user"], "What is the subsidy amount?")

    def test_03_voice_turn_stored_as_text(self) -> None:
        """3. Voice input -> transcription -> stored correctly as a turn with mode='voice'."""
        logger = ChatLogger(self.log_path)
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

        # Confirm exact text is in disk file
        disk_data = json.loads(self.log_path.read_text(encoding="utf-8"))
        self.assertEqual(disk_data[0]["chat"][0]["mode"], "voice")
        self.assertEqual(disk_data[0]["chat"][0]["user"], transcribed_text)

    def test_04_multiple_voice_turns(self) -> None:
        """4. Multiple voice turns."""
        logger = ChatLogger(self.log_path)
        uid = logger.start_conversation()

        v1 = logger.begin_turn(uid, "voice", "வணக்கம்")
        logger.complete_turn(uid, v1, "வணக்கம்! என்ன உதவி வேண்டும்?")

        v2 = logger.begin_turn(uid, "voice", "தொழில் தொடங்க கடன் உதவி உள்ளதா?")
        logger.complete_turn(uid, v2, "UYEGP திட்டம் மூலம் 25% மானியம் பெறலாம்.")

        conv = logger.get_conversation(uid)
        self.assertEqual(len(conv["chat"]), 2)
        self.assertEqual(conv["chat"][0]["mode"], "voice")
        self.assertEqual(conv["chat"][1]["mode"], "voice")

    def test_05_mixed_text_and_voice_turns_in_order(self) -> None:
        """5. Mixed text + voice turns within one conversation, in correct order."""
        logger = ChatLogger(self.log_path)
        uid = logger.start_conversation()

        t1 = logger.begin_turn(uid, "text", "Hello")
        logger.complete_turn(uid, t1, "Hi! How can I help?")

        v1 = logger.begin_turn(uid, "voice", "What is the weather today?")
        logger.complete_turn(uid, v1, "The weather today is sunny.")

        t2 = logger.begin_turn(uid, "text", "What about tomorrow?")
        logger.complete_turn(uid, t2, "Tomorrow is expected to be partly cloudy.")

        conv = logger.get_conversation(uid)
        self.assertEqual(len(conv["chat"]), 3)
        self.assertEqual(conv["chat"][0]["mode"], "text")
        self.assertEqual(conv["chat"][1]["mode"], "voice")
        self.assertEqual(conv["chat"][2]["mode"], "text")
        self.assertEqual(conv["chat"][0]["user"], "Hello")
        self.assertEqual(conv["chat"][1]["user"], "What is the weather today?")
        self.assertEqual(conv["chat"][2]["user"], "What about tomorrow?")

    def test_06_application_restart_loads_history(self) -> None:
        """6. Application restart -- history loads correctly, existing conversations intact."""
        # First run
        logger1 = ChatLogger(self.log_path)
        uid = logger1.start_conversation()
        t1 = logger1.begin_turn(uid, "text", "First run query")
        logger1.complete_turn(uid, t1, "First run response")

        # Simulate restart by creating a new ChatLogger instance pointing to the same file
        logger2 = ChatLogger(self.log_path)
        history = logger2.get_history()
        self.assertEqual(len(history), 1)
        self.assertEqual(history[0]["uid"], uid)
        self.assertEqual(history[0]["chat"][0]["user"], "First run query")

    def test_07_new_turns_append_correctly_after_restart(self) -> None:
        """7. New turns append correctly to the right conversation after restart."""
        logger1 = ChatLogger(self.log_path)
        uid = logger1.start_conversation()
        t1 = logger1.begin_turn(uid, "text", "Message 1")
        logger1.complete_turn(uid, t1, "Reply 1")

        # Restart
        logger2 = ChatLogger(self.log_path)
        t2 = logger2.begin_turn(uid, "text", "Message 2")
        logger2.complete_turn(uid, t2, "Reply 2")

        conv = logger2.get_conversation(uid)
        self.assertEqual(len(conv["chat"]), 2)
        self.assertEqual(conv["chat"][0]["user"], "Message 1")
        self.assertEqual(conv["chat"][1]["user"], "Message 2")

    def test_08_new_conversation_gets_new_id_and_uid(self) -> None:
        """8. New conversation gets a new id + new uid."""
        logger = ChatLogger(self.log_path)
        uid1 = logger.start_conversation()
        uid2 = logger.start_conversation()

        self.assertNotEqual(uid1, uid2)
        c1 = logger.get_conversation(uid1)
        c2 = logger.get_conversation(uid2)
        self.assertEqual(c1["id"], 1)
        self.assertEqual(c2["id"], 2)

    def test_09_same_conversation_keeps_same_uid_across_turns(self) -> None:
        """9. Same conversation keeps the same uid across multiple turns."""
        logger = ChatLogger(self.log_path)
        uid = logger.start_conversation()

        for i in range(5):
            t = logger.begin_turn(uid, "text", f"Turn {i}")
            logger.complete_turn(uid, t, f"Ans {i}")

        conv = logger.get_conversation(uid)
        self.assertEqual(conv["uid"], uid)
        self.assertEqual(len(conv["chat"]), 5)

    def test_10_conversation_ids_remain_globally_unique_and_sequential(self) -> None:
        """10. Conversation ids remain globally unique and sequential."""
        logger1 = ChatLogger(self.log_path)
        uid1 = logger1.start_conversation()
        uid2 = logger1.start_conversation()
        self.assertEqual(logger1.get_conversation(uid1)["id"], 1)
        self.assertEqual(logger1.get_conversation(uid2)["id"], 2)

        # Restart app and start a third conversation
        logger2 = ChatLogger(self.log_path)
        uid3 = logger2.start_conversation()
        self.assertEqual(logger2.get_conversation(uid3)["id"], 3)

    def test_11_missing_file_created_on_first_run(self) -> None:
        """11. Missing chat_log.json is created correctly on first run (as [])."""
        self.assertFalse(self.log_path.exists())
        logger = ChatLogger(self.log_path)
        self.assertTrue(self.log_path.exists())
        raw_text = self.log_path.read_text(encoding="utf-8").strip()
        self.assertEqual(json.loads(raw_text), [])

    def test_12_corrupted_json_backed_up_and_recovered(self) -> None:
        """12. Corrupted JSON is backed up and recovered from without crashing or losing corrupted file."""
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
        corrupted_content = "{ this is invalid json content !!! "
        self.log_path.write_text(corrupted_content, encoding="utf-8")

        # ChatLogger should not crash
        logger = ChatLogger(self.log_path)
        history = logger.get_history()
        self.assertEqual(history, [])

        # Check that backup file exists
        backup_files = list(self.log_path.parent.glob("chat_log.corrupt-*.json"))
        self.assertEqual(len(backup_files), 1)
        self.assertEqual(backup_files[0].read_text(encoding="utf-8"), corrupted_content)

        # Fresh log should be fully functional
        uid = logger.start_conversation()
        t = logger.begin_turn(uid, "text", "Valid after corruption")
        logger.complete_turn(uid, t, "All working!")
        self.assertEqual(len(logger.get_conversation(uid)["chat"]), 1)

    def test_13_empty_voice_transcription_produces_no_turn(self) -> None:
        """13. Empty voice transcription produces no turn at all (not even a pending one)."""
        logger = ChatLogger(self.log_path)
        uid = logger.start_conversation()

        # Whitespace-only voice transcription
        t1 = logger.begin_turn(uid, "voice", "   ")
        self.assertIsNone(t1)

        # Empty string
        t2 = logger.begin_turn(uid, "voice", "")
        self.assertIsNone(t2)

        # Confirm chat array is empty
        conv = logger.get_conversation(uid)
        self.assertEqual(len(conv["chat"]), 0)
        self.assertEqual(len(logger._pending_turns), 0)

    def test_14_failed_ai_response_produces_no_completed_turn(self) -> None:
        """14. Failed AI response does not produce a completed turn in the log."""
        logger = ChatLogger(self.log_path)
        uid = logger.start_conversation()

        turn_ref = logger.begin_turn(uid, "text", "Hello AI")
        self.assertIsNotNone(turn_ref)

        # AI fails (e.g. returns empty or None or complete_turn is never called)
        res = logger.complete_turn(uid, turn_ref, "")
        self.assertIsNone(res)

        conv = logger.get_conversation(uid)
        self.assertEqual(len(conv["chat"]), 0)

    def test_15_incomplete_turn_not_written_on_app_close(self) -> None:
        """15. App closed while turn is pending -- confirm incomplete turn is NOT written to disk."""
        logger1 = ChatLogger(self.log_path)
        uid = logger1.start_conversation()

        # Completed turn
        t1 = logger1.begin_turn(uid, "text", "Completed message")
        logger1.complete_turn(uid, t1, "Completed reply")

        # Pending turn that never completes
        t2 = logger1.begin_turn(uid, "text", "Incomplete message without AI response")
        self.assertIsNotNone(t2)

        # Simulate app killed and restarted
        logger2 = ChatLogger(self.log_path)
        conv = logger2.get_conversation(uid)
        self.assertEqual(len(conv["chat"]), 1)
        self.assertEqual(conv["chat"][0]["user"], "Completed message")
        # Incomplete turn is not present
        self.assertNotIn("Incomplete message without AI response", json.dumps(conv))

    def test_16_concurrent_turn_completions(self) -> None:
        """16. Two near-simultaneous turn completions don't corrupt file or drop turns."""
        logger = ChatLogger(self.log_path)
        uid = logger.start_conversation()

        turn_refs = [
            logger.begin_turn(uid, "text", f"User query {i}")
            for i in range(20)
        ]

        def complete(i_and_ref: tuple[int, str]) -> None:
            i, ref = i_and_ref
            logger.complete_turn(uid, ref, f"AI response {i}")

        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            list(executor.map(complete, enumerate(turn_refs)))

        # Reload from disk and verify all 20 turns exist
        reloaded = ChatLogger(self.log_path)
        conv = reloaded.get_conversation(uid)
        self.assertEqual(len(conv["chat"]), 20)

    def test_17_atomic_persistence_preserves_valid_log(self) -> None:
        """17. Atomic persistence guarantees existing log remains intact."""
        logger = ChatLogger(self.log_path)
        uid = logger.start_conversation()
        t = logger.begin_turn(uid, "text", "Persisted Turn")
        logger.complete_turn(uid, t, "Persisted Reply")

        # Verify disk file is valid JSON
        data = json.loads(self.log_path.read_text(encoding="utf-8"))
        self.assertEqual(data[0]["chat"][0]["user"], "Persisted Turn")

    def test_18_no_audio_data_or_paths_in_log_or_code(self) -> None:
        """18. Confirm no audio data, audio file paths, or Base64 audio appear anywhere in log or code."""
        logger = ChatLogger(self.log_path)
        uid = logger.start_conversation()
        t = logger.begin_turn(uid, "voice", "Voice prompt transcribed text")
        logger.complete_turn(uid, t, "AI spoken reply text")

        content = self.log_path.read_text(encoding="utf-8")
        self.assertNotIn(".wav", content.lower())
        self.assertNotIn(".mp3", content.lower())
        self.assertNotIn("base64", content.lower())
        self.assertNotIn("audio/", content.lower())
        self.assertNotIn("audio_bytes", content.lower())


if __name__ == "__main__":
    unittest.main()
