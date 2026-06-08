-- ============================================================
-- setup.sql
-- Airport-Performance-Analyzer Datenbank (vollständiges Schema)
-- ============================================================

BEGIN;

-- ============================================================
-- 0. Drop Tables
-- Reihenfolge: erst Faktentabellen, dann Dimensionstabellen
-- (FK-Abhängigkeiten beachten)
-- ============================================================

-- ── Faktentabellen ──────────────────────────────────────────
DROP TABLE IF EXISTS fact_weather;
DROP TABLE IF EXISTS fact_enroute_delay;
DROP TABLE IF EXISTS fact_airport_traffic;
DROP TABLE IF EXISTS fact_airport_delay;
DROP TABLE IF EXISTS fact_measurement;
DROP TABLE IF EXISTS fact_flight_event;
DROP TABLE IF EXISTS fact_flight;

-- ── Dimensionstabellen ──────────────────────────────────────
DROP TABLE IF EXISTS dim_entity_region;
DROP TABLE IF EXISTS dim_airline;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS dim_runway;
DROP TABLE IF EXISTS dim_airport;
DROP TABLE IF EXISTS dim_public_holidays;
DROP TABLE IF EXISTS dim_school_holidays;


-- ============================================================
-- 1. DIMENSIONSTABELLEN
--    Reihenfolge: dim_airport zuerst, da andere
--    Tabellen per FK darauf referenzieren.
-- ============================================================

-- ── dim_airport ─────────────────────────────────────────────
-- Quelle: opdi/airports.csv
-- Link: https://davidmegginson.github.io/ourairports-data/airports.csv

CREATE TABLE dim_airport (
    id                  INTEGER             NOT NULL,
    ident               CHAR(4)             PRIMARY KEY,
    type                VARCHAR(20)         NOT NULL,
    name                VARCHAR(20)         NOT NULL,
    latitude_deg        DECIMAL             NOT NULL,
    longitude_deg       DECIMAL             NOT NULL,
    continent           CHAR(2)             NOT NULL,
    iso_country         CHAR(2)             NOT NULL,
    iso_region          VARCHAR(20)         NOT NULL,
    municipality        VARCHAR(20),
    scheduled_service   BOOLEAN             NOT NULL,
    icao_code           CHAR(4),
    iata_code           CHAR(3),
    gps_code            CHAR(4),
    local_code          VARCHAR(7)
);

-- ── dim_runway ──────────────────────────────────────────────
-- Quelle: opdi/runways.csv
-- Link: https://davidmegginson.github.io/ourairports-data/runways.csv

CREATE TABLE dim_runway (
    id                  INTEGER         PRIMARY KEY,
    airport_ref         INTEGER         NOT NULL,
    airport_ident       VARCHAR(10)     NOT NULL,
    length_ft           DECIMAL,
    width_ft            DECIMAL,
    surface             VARCHAR(10),
    lighted             BOOLEAN         NOT NULL,
    closed              BOOLEAN         NOT NULL
);


-- ── dim_date ────────────────────────────────────────────────
-- Wird automatisch per GENERATE_SERIES befüllt (siehe Abschnitt 3)

CREATE TABLE dim_date (
    date_id             DATE              PRIMARY KEY,
    year                SMALLINT          NOT NULL,
    quarter             SMALLINT          NOT NULL,     -- 1–4
    month               SMALLINT          NOT NULL,     -- 1–12
    week                SMALLINT,                       -- ISO-Wochennummer
    day_of_week         SMALLINT,                       -- 1=Mo, 7=So
    is_weekend          BOOLEAN,                        -- True, False
    season              VARCHAR(10)                     -- 'summer','winter','shoulder'
);


-- ── dim_airline ─────────────────────────────────────────────
-- Quelle: openflights/airlines.dat
-- Link: https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat

CREATE TABLE dim_airline (
    icao                CHAR(3)             PRIMARY KEY,
    name                varchar(50),
    country             varchar(20)         
);


-- ── dim_entity_region ───────────────────────────────────────
-- Mapping ANSP/AUA-Entität → ISO-Land, zum Join der En-Route-
-- Verspätung (by entity) gegen flughafenseitige Daten (by country).

