import pandas as pd
import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# Set the working directory to the folder containing import_eurocontrol.py
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# Load .env file
load_dotenv()
DB_URL = os.getenv('DATABASE_URL')
engine = create_engine(DB_URL)

# Years to import
YEARS_LIST = list(range(2016, 2027))

# -------------- Import fact_airport_delay -------------------------------------

# -- Extract raw data --

apt_dly_url = "../../data/raw/eurocontrol/apt_dly/"
df_apt_dly = pd.DataFrame()

for y in YEARS_LIST:
    path = f"{apt_dly_url}apt_dly_{y}.csv"
    if not os.path.exists(path):
        print(f"WARNING: File not found - {path} skipped")
        continue

    df_temp = pd.read_csv(path, encoding='latin-1')
    df_apt_dly = pd.concat([df_apt_dly, df_temp])

# -- Transform --

df_apt_dly["FLT_DATE"] = pd.to_datetime(df_apt_dly["FLT_DATE"], errors="coerce")
df_apt_dly["FLT_DATE"] = df_apt_dly["FLT_DATE"].dt.tz_localize(None)

df_apt_dly = df_apt_dly.drop(columns="ATFM_VERSION")

df_apt_dly.columns = [col.lower() for col in df_apt_dly.columns]

# -- Load --

# Clear the table before importing
with engine.connect() as conn:
    conn.execute(text("TRUNCATE TABLE fact_airport_delay RESTART IDENTITY CASCADE;"))
    conn.commit()

df_apt_dly.to_sql("fact_airport_delay", engine, if_exists='append', index=False)



# -------------- Import fact_airport_traffic -------------------------------------

# -- Extract raw data --


# -- Transform --


# -- Load --



# -------------- Import fact_enroute_delay -------------------------------------

# -- Extract raw data --


# -- Transform --


# -- Load --
