import pandas as pd
import os

# Set the working directory to the folder containing this script
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# Years to import
YEARS_LIST = list(range(2022, 2027))
MONTHS_LIST = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]

# Columns that may arrive as a native timestamp OR as an ISO string,
# depending on the OPDI export version -> parse them to datetime after concat.
TIME_COLS = ["dof", "first_seen", "last_seen"]
# Integer columns. Their storage type changed across exports (uint64 vs int64),
# and unix_time is missing in newer files. Cast each month to nullable Int64
# BEFORE concat so a uint64/int64 mix can't force a lossy float64 upcast.
INT_COLS = ["id", "unix_time"]


# -------------- Import fact_flight -------------------------------------

# -- Extract raw data --

input_dir = "../../data/raw/opdi/flight_list/"
output_dir = "../../data/processed/opdi/flight_list/"

# Create the output folder if it does not exist yet
os.makedirs(output_dir, exist_ok=True)

for y in YEARS_LIST:
    df_months = []
    for m in MONTHS_LIST:
        path = f"{input_dir}flight_list_{y}{m}.parquet"
        if not os.path.exists(path):
            print(f"WARNING: File not found - {path} skipped")
            continue

        df = pd.read_parquet(path, engine="pyarrow")

        # Cast integer columns per month before concat. The intermediate int64
        # cast handles uint64 sources (uint64 -> Int64 fails the 'safe' rule),
        # then Int64 keeps full precision and allows missing values after concat.
        for col in INT_COLS:
            if col in df.columns:
                df[col] = df[col].astype("int64").astype("Int64")

        df_months.append(df)

    if not df_months:
        print(f"INFO: No data for {y}")
        continue

    df_year = pd.concat(df_months, ignore_index=True)

    # Normalize time columns (timestamp OR string depending on the month)
    for col in TIME_COLS:
        if col in df_year.columns:
            df_year[col] = pd.to_datetime(df_year[col], errors="coerce")
    
    # dof: drop the time part, keep date only
    if "dof" in df_year.columns:
        df_year["dof"] = df_year["dof"].dt.normalize()

    
    # first_seen / last_seen: keep BOTH date and time, in separate columns
    #   *_date -> midnight-normalized datetime64 -> PostgreSQL DATE
    #   *_time -> "HH:MM:SS" string              -> PostgreSQL TIME WITHOUT TIME ZONE
    for col in ["first_seen", "last_seen"]:
        if col in df_year.columns:
            df_year[f"{col}_date"] = df_year[col].dt.normalize()
            df_year[f"{col}_time"] = df_year[col].dt.strftime("%H:%M:%S")
            df_year = df_year.drop(columns=[col])


    output_path = f"{output_dir}flight_list_{y}.parquet"
    df_year.to_parquet(output_path, engine="pyarrow", compression="snappy", index=False)
    print(f"Exported {output_path} ({len(df_year):,} rows)")



# drop columns in previously generated dfs for each year
# final concat into one df to be imported into database

df_years = []

for y in YEARS_LIST:
    
    path = f"{output_dir}flight_list_{y}.parquet"

    df_temp = pd.read_parquet(path, engine="pyarrow")
    
    df_temp = df_temp.drop(columns=["unix_time", "adep_p", "ades_p", "registration", "icao_aircraft_class"], errors="ignore")

    # if column does not exist, drop will be ignored and continued
    # first_seen / last_seen were already split + dropped in the loop above.
    df_temp = df_temp.drop(
        columns=["unix_time", "adep_p", "ades_p", "registration", "icao_aircraft_class", "version"],
        errors="ignore"
    )

    # same id dtype
    df_temp = df_temp.assign(id=df_temp["id"].astype("Int64"))

    df_years.append(df_temp)

df_total = pd.concat(df_years, ignore_index=True)

output_path_total = f"{output_dir}flight_list_total.parquet"
df_total.to_parquet(output_path_total, engine="pyarrow", compression="snappy", index=False)
print(f"Exported {output_path_total} ({len(df_total):,} rows)")