CREATE TABLE dim_entity_region (
    entity_name         VARCHAR(50)         PRIMARY KEY,    -- exakt wie entity_name in fact_enroute_delay
    iso_country         CHAR(2),                            -- ISO 3166-1 alpha-2
    country_name        VARCHAR(60),
    entity_kind         VARCHAR(20)         NOT NULL,       -- 'ANSP', 'AGGREGATE', 'CROSS_BORDER'
    notes               TEXT
);


-- ── dim_public_holidays ─────────────────────────────────────
-- Quelle: https://date.nager.at/
-- Granularität: Land × Datum × Feiertagsname

CREATE TABLE dim_public_holidays (
    country_code        CHAR(2)             NOT NULL        REFERENCES dim_airport(iso_country), -- ISO 3166-1 alpha-2, Join mit dim_airport
    country_name        VARCHAR(60)         NOT NULL,
    year                SMALLINT            NOT NULL,
    date                DATE                NOT NULL        REFERENCES dim_date(date_id),
    name                VARCHAR(100)        NOT NULL,
    local_name          VARCHAR(100),
    is_global           BOOLEAN,
    subdivision_code    VARCHAR(10),                        -- Bundesland
    types               VARCHAR(30),
    fixed               BOOLEAN,
    launch_year         SMALLINT,

    PRIMARY KEY (country_code, date, name)
);


-- ── dim_school_holidays ─────────────────────────────────────
-- Quelle: https://openholidaysapi.org/swagger/index.html
-- Granularität: Land × Zeitraum × Ferienname

CREATE TABLE dim_school_holidays (
    country_code        CHAR(2)             NOT NULL        REFERENCES dim_airport(iso_country), -- ISO 3166-1 alpha-2, Join mit dim_airport
    country_name        VARCHAR(60)         NOT NULL,
    name                VARCHAR(100)        NOT NULL,
    start_date          DATE                NOT NULL        REFERENCES dim_date(date_id),
    end_date            DATE                NOT NULL        REFERENCES dim_date(date_id),
    type                VARCHAR(30),
    nationwide          BOOLEAN,
    subdivision_code    VARCHAR(10),                        -- Bundesland
    subdivision_name    VARCHAR(60),                        -- Bundesland

    PRIMARY KEY (country_code, start_date, name)
);


-- ============================================================
-- 2. FAKTENTABELLEN
--    Reihenfolge: OPDI-Tabellen zuerst, dann Eurocontrol,
--    dann Wetter. fact_flight_event und fact_measurement
--    müssen nach fact_flight angelegt werden (FK).
-- ============================================================

-- ── fact_flight ─────────────────────────────────────────────
-- Quelle: opdi/flight_list/flight_list_YYYYMM.parquet
-- Link: https://www.opdi.aero/flight-list-data.html

CREATE TABLE fact_flight (
    id                  INT          PRIMARY KEY,
    icao24              CHAR(6)         NOT NULL,
    flt_id              VARCHAR(10),
    dof                 DATE            NOT NULL    REFERENCES dim_date(date_id),
    adep                CHAR(4)                     REFERENCES dim_airport(ident),
    ades                CHAR(4)                     REFERENCES dim_airport(ident),
    model               VARCHAR(50),
    typecode            CHAR(4),
    icao_operator       CHAR(3)                     REFERENCES dim_airline(icao),
    first_seen_date     DATE,
    first_seen_time     TIME,
    last_seen_date      DATE,
    last_seen_time      TIME
);


-- ── fact_flight_event ───────────────────────────────────────
-- Quelle: opdi/flight_events/flight_events_YYYYMMDD_YYYYMMDD.parquet
-- Link: https://www.opdi.aero/flight-event-data.html

CREATE TABLE fact_flight_event (
    id                  INT             PRIMARY KEY,
    flight_id           INT             NOT NULL    REFERENCES fact_flight(id),
    type                VARCHAR(20)     NOT NULL,
    event_date          DATE            NOT NULL    REFERENCES dim_date(date_id),
    event_time          TIME            NOT NULL,
    longitude           DECIMAL         NOT NULL,
    latitude            DECIMAL         NOT NULL,
    altitude            DECIMAL
);


-- ── fact_measurement ────────────────────────────────────────
-- Quelle: opdi/measurements/measurements_YYYYMMDD_YYYYMMDD.parquet
-- Link: https://www.opdi.aero/measurement-data.html

CREATE TABLE fact_measurement (
    id                  VARCHAR(30)     PRIMARY KEY,
    event_id            VARCHAR(30)     NOT NULL    REFERENCES fact_flight_event(id),
    type                VARCHAR(50),
    value               DECIMAL
);


