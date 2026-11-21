"""Summarize opt-in Smart Assessment debug logs from a synthetic QA session."""

import argparse
import json
from collections import Counter, defaultdict
from statistics import median


def summarize(lines):
    runs = Counter()
    questions = defaultdict(Counter)
    result_counts = []
    no_good_fit = 0
    opens = Counter()
    marker = "SMART_ASSESSMENT_QA {"
    for line in lines:
        _, found, payload = line.partition(marker)
        if not found:
            continue
        event = json.loads("{" + payload)
        match event["event"]:
            case "run":
                runs["started"] += 1
                runs["completed" if event["completed"] else "abandoned"] += 1
                for field, answered in event["fields"].items():
                    questions[field]["shown"] += 1
                    if answered is not None:
                        questions[field]["answered" if answered else "skipped"] += 1
                if event.get("drop_off_field"):
                    questions[event["drop_off_field"]]["drop_off"] += 1
            case "results":
                result_counts.append(event["good"] + event["possible"])
                no_good_fit += event["good"] == 0
            case "scheme_opened":
                opens[event["fit"]] += 1

    return {
        "runs": dict(runs),
        "results_views": len(result_counts),
        "median_viable_results": median(result_counts) if result_counts else None,
        "viable_result_distribution": dict(sorted(Counter(result_counts).items())),
        "views_without_good_fit": no_good_fit,
        "share_without_good_fit": (
            no_good_fit / len(result_counts) if result_counts else None
        ),
        "questions": dict(questions),
        "scheme_opens_by_fit": dict(opens),
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log", type=argparse.FileType("r", encoding="utf-8-sig"))
    args = parser.parse_args()
    with args.log:
        print(json.dumps(summarize(args.log), indent=2))
