from gsiqcetl import QCETLMultiCache
import gsiqcetl.column
import argparse
import logging
import pandas as pd

# Set up logging
logging.basicConfig(level=logging.INFO)

# Argument parser
parser = argparse.ArgumentParser()
parser.add_argument("--gsiqcetl-dir", action="append", required=True,
                    help="Path(s) to GSI-QC-ETL directories.")
parser.add_argument("--lims-id", nargs="+", required=True,
                    help="List of LIMS IDs to search for.")
parser.add_argument("--assay", type=str, required=True,
                    help="Assay type: WGTS, WGS, PWGS, or TAR.")
args = parser.parse_args()

# Flatten any nested LIMS IDs (e.g., [['ABC123']] -> ['ABC123'])
def _flatten_lims_ids(lims_ids):
    flat = []
    for item in lims_ids:
        if isinstance(item, list):
            flat.extend(item)
        else:
            flat.append(item)
    return [str(i) for i in flat]

lims_ids = _flatten_lims_ids(args.lims_id)
assay = args.assay.upper()
gsiqcetl_dirs = args.gsiqcetl_dir

# Load ETL caches
etl_caches = QCETLMultiCache(gsiqcetl_dirs)

def _load_cache(etl_caches, cache_version, cache_name, id_column, merged=False):
    try:
        version = etl_caches.load_same_version(cache_version).remove_missing(cache_name)
        cache = version.unique(cache_name)
        if id_column not in cache:
            logging.warning(f"'{id_column}' column not found in cache: {cache_name}.{cache_version}")
            return pd.DataFrame()
        if merged:
            single_id_column = "Pinery Lims ID"
            cache[single_id_column] = cache[id_column]
            cache = cache.explode(single_id_column)
        else:
            single_id_column = id_column
        cache.set_index(single_id_column, inplace=True, drop=False)
        cache.sort_index(inplace=True)
        return cache
    except Exception:
        logging.exception(f"Failed to load cache: {cache_version}.{cache_name}")
        return pd.DataFrame()

def _get_metric(cache: pd.DataFrame, lims_ids: list[str], column_name: str):
    if not lims_ids:
        logging.warning("No LIMS IDs provided.")
        return pd.DataFrame()

    lims_ids = [str(i) for i in lims_ids]
    filtered = cache.loc[cache.index.intersection(lims_ids)]

    if filtered.empty:
        logging.warning("No matching LIMS IDs found.")
        return pd.DataFrame()

    tumor = filtered[filtered['Tissue Type'] != 'R']
    if tumor.empty:
        logging.warning("No tumor samples found.")
        return pd.DataFrame()

    values = tumor[column_name].drop_duplicates()
    return values

# Assay-specific logic
if assay in ("WGTS", "WGS"):
    cache = _load_cache(
        etl_caches, "bamqc4merged", "bamqc4merged",
        gsiqcetl.column.BamQc4MergedColumn.MergedPineryLimsID,
        merged=True
    )
    coverage = _get_metric(cache, lims_ids, "coverage deduplicated")
    with open("coverage.txt", "w") as f:
        if not coverage.empty:
            coverage = coverage.round(1).astype(str)
            f.write("\n".join(coverage))
        else:
            logging.warning("No coverage data available to write for WGTS.")
            f.write("0")  
    with open("insertsize.txt", "w") as f:
        f.write("")
        logging.info("Created empty insertsize.txt for WGTS assay.")

elif assay == "PWGS":
    cache = _load_cache(
        etl_caches, "bamqc4merged", "bamqc4merged",
        gsiqcetl.column.BamQc4MergedColumn.MergedPineryLimsID,
        merged=True
    )
    # Coverage
    coverage = _get_metric(cache, lims_ids, "coverage deduplicated")
    with open("coverage.txt", "w") as f:
        if not coverage.empty:
            coverage = coverage.astype(int).astype(str)
            f.write("\n".join(coverage))
        else:
            logging.warning("No coverage data available to write for PWGS.")
            f.write("0")  

    # Insert size
    insert_size = _get_metric(cache, lims_ids, "insert size median")
    with open("insertsize.txt", "w") as f:
        if not insert_size.empty:
            insert_size = insert_size.astype(int).astype(str)
            f.write("\n".join(insert_size))
        else:
            logging.warning("No insert size data available to write for PWGS.")
            f.write("0")  

elif assay == "TAR":
    cache = _load_cache(
        etl_caches, "hsmetrics", "metrics",
        gsiqcetl.column.HsMetricsColumn.MergedPineryLimsID,
        merged=True
    )
    coverage = _get_metric(cache, lims_ids, "MEAN_BAIT_COVERAGE")
    with open("coverage.txt", "w") as f:
        if not coverage.empty:
            coverage = coverage.astype(int).astype(str)
            f.write("\n".join(coverage))
        else:
            logging.warning("No coverage data available to write for TAR.")
            f.write("0")  
    with open("insertsize.txt", "w") as f:
        f.write("")
        logging.info("Created empty insertsize.txt for TAR assay.")

else:
    raise ValueError(f"Unsupported assay: {assay}")