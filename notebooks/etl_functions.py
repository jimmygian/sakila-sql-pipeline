import pandas as pd
from sqlalchemy import create_engine, text
import time
from tqdm.notebook import tqdm

# Source: Transactional Database
src_engine = create_engine("mysql+pymysql://app:app_password@db:3306/sakila")

# Target: Data Warehouse
tgt_engine = create_engine("mysql+pymysql://app:app_password@db:3306/sakila_star")


def get_watermark(pipeline_name, conn):
    """Retrieve the last successful timestamp from sakila_star.etl_state"""
    
    query = text("SELECT last_success_ts FROM etl_state WHERE pipeline_name = :p_name")
    
    result = conn.execute(
        query, 
        {"p_name": pipeline_name}
    ).fetchone()

    
    # If never run, default to an old timestamp (start of epoch)
    return result[0] if result else '1970-01-01 00:00:00'

# Test
with tgt_engine.connect() as conn:
    watermark_value = get_watermark("fact_rental", conn)
    print(watermark_value)



def update_watermark(pipeline_names, new_ts, conn):
    """
    Update the watermark for a list of pipelines.
    
    Args:
        pipeline_names (list): A list of pipeline names (e.g. ['dim_customer'])
        new_ts (datetime/str): The timestamp to set (e.g. '2025-01-01 12:00:00')
        conn: The active database connection
    """
    
    query = text("""
        INSERT INTO etl_state (pipeline_name, last_success_ts) 
        VALUES (:p_name, :ts) 
        ON DUPLICATE KEY UPDATE last_success_ts = VALUES(last_success_ts)
    """)
    

    for name in pipeline_names:
        old_watermark = get_watermark(name, conn)
        
        conn.execute(query, {"p_name": name, "ts": new_ts})
        print(f"[{name}] Updated watermark from '{old_watermark}' to '{new_ts}' in 'etl_state' table")
    

def test_select_query(query, engine, watermark_value='1970-01-01 00:00:00'):    
    return (
        pd.read_sql(
            query, 
            engine, 
            params={"watermark": watermark_value}
        )
    )

def _initialise_etl_state(etl_state_list=None, ts='1970-01-01 00:00:00'):
    print("\n\n >> INITIALISING ETL STATE ...\n")

    if not etl_state_list:
        etl_state_list = ["fact_rental", "dim_film", "dim_customer", "dim_staff", "dim_actor", "bridge_actor", "dim_store"]
    
    with tgt_engine.connect() as conn:
        update_watermark(etl_state_list, ts, conn)
        conn.commit() 

def _clear_table_data(table_names, engine, force=False):
    """
    Deletes all rows from a specified tables.
    
    Args:
        table_name (list): The tables to clear (e.g. ['dim_store'])
        engine: The SQLAlchemy engine to use
        force (bool): If True, disables Foreign Key checks to force deletion.
    """
    print(f"\n\n >> CLEARING DATA FROM TABLES {table_names} ...\n")
    for table_name in table_names:
        with engine.connect() as conn:
            try:
                if force:
                    conn.execute(text("SET FOREIGN_KEY_CHECKS = 0"))
                
                # Delete all rows
                result = conn.execute(text(f"DELETE FROM {table_name}"))
                
                if force:
                    conn.execute(text("SET FOREIGN_KEY_CHECKS = 1"))
                
                conn.commit()
                print(f"Success: Deleted {result.rowcount} rows from {table_name}.")
                
            except Exception as e:
                print(f"Error clearing {table_name}: {e}")




def run_incremental_load(pipeline_name, extract_sql, load_sql, src_engine, tgt_engine):
    """
    Generic function to run ETL for a single table.
    """
    
    # 1. Get Watermark (Target)
    with tgt_engine.connect() as tgt_conn:
        watermark = get_watermark(pipeline_name, tgt_conn)
        
    print(f"[{pipeline_name}] Checking for updates since {watermark}...")

    # 2. Extract Data (Source)
    # We use the watermark to only fetch new data
    try:
        df = pd.read_sql(extract_sql, src_engine, params={"watermark": watermark})
    except Exception as e:
        print(f"[{pipeline_name}] Extraction Error: {e}")
        return

    if df.empty:
        print(f"[{pipeline_name}] No new records found.")
        return

    print(f"[{pipeline_name}] Found {len(df)} rows. Loading...")

    # 3. Load Data (Target)
    # Iterate and execute the specific Upsert SQL for this table
    with tgt_engine.begin() as tgt_conn: # .begin() auto-commits on success
        for index, row in df.iterrows():
        
            # Convert row to dict for parameter binding
            tgt_conn.execute(load_sql, row.to_dict())
        
        # 4. Update Watermark (Target)
        # Calculate new max timestamp from the dataframe
        new_ts = df['src_last_update'].max()
        update_watermark([pipeline_name], new_ts, tgt_conn)
        
    print(f"[{pipeline_name}] Success! Watermark updated to {new_ts}")

def upsert_data(upsert_list, src_engine, tgt_engine):
    # print(upsert_list)

    print("\n\n >> UPDATING / INSERTING DATA ...\n")

    for job in upsert_list:
        run_incremental_load(
            job["table_name"], 
            job["extract_sql"], 
            job["load_sql"], 
            src_engine, 
            tgt_engine
        )
