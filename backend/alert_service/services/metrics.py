from datetime import datetime
from typing import Dict, Any
import threading


_lock = threading.Lock()


_state: Dict[str, Any] = {
    # last run timestamps
    "last_run": {
        "insurance_expiry": None,
        "service_due": None,
    },
    # counters since process start
    "counters": {
        "insurance_expiry_runs": 0,
        "service_due_runs": 0,
        "alerts_created": 0,
        "alerts_enqueued": 0,
        "deliveries_attempted": 0,
        "deliveries_succeeded": 0,
        "deliveries_failed": 0,
    },
}


def mark_rule_run(rule_key: str) -> None:
    with _lock:
        _state["last_run"][rule_key] = datetime.utcnow().isoformat() + "Z"
        if rule_key == "insurance_expiry":
            _state["counters"]["insurance_expiry_runs"] += 1
        elif rule_key == "service_due":
            _state["counters"]["service_due_runs"] += 1


def inc(metric_key: str, amount: int = 1) -> None:
    with _lock:
        _state["counters"][metric_key] = _state["counters"].get(metric_key, 0) + amount


def snapshot() -> Dict[str, Any]:
    with _lock:
        # return a shallow copy suitable for JSON serialization
        return {
            "last_run": dict(_state["last_run"]),
            "counters": dict(_state["counters"]),
        }


