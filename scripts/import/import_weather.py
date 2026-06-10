import pandas as pd
import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
from io import StringIO

# Set the working directory to the folder containing import_weather.py
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# Load .env file
load_dotenv()
DB_URL = os.getenv('DATABASE_URL')
engine = create_engine(DB_URL)

# Empty fact table
with engine.connect() as conn:
    conn.execute(text("TRUNCATE TABLE fact_weather RESTART IDENTITY CASCADE;"))
    conn.commit()

# Years to import
YEARS_LIST = list(range(2016, 2027))



# -------------- Import fact_weather -------------------------------------

# -- Extract raw data --

weather_url = "../../data/raw/weather/"
path = f"{weather_url}fact_weather.parquet"
df_weather = pd.read_parquet(path, engine="pyarrow")


# -- Transform --

df_weather["ts_hour"] = df_weather["ts_hour"].dt.tz_localize(None)

df_weather = df_weather.drop_duplicates(subset=["apt_icao", "ts_hour"], keep="first")

df_weather.columns = [col.lower() for col in df_weather.columns]


# -- Load --

def copy_to_sql(df, table, engine):
    
    # create in-memory-buffer
    buffer = StringIO()
    df.to_csv(buffer, index=False, header=False)
    
    # Reset buffer cursor to the beginning
    buffer.seek(0)
    
    # Extract raw psycopg2 connection from SQLAlchemy engine
    with engine.connect() as conn:
        dbapi_conn = conn.connection
        
        with dbapi_conn.cursor() as cursor:
            # Bulk load via PostgreSQL COPY
            # sep="," matches CSV format, null="" maps empty fields to NULL
            cursor.copy_from(buffer, table, sep=",", null="")
        
        dbapi_conn.commit()

copy_to_sql(df_weather, "fact_weather", engine)

print("-- fact_weather finished --")