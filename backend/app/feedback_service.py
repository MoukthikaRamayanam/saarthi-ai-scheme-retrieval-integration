import json
import time
from pathlib import Path
from typing import List, Dict, Any

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
FEEDBACK_FILE = DATA_DIR / "feedback.json"


class FeedbackService:
    def __init__(self, filepath: Path = FEEDBACK_FILE):
        self.filepath = filepath
        self._ensure_file()

    def _ensure_file(self) -> None:
        if not self.filepath.exists():
            self.filepath.parent.mkdir(parents=True, exist_ok=True)
            with open(self.filepath, "w", encoding="utf-8") as f:
                json.dump([], f)

    def load_feedback(self) -> List[Dict[str, Any]]:
        self._ensure_file()
        try:
            with open(self.filepath, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return []

    def record_feedback(self, query: str, scheme_id: str, feedback: str) -> Dict[str, Any]:
        normalized_feedback = feedback.strip().lower()
        if normalized_feedback not in ["relevant", "not_relevant"]:
            raise ValueError("Feedback must be either 'relevant' or 'not_relevant'")

        entry = {
            "query": query.strip(),
            "scheme_id": scheme_id.strip(),
            "feedback": normalized_feedback,
            "timestamp": time.time()
        }

        feedbacks = self.load_feedback()
        feedbacks.append(entry)

        with open(self.filepath, "w", encoding="utf-8") as f:
            json.dump(feedbacks, f, indent=2)

        return entry

    def get_feedback_adjustments(self) -> Dict[str, float]:
        """
        Calculates lightweight score adjustment per scheme_id based on accumulated feedback.
        - relevant: +0.02 bonus
        - not_relevant: -0.02 penalty
        Total adjustment is capped between -0.06 and +0.06 to preserve semantic similarity as the dominant signal.
        """
        feedbacks = self.load_feedback()
        scores: Dict[str, float] = {}

        for entry in feedbacks:
            s_id = entry.get("scheme_id")
            fb = entry.get("feedback")
            if not s_id:
                continue

            current = scores.get(s_id, 0.0)
            if fb == "relevant":
                current += 0.02
            elif fb == "not_relevant":
                current -= 0.02
            scores[s_id] = current

        # Clamp adjustments to [-0.06, 0.06]
        return {s_id: max(-0.06, min(0.06, val)) for s_id, val in scores.items()}


feedback_service = FeedbackService()