-- ── fact_airport_delay  ──────────────────────────────────────
-- Quelle: eurocontrol/apt_dly/apt_dly_YYYY.csv
-- Link: https://ansperformance.eu/csv/#aptdly-csv
-- Granularität: Flughafen × Tag

CREATE TABLE fact_airport_delay (
    year                INTEGER             NOT NULL,
    month_num           INTEGER             NOT NULL,
    month_mon           VARCHAR(30),
    flt_date            DATE                REFERENCES dim_date(date_id),
    apt_icao            CHAR(4)             REFERENCES dim_airport(ident),
    apt_name            VARCHAR(150),
    state_name          VARCHAR(100),
    flt_arr_1           INTEGER,            -- Anzahl Ankünfte

    -- Gesamtverspätung und Ursachen (in Minuten) – nach ATFM Delay Codes:
    -- https://ansperformance.eu/definition/atfm-delay-codes/

    dly_apt_arr_1       NUMERIC(10,2),      -- Gesamt-Arrival-Delay
    dly_apt_arr_a_1     NUMERIC(10,2),      -- A  Accident/Incident
    dly_apt_arr_c_1     NUMERIC(10,2),      -- C  ATC Capacity
    dly_apt_arr_d_1     NUMERIC(10,2),      -- D  De-icing
    dly_apt_arr_e_1     NUMERIC(10,2),      -- E  Aerodrome Services
    dly_apt_arr_g_1     NUMERIC(10,2),      -- G  Aerodrome Capacity
    dly_apt_arr_i_1     NUMERIC(10,2),      -- I  Industrial Action (ATC)
    dly_apt_arr_m_1     NUMERIC(10,2),      -- M  Military Activity
    dly_apt_arr_n_1     NUMERIC(10,2),      -- N  Industrial Action (non-ATC)
    dly_apt_arr_o_1     NUMERIC(10,2),      -- O  Other
    dly_apt_arr_p_1     NUMERIC(10,2),      -- P  Special Event
    dly_apt_arr_r_1     NUMERIC(10,2),      -- R  ATC Routeing
    dly_apt_arr_s_1     NUMERIC(10,2),      -- S  ATC Staffing
    dly_apt_arr_t_1     NUMERIC(10,2),      -- T  Equipment (ATC)
    dly_apt_arr_v_1     NUMERIC(10,2),      -- V  Environmental Issues
    dly_apt_arr_w_1     NUMERIC(10,2),      -- W  Weather
    dly_apt_arr_na_1    NUMERIC(10,2),      -- NA Not regulated/Not specified
    flt_arr_dly         INTEGER,            -- Anzahl verspäteter Ankünfte
    flt_arr_dly_15      INTEGER,            -- Ankünfte mit >15 Min. Verspätung

    PRIMARY KEY (apt_icao, flt_date)
);


-- ── fact_airport_traffic ─────────────────────────────────────
-- Quelle: eurocontrol/airport_traffic/airport_traffic_YYYY.csv
-- Link: https://ansperformance.eu/csv/#aptflt-csv
-- Granularität: Flughafen × Tag

CREATE TABLE fact_airport_traffic (
    year                INTEGER             NOT NULL,
    month_num           INTEGER             NOT NULL,
    month_mon           VARCHAR(30),
    flt_date            DATE                REFERENCES dim_date(date_id),
    apt_icao            CHAR(4)             REFERENCES dim_airport(ident),
    apt_name            VARCHAR(150),
    state_name          VARCHAR(100),

    flt_dep_1           INTEGER,            -- Abflüge
    flt_arr_1           INTEGER,            -- Ankünfte
    flt_tot_1           INTEGER,            -- Gesamt
    
    PRIMARY KEY (apt_icao, flt_date)
);


-- ── fact_enroute_delay ────────────────────────────────────────
-- Quelle: eurocontrol/enroute_ansp/ert_dly_ansp_YYYY.csv
-- Link: https://ansperformance.eu/csv/#ertdly-csv
-- Granularität: Luftraum-Entität (ANSP/AUA) × Tag

