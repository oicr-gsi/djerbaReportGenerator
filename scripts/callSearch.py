import sqlite3
import argparse

def query_callability(database, lims_ids):

    # Create a formatted string for the IN clause of the SQL query
    formatted_ids = ', '.join(f'"{lims_id}"' for lims_id in lims_ids)
    
    # SQL query with IN clause
    query = f'''
        SELECT "callability"
        FROM mutectcallability_mutectcallability_1
        WHERE json("Merged Pinery Lims ID") = json_array({formatted_ids})
    '''
    # Connect to the SQLite database
    try:
        conn = sqlite3.connect(database)
        cur = conn.cursor()
        
        # Execute the query
        cur.execute(query)
        result = cur.fetchall()
        
        # Check if the query returned any results
        if result:
            # Extract the callability value from the first row
            callability_value = result[0][0]
            print(f"Callability Value: {callability_value}")
            return callability_value
        else:
            print("No result found.")
            return None
        
    except sqlite3.Error as e:
        print(f"SQLite error: {e}")
        return None

        conn.close()
        cur.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Query SQLite database for callability values based on LIMS IDs.")
    parser.add_argument("lims_ids", nargs="+", help="List of LIMS IDs to search for.")

    database = "/scratch2/groups/gsi/production/qcetl_v1/mutectcallability/latest"
    args = parser.parse_args()

    callability_value = query_callability(database, args.lims_ids)

    with open("callability.txt", "w") as result_file:
        if callability_value is not None:
            result_file.write(str(callability_value))
        else:
            result_file.write("No result found or query failed.")
