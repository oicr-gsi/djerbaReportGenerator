import logging
import requests

DEFAULT_BASE_URL = "https://cardea.gsi.oicr.on.ca"


def fetch_case(case_id, base_url=DEFAULT_BASE_URL):
    url = f"{base_url}/cases/{case_id}"
    try:
        res = requests.get(url, timeout=30)
        res.raise_for_status()
        return res.json()
    except Exception:
        logging.exception(f"Failed to fetch case {case_id} from {url}")
        return {}


def get_full_depth_samples(case_json):
    samples = []
    for test in case_json.get("tests", []) or []:
        samples.extend(test.get("fullDepthSequencings") or [])
    return samples


def filter_tumor_samples(samples, tumor_only=True):
    if not tumor_only:
        return samples
    tumor = [s for s in samples if s.get("tissueType") != "R"]
    if not tumor:
        logging.warning("No tumor samples found.")
    return tumor


def get_metric_values(samples, metric_name, metric_level="SAMPLE"):
    """Search each sample's metrics[] for entries matching metric_name
    that passed QC, and return values."""
    output = set()
    values = []
    for s in samples:
        for m in s.get("metrics") or []:
            if (m.get("name") or "").strip().lower() != metric_name.strip().lower():
                continue
            if metric_level is not None and m.get("metricLevel") != metric_level:
                continue
            if m.get("qcPassed") is not True:
                continue
            v = m.get("value")
            if v is None or v in output:
                continue
            output.add(v)
            values.append(v)
    return values

def get_paired_metric_values(samples, metric_name_a, metric_name_b, metric_level="SAMPLE"):
    """Return (value_a, value_b) pairs only from samples where both named
    metrics are present and passed QC on that same sample. This avoids
    pairing a passed value for one metric with a passed value for the
    other metric from a different sample."""
    name_a = metric_name_a.strip().lower()
    name_b = metric_name_b.strip().lower()

    output = set()
    pairs = []
    for s in samples:
        val_a = pass_a = val_b = pass_b = None
        for m in s.get("metrics") or []:
            if metric_level is not None and m.get("metricLevel") != metric_level:
                continue
            name = (m.get("name") or "").strip().lower()
            if name == name_a:
                val_a = m.get("value")
                pass_a = m.get("qcPassed") is True
            elif name == name_b:
                val_b = m.get("value")
                pass_b = m.get("qcPassed") is True

        if val_a is None or val_b is None:
            continue
        if not (pass_a and pass_b):
            continue

        key = (val_a, val_b)
        if key in output:
            continue
        output.add(key)
        pairs.append(key)

    return pairs
