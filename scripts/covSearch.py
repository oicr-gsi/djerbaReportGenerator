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
        if len(coverage) > 1:
            logging.warning(
                f"Multiple tumor samples with coverage data: "
                f"{[c[0] for c in coverage]}. Using {coverage[0][0]}."
            )
        result["meanCoverage"] = str(round(coverage[0][1], 1))
    else:
        logging.warning("No coverage data available for WGTS/WGS.")
        result["meanCoverage"] = "0"

elif assay == "PWGS":
    pairs = get_paired_metric_values(samples, "Mean Coverage Deduplicated", "Mean Insert Size")
    if pairs:
        if len(pairs) > 1:
            logging.warning(
                f"Multiple tumor samples with both coverage and insert size passing QC: "
                f"{[p[0] for p in pairs]}. Using {pairs[0][0]}."
            )
        _, coverage_val, insert_size_val = pairs[0]
        result["meanCoverage"] = str(round(coverage_val))
        result["medianInsertSize"] = str(round(insert_size_val))
    else:
        logging.warning("No sample with both coverage and insert size passing QC found for this case")
        result["meanCoverage"] = "0"
        result["medianInsertSize"] = "0"

elif assay == "TAR":
    pairs = get_paired_metric_values(samples, "Mean Bait Coverage", "Collapsed Coverage")
    if pairs:
        if len(pairs) > 1:
            logging.warning(
                f"Multiple tumor samples with both raw and collapsed coverage passing QC: "
                f"{[p[0] for p in pairs]}. Using {pairs[0][0]}."
            )
        _, raw_val, collapsed_val = pairs[0]
        result["rawCoverage"] = str(round(raw_val))
        result["collapsedCoverage"] = str(round(collapsed_val))
    else:
        # Collapsed coverage is the deciding metric for TAR. If it passed QC,
        # use that sample and take its raw coverage even if raw failed QC.
        collapsed = get_metric_values(samples, "Collapsed Coverage")
        if collapsed:
            if len(collapsed) > 1:
                logging.warning(
                    f"Multiple tumor samples with collapsed coverage passing QC: "
                    f"{[c[0] for c in collapsed]}. Using {collapsed[0][0]}."
                )
            group_id, collapsed_val = collapsed[0]
            result["collapsedCoverage"] = str(round(collapsed_val))

            same_sample = [s for s in samples if s.get("groupId") == group_id]
            raw = get_metric_values(same_sample, "Mean Bait Coverage", include_failed=True)
            if raw:
                logging.warning(
                    f"Mean Bait Coverage did not pass QC for {group_id}; "
                    f"reporting the failed value ({raw[0][1]}) alongside passing collapsed coverage."
                )
                result["rawCoverage"] = str(round(raw[0][1]))
            else:
                logging.warning(f"No Mean Bait Coverage data for {group_id}.")
                result["rawCoverage"] = "0"
        else:
            # Collapsed coverage failed QC on every sample. If raw coverage passed,
            # use that sample and take its (failed) collapsed value. If raw also
            # failed everywhere, report 0 and 0.
            raw_passed = get_metric_values(samples, "Mean Bait Coverage")
            if raw_passed:
                group_id, raw_val = raw_passed[0]
                result["rawCoverage"] = str(round(raw_val))

                same_sample = [s for s in samples if s.get("groupId") == group_id]
                collapsed_failed = get_metric_values(same_sample, "Collapsed Coverage", include_failed=True)
                if collapsed_failed:
                    logging.warning(
                        f"Collapsed Coverage did not pass QC for {group_id}; "
                        f"reporting the failed value ({collapsed_failed[0][1]}) alongside passing raw coverage."
                    )
                    result["collapsedCoverage"] = str(round(collapsed_failed[0][1]))
                else:
                    logging.warning(f"No Collapsed Coverage data for {group_id}.")
                    result["collapsedCoverage"] = "0"
            else:
                logging.warning("Both Mean Bait Coverage and Collapsed Coverage failed QC; reporting 0 and 0.")
                result["rawCoverage"] = "0"
                result["collapsedCoverage"] = "0"

else:
    raise ValueError(f"Unsupported assay: {assay}")

with open("result.json", "w") as f:
    json.dump(result, f)