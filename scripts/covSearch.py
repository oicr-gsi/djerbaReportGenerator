import sqlite3
import argparse

def query_coverage(database, lims_ids):

    # Create a formatted string for the IN clause of the SQL query
    formatted_ids = ', '.join(f'"{lims_id}"' for lims_id in lims_ids)

    # SQL query with IN clause
    query = f'''
        SELECT "coverage deduplicated"
        FROM bamqc4merged_bamqc4merged_5
        WHERE json("Merged Pinery Lims ID") = json_array({formatted_ids})
    '''
    # Connect to the SQLite database
    try:
        conn = sqlite3.connect(database)
        cur = conn.cursor()
        
        # Execute the query
        cur.execute(query)
        result = cur.fetchall()
        
        if result:
            # Extract the coverage value from the first row
            coverage_value = result[0][0]
            print(f"Coverage Value: {coverage_value}")
            return coverage_value
        else:
            print("No result found.")
            return None
        
    except sqlite3.Error as e:
        print(f"SQLite error: {e}")
        return None

        conn.close()
        cur.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Query SQLite database for coverage deduplicated values based on LIMS IDs.")
    parser.add_argument("lims_ids", nargs="+", help="List of LIMS IDs to search for.")
    
    database = "/scratch2/groups/gsi/production/qcetl_v1/bamqc4merged/latest"
    args = parser.parse_args()

    coverage_value = query_coverage(database, args.lims_ids)

    with open("coverage.txt", "w") as result_file:
        if coverage_value is not None:
            result_file.write(str(coverage_value))
        else:
            result_file.write("No result found or query failed.")