CREATE TABLE fact_enroute_delay (
    year                INTEGER             NOT NULL,
    month_num           INTEGER             NOT NULL,
    month_mon           VARCHAR(30),
    flt_date            DATE                REFERENCES dim_date(date_id),   
    entity_name         VARCHAR(50)         REFERENCES dim_entity_region(entity_name), -- ENTITY_NAME (z.B. 'DFS', 'MUAC')
    entity_type         VARCHAR(20)         NOT NULL,   -- ENTITY_TYPE: 'ANSP (AUA)' od. 'AREA (AUA)'
    flt_ert_1           INTEGER,                        -- Anzahl En-Route-Flüge in dem jeweiligen Luftraum
    dly_ert_1           NUMERIC(10,2),                  -- Gesamt En-Route-Verspätung (Min.)
    
    -- Gesamtverspätung und Ursachen (in Minuten) – nach ATFM Delay Codes:
    -- https://ansperformance.eu/definition/atfm-delay-codes/

    dly_ert_a_1         NUMERIC(10,2),      -- A  Accident/Incident
    dly_ert_c_1         NUMERIC(10,2),      -- C  ATC Capacity
    dly_ert_d_1         NUMERIC(10,2),      -- D  De-icing
    dly_ert_e_1         NUMERIC(10,2),      -- E  Aerodrome Services
    dly_ert_g_1         NUMERIC(10,2),      -- G  Aerodrome Capacity
    dly_ert_i_1         NUMERIC(10,2),      -- I  Industrial Action (ATC)
    dly_ert_m_1         NUMERIC(10,2),      -- M  Military Activity
    dly_ert_n_1         NUMERIC(10,2),      -- N  Industrial Action (non-ATC)
    dly_ert_o_1         NUMERIC(10,2),      -- O  Other
    dly_ert_p_1         NUMERIC(10,2),      -- P  Special Event
    dly_ert_r_1         NUMERIC(10,2),      -- R  ATC Routeing
    dly_ert_s_1         NUMERIC(10,2),      -- S  ATC Staffing
    dly_ert_t_1         NUMERIC(10,2),      -- T  Equipment (ATC)
    dly_ert_v_1         NUMERIC(10,2),      -- V  Environmental Issues
    dly_ert_w_1         NUMERIC(10,2),      -- W  Weather
    dly_ert_na_1        NUMERIC(10,2),      -- NA Not regulated/Not specified
    flt_ert_1_dly       INTEGER,            -- Flüge mit Verspätung
    flt_ert_1_dly_15    INTEGER,            -- Flüge mit >15 Min. Verspätung

    PRIMARY KEY (flt_date, entity_name, entity_type)
);


-- ── fact_weather (Open-Meteo API) ────────────────────────────
-- Quelle: Open-Meteo Historical Weather API
-- Link: https://archive-api.open-meteo.com/v1/archive
-- Granularität: Flughafen × Stunde

CREATE TABLE fact_weather (
    apt_icao            CHAR(4)         REFERENCES dim_airport(ident),
    ts_hour             TIMESTAMPTZ     NOT NULL,   -- UTC, auf volle Stunde gerundet
    wind_speed          NUMERIC(10,2),              -- km/h
    precipitation       NUMERIC(10,2),              -- mm
    temperature         NUMERIC(10,2),              -- °C
    snow_depth          NUMERIC(10,2),              -- meters
    cloud_cover         NUMERIC(10,2),              -- %

    PRIMARY KEY (apt_icao, ts_hour)
);


-- ============================================================
-- 3. DIM_DATE BEFÜLLEN (2011 – 2026)
--    Einmalig automatisch generiert – kein externer Datensatz nötig.
-- ============================================================

INSERT INTO dim_date (date_id, year, quarter, month, week, day_of_week, is_weekend, season)
SELECT
    d::DATE,
    EXTRACT(year FROM d)::SMALLINT,
    EXTRACT(quarter FROM d)::SMALLINT,
    EXTRACT(month FROM d)::SMALLINT,
    EXTRACT(week FROM d)::SMALLINT,
    EXTRACT(isodow FROM d)::SMALLINT,              -- 1=Mo, 7=So
    EXTRACT(isodow FROM d) >= 6,                   -- Sa + So = Wochenende
    CASE
        WHEN EXTRACT(month FROM d) IN (6, 7, 8)    THEN 'summer'
        WHEN EXTRACT(month FROM d) IN (12, 1, 2)   THEN 'winter'
        ELSE 'shoulder'
    END
FROM GENERATE_SERIES(
    '2011-01-01'::DATE,
    '2026-12-31'::DATE,
    '1 day'::INTERVAL
) AS d;


COMMIT;