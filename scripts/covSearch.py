from gsiqcetl import QCETLMultiCache
import gsiqcetl.column
import argparse
import logging
import pandas as pd

# Create a parser instance
parser = argparse.ArgumentParser()

# Add arguments to the parser
parser.add_argument("--gsiqcetl-dir",
                    action="append",
                    help="GSI-QC-ETL directory to retrieve QC data from. If multiple are "
                         "specified, they are used in the order specified to fill in any missing "
                         "data")

parser.add_argument("--lims-id",
                    nargs="+", 
                    help="List of LIMS IDs to search for.")

# Parse the arguments
args = parser.parse_args()

# Access parsed arguments
gsiqcetl_dirs = args.gsiqcetl_dir
lims_ids = args.lims_id

# Load QC caches
etl_caches = QCETLMultiCache(gsiqcetl_dirs)
bamqc4merged_columns = gsiqcetl.column.BamQc4MergedColumn

# load the cache, or return empty cache if the cache is missing or seems invalid
# (based on missing ID column)
# merged means the cache is merged and has a Merged Pinery Lims ID column. The merged rows will be
# exploded so that individual Pinery Lims IDs can be used for lookup
def _load_cache(etl_caches, cache_version: str, cache_name: str, id_column, merged: bool = False):
    try:
        version = etl_caches.load_same_version(cache_version).remove_missing(cache_name)
        cache = version.unique(cache_name)
        if id_column not in cache:
            logging.warning(f"'{id_column}' column not found in cache: {cache_name}.{cache_version}")
            return pd.DataFrame()
        else:
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
            logging.exception(f'Error loading cache: {cache_version}.{cache_name}')
            return pd.DataFrame()

def _get_coverage(cache: pd.DataFrame, lims_ids: list[str]):
    '''
    Filters the cache to return rows matching the given LIMS IDs and returns the
    relevant coverage deduplicated values.
    Parameters:
    ----------
    cache (pd.DataFrame): The cache DataFrame with 'Merged Pinery Lims ID' as index.
    lims_ids (list[str]): List of LIMS IDs to filter by.
    coverage_column (str): The name of the column to return.

    Returns:
    --------
    pd.DataFrame: Filtered DataFrame containing matching LIMS IDs and coverage.
    '''
    if not lims_ids:
        logging.warning("No LIMS IDs provided for filtering.")
        return pd.DataFrame()

    lims_ids = [str(i) for i in lims_ids]
    filtered = cache.loc[cache.index.intersection(lims_ids)]

    if filtered.empty:
        logging.warning("No matching LIMS IDs found in the cache.")
        return pd.DataFrame()
    
    tumor = filtered[filtered['Tissue Type'] != 'R']
    if tumor.empty:
        logging.warning("No tumor samples found in the filtered cache.")
        return pd.DataFrame()
    else:
        coverage = tumor['coverage deduplicated'].drop_duplicates()
        coverage = coverage.round(2)

    return coverage

bamqc4merged = _load_cache(etl_caches, 'bamqc4merged', 'bamqc4merged',
            bamqc4merged_columns.MergedPineryLimsID, True)

coverage = _get_coverage(bamqc4merged, lims_ids)
if not coverage.empty:
    with open("coverage.txt", "w") as f:
        f.write("\n".join(coverage.astype(str)))
else:
    print("No coverage data available to write.")
