import argparse
import json
import logging
from common import fetch_case

logging.basicConfig(level=logging.INFO)

parser = argparse.ArgumentParser()
parser.add_argument("--case-id", required=True, help="Cardea case ID to query.")
parser.add_argument("--base-url", default="https://cardea.gsi.oicr.on.ca")
args = parser.parse_args()


def get_callability(case_json, library_design_code="WG"):
    groups = case_json.get("qcGroups") or []
    matches = [
        g for g in groups
        if g.get("libraryDesignCode") == library_design_code
        and g.get("tissueType") != "R"
    ]
    if not matches:
        logging.warning(f"No tumor qcGroup found with libraryDesignCode={library_design_code}.")
        return None
    return matches[0].get("callability")


case_json = fetch_case(args.case_id, args.base_url)
call = get_callability(case_json, library_design_code="WG")

result = {
    "callability": str(round(call, 1)) if call is not None else "0",
}

with open("result.json", "w") as f:
    json.dump(result, f)