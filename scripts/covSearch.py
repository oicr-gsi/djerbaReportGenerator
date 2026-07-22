import argparse
import json
import logging
from common import fetch_case, get_full_depth_samples, filter_tumor_samples, get_metric_values, get_paired_metric_values

logging.basicConfig(level=logging.INFO)

parser = argparse.ArgumentParser()
parser.add_argument("--case-id", required=True, help="Cardea case ID to query.")
parser.add_argument("--assay", type=str, required=True, help="Assay type: WGTS, WGS, PWGS, or TAR.")
parser.add_argument("--base-url", default="https://cardea.gsi.oicr.on.ca")
args = parser.parse_args()

assay = args.assay.upper()

case_json = fetch_case(args.case_id, args.base_url)
all_samples = get_full_depth_samples(case_json)
samples = filter_tumor_samples(all_samples, tumor_only=True)

# Always emit all four keys so downstream Map[String, String] access never
# fails on a missing key, regardless of which assay branch actually populated them.
result = {
    "meanCoverage": "",
    "medianInsertSize": "",
    "rawCoverage": "",
    "collapsedCoverage": "",
}

if assay in ("WGTS", "WGS"):
    coverage = get_metric_values(samples, "Mean Coverage Deduplicated")
    if coverage:
        result["meanCoverage"] = str(round(coverage[0], 1))
    else:
        logging.warning("No coverage data available for WGTS/WGS.")
        result["meanCoverage"] = "0"

elif assay == "PWGS":
    pairs = get_paired_metric_values(samples, "Mean Coverage Deduplicated", "Mean Insert Size")
    if pairs:
        coverage_val, insert_size_val = pairs[0]
        result["meanCoverage"] = str(int(coverage_val))
        result["medianInsertSize"] = str(int(insert_size_val))
    else:
        logging.warning("No sample with both coverage and insert size passing QC found for this case")
        result["meanCoverage"] = "0"
        result["medianInsertSize"] = "0"

elif assay == "TAR":
    pairs = get_paired_metric_values(samples, "Mean Bait Coverage", "Collapsed Coverage")
    if pairs:
        raw_val, collapsed_val = pairs[0]
        result["rawCoverage"] = str(int(raw_val))
        result["collapsedCoverage"] = str(int(collapsed_val))
    else:
        logging.warning("No sample with both raw and collapsed coverage passing QC found for this case")
        result["rawCoverage"] = "0"
        result["collapsedCoverage"] = "0"

else:
    raise ValueError(f"Unsupported assay: {assay}")

with open("result.json", "w") as f:
    json.dump(result, f)