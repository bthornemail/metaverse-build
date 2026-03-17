#!/usr/bin/env python3

import json
import unittest
from pathlib import Path

from runtime.tetragrammatron.io.lane16 import (
  Lane16Error,
  Lane16System,
  encode_lane_state,
  fano_pcg_check,
  lane_pair_digest,
  lane_phase,
  lane_sid,
  lane_step,
)


ROOT = Path(__file__).resolve().parents[3]


class Lane16Tests(unittest.TestCase):
  def test_accept_corpus(self):
    accept = ROOT / "runtime/tetragrammatron/fixtures/lane16/accept"
    for path in sorted(accept.rglob("*.json")):
      payload = json.loads(path.read_text(encoding="utf-8"))
      kind = payload["kind"]
      if kind == "lane_basic":
        self.assertEqual(lane_step(payload["state"]), payload["expected_next"])
        self.assertEqual(lane_phase(payload["lane_idx"], payload["state"]), payload["expected_phase"])
        self.assertEqual(lane_sid(payload["lane_idx"], payload["state"]), payload["expected_sid"])
        self.assertEqual(encode_lane_state(payload["lane_idx"], payload["state"]), payload["expected_codes"])
      elif kind == "lane_group":
        start = payload["group"] * 4
        self.assertEqual(fano_pcg_check(payload["states"], start), payload["expected_sync"])
      elif kind == "lane_full":
        system = Lane16System.init(payload["initial_states"])
        for _ in range(payload["steps"]):
          system.tick()
        self.assertEqual(system.clock, payload["expected_clock"])
        self.assertEqual(system.lane_states, payload["expected_states"])
        self.assertEqual(system.sid, payload["expected_sid"])
        self.assertEqual(system.sync_all(), payload["expected_sync_all"])
      elif kind == "lane_invariant":
        self.assertEqual(lane_pair_digest(payload["states"]), payload["expected_digest"])
      else:
        self.fail(f"unknown kind: {kind}")

  def test_must_reject_corpus(self):
    reject = ROOT / "runtime/tetragrammatron/fixtures/lane16/must-reject"
    for path in sorted(reject.glob("*.json")):
      payload = json.loads(path.read_text(encoding="utf-8"))
      kind = payload["kind"]
      with self.assertRaises(Exception):
        if kind == "lane_basic":
          _ = lane_phase(payload["lane_idx"], payload["state"])
        elif kind == "lane_group":
          start = payload["group"] * 4
          got = fano_pcg_check(payload["states"], start)
          if got != payload["expected_sync"]:
            raise Lane16Error("group sync mismatch")
        elif kind == "lane_codes":
          _ = encode_lane_state(payload["lane_idx"], payload["state"])
        elif kind == "lane_full":
          system = Lane16System.init(payload["initial_states"])
          for _ in range(payload.get("steps", 0)):
            system.tick()
          if system.sync_all() != payload["expected_sync_all"]:
            raise Lane16Error("system sync mismatch")
        else:
          raise Lane16Error("unknown reject kind")


if __name__ == "__main__":
  unittest.main()